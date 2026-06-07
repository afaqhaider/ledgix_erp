import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/migration_models.dart';

class DataMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<List<dynamic>>> parseFile(PlatformFile file) async {
    if (file.bytes == null) return [];

    if (file.extension == 'xlsx' || file.extension == 'xls') {
      try {
        var excel = Excel.decodeBytes(file.bytes!);
        for (var table in excel.tables.keys) {
          return excel.tables[table]!.rows
              .map((row) => row.map((cell) => _extractCellValue(cell?.value)).toList())
              .toList();
        }
      } catch (e) {
        throw Exception(
          'Failed to decode Excel file. Please ensure it is a valid XLSX file. Legacy XLS files might not be supported.',
        );
      }
    } else if (file.extension == 'csv') {
      final csvString = String.fromCharCodes(file.bytes!);
      return const CsvDecoder().convert(csvString);
    }
    return [];
  }

  dynamic _extractCellValue(dynamic value) {
    if (value == null) return null;
    
    // The 'excel' package CellValue classes
    final typeName = value.runtimeType.toString();
    
    if (typeName.contains('TextCellValue') || 
        typeName.contains('IntCellValue') || 
        typeName.contains('DoubleCellValue') || 
        typeName.contains('BoolCellValue')) {
      return value.value;
    }
    
    return value;
  }

  dynamic sanitizeValue(dynamic value, {String type = 'string'}) {
    if (value == null) return null;
    
    String strVal = value.toString().trim();
    if (strVal.isEmpty) return null;

    switch (type) {
      case 'string':
        // Convert numeric codes like 1000.0 to "1000"
        if (double.tryParse(strVal) != null) {
          final d = double.parse(strVal);
          if (d == d.toInt()) return d.toInt().toString();
        }
        return strVal;
      
      case 'double':
        return double.tryParse(strVal.replaceAll(',', '')) ?? 0.0;
      
      case 'bool':
        final low = strVal.toLowerCase();
        return low == 'yes' || low == 'true' || low == '1' || low == 'y';
      
      case 'balanceType':
        final low = strVal.toLowerCase();
        if (low.startsWith('de') || low == 'dr') return 'debit';
        if (low.startsWith('cr')) return 'credit';
        return 'debit';
      
      default:
        return value;
    }
  }

  Map<String, int> autoMapFields(
    List<dynamic> headers,
    List<FieldDefinition> definitions,
  ) {
    Map<String, int> mapping = {};
    for (var def in definitions) {
      for (var i = 0; i < headers.length; i++) {
        String header = headers[i].toString().toLowerCase().trim();
        if (header == def.label.toLowerCase() ||
            header == def.key.toLowerCase() ||
            def.aliases.any((alias) => alias.toLowerCase() == header)) {
          mapping[def.key] = i;
          break;
        }
      }
    }
    return mapping;
  }

  List<ImportRow> processData(
    List<List<dynamic>> rawData,
    Map<String, int> mapping,
    List<FieldDefinition> definitions,
  ) {
    if (rawData.isEmpty) return [];

    // Skip header row
    final dataRows = rawData.skip(1).toList();
    List<ImportRow> processedRows = [];

    for (var i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      Map<String, dynamic> mappedData = {};
      Map<String, String?> errors = {};

      for (var def in definitions) {
        final index = mapping[def.key];
        dynamic value = (index != null && index < row.length)
            ? row[index]
            : null;

        mappedData[def.key] = value;

        if (def.isRequired && (value == null || value.toString().isEmpty)) {
          errors[def.key] = '${def.label} is required';
        }
      }

      processedRows.add(ImportRow(index: i, data: mappedData, errors: errors));
    }
    return processedRows;
  }

  Future<void> performBatchImport(
    MigrationModule module,
    List<ImportRow> rows,
    String companyId, {
    bool useImportedCodes = false,
    DuplicateStrategy strategy = DuplicateStrategy.createNew,
  }) async {
    final batch = _firestore.batch();
    final collection = _firestore
        .collection('companies')
        .doc(companyId)
        .collection(_getCollectionName(module));

    List<String> rowErrors = [];

    // For COA code generation and duplicate detection
    Map<String, int> sessionHighestCodes = {};
    Map<String, String> existingIdsByUniqueKey = {};

    // Fetch existing records for duplicate detection and high-code discovery
    // Load once per company/module to optimize and avoid row-by-row queries
    if (strategy != DuplicateStrategy.createNew ||
        module == MigrationModule.chartOfAccounts) {
      try {
        final existing = await collection.get();
        for (var doc in existing.docs) {
          final data = doc.data();
          String? key;
          if (module == MigrationModule.chartOfAccounts) {
            key = data['accountCode']?.toString() ??
                data['accountName']?.toString().toLowerCase();
            
            // Discover highest codes locally
            final type = data['accountType']?.toString();
            final codeStr = data['accountCode']?.toString();
            if (type != null && codeStr != null) {
              final code = int.tryParse(codeStr) ?? 0;
              if (code > (sessionHighestCodes[type] ?? 0)) {
                sessionHighestCodes[type] = code;
              }
            }
          } else if (module == MigrationModule.customers ||
              module == MigrationModule.suppliers) {
            key = data['name']?.toString().toLowerCase();
          } else if (module == MigrationModule.inventory) {
            key = data['sku']?.toString() ??
                data['name']?.toString().toLowerCase();
          }

          if (key != null) {
            existingIdsByUniqueKey[key] = doc.id;
          }
        }
      } catch (e) {
        // Intercept Firestore index errors before the loop
        if (e is FirebaseException && (e.code == 'failed-precondition' || e.message?.contains('index') == true)) {
          throw Exception('INDEX_REQUIRED: Required database index is missing. Please deploy Firestore indexes and try again.');
        }
        rethrow;
      }
    }

    for (var row in rows) {
      if (!row.isValid || !row.isSelected) continue;

      try {
        Map<String, dynamic> data = {};
        String? existingId;

        // Sanitize based on module
        if (module == MigrationModule.chartOfAccounts) {
          final importedCode = sanitizeValue(row.data['code']);
          final accountName = sanitizeValue(row.data['name']);
          final categoryStr = sanitizeValue(row.data['category']) ?? '';
          final typeStr = sanitizeValue(row.data['type']) ?? '';

          String finalCode;
          if (useImportedCodes &&
              importedCode != null &&
              importedCode.isNotEmpty) {
            finalCode = importedCode;
          } else {
            // Generate code locally using cached highest codes
            finalCode = _generateLocalCode(typeStr, categoryStr, sessionHighestCodes);
          }

          // Check for duplicate
          final lookupKey = useImportedCodes
              ? (importedCode ?? accountName?.toLowerCase())
              : accountName?.toLowerCase();
          if (lookupKey != null) {
            existingId = existingIdsByUniqueKey[lookupKey];
          }

          if (existingId != null && strategy == DuplicateStrategy.skip) continue;

          data = {
            'accountCode': finalCode,
            'externalCode': importedCode,
            'accountName': accountName,
            'accountType': _mapToAccountType(typeStr, categoryStr),
            'accountCategory': _mapToAccountCategory(categoryStr),
            'parentAccountId': sanitizeValue(row.data['parentCode']),
            'allowPosting':
                sanitizeValue(row.data['isPostable'], type: 'bool') ?? true,
            'openingBalance':
                sanitizeValue(row.data['openingBalance'], type: 'double') ??
                    0.0,
            'openingBalanceType':
                sanitizeValue(row.data['normalBalance'], type: 'balanceType') ??
                    'debit',
            'isGroup':
                !(sanitizeValue(row.data['isPostable'], type: 'bool') ?? true),
          };

          // Ensure currentBalance is initialized for new accounts
          if (existingId == null) {
            data['currentBalance'] = data['openingBalance'];
          }
        } else if (module == MigrationModule.suppliers ||
module == MigrationModule.customers) {
          final nameKey = module == MigrationModule.customers ? 'name' : 'supplierName';
          final name = sanitizeValue(row.data[nameKey]);
          
          if (name != null) {
            existingId = existingIdsByUniqueKey[name.toString().toLowerCase()];
          }
          
          if (existingId != null && strategy == DuplicateStrategy.skip) continue;

          data = {
            'name': name,
            'email': sanitizeValue(row.data['email']),
            'phone': sanitizeValue(row.data['phone']),
            'address': sanitizeValue(row.data['address']),
            'trnVatNumber': sanitizeValue(row.data['trnVatNumber'] ?? row.data['taxNumber']),
            'openingBalance': sanitizeValue(row.data['openingBalance'], type: 'double') ?? 0.0,
            'openingBalanceType': sanitizeValue(row.data['openingBalanceType'], type: 'balanceType') ?? (module == MigrationModule.customers ? 'debit' : 'credit'),
            'isActive': sanitizeValue(row.data['isActive'], type: 'bool') ?? true,
          };
          
          data['portalAccessEnabled'] = false;
          data['portalUserIds'] = [];
          data['invitedEmails'] = [];
        } else if (module == MigrationModule.inventory) {
          final name = sanitizeValue(row.data['name']);
          final sku = sanitizeValue(row.data['sku']);
          
          final lookupKey = sku ?? name?.toString().toLowerCase();
          if (lookupKey != null) {
            existingId = existingIdsByUniqueKey[lookupKey];
          }
          
          if (existingId != null && strategy == DuplicateStrategy.skip) continue;

          data = {
            'name': name,
            'sku': sku,
            'description': sanitizeValue(row.data['description']),
            'type': sanitizeValue(row.data['type']) ?? 'storable',
            'uom': sanitizeValue(row.data['uom']) ?? 'Units',
            'salePrice': sanitizeValue(row.data['salePrice'], type: 'double') ?? 0.0,
            'costPrice': sanitizeValue(row.data['costPrice'], type: 'double') ?? 0.0,
            'stockQuantity': 0.0,
            'stockBatches': [],
          };
        } else {
          // Fallback: strictly ensure no custom objects go to Firestore
          row.data.forEach((key, value) {
            data[key] = sanitizeValue(value);
          });
        }

        if (data.isEmpty) continue;

        // Final sanitation check for all fields to prevent "custom object found" error
        data.updateAll((key, value) {
          if (value == null) return null;
          // If value is still some complex object (like Excel cell), force to string
          if (value is! String && value is! num && value is! bool && value is! DateTime && value is! FieldValue && value is! List && value is! Map) {
            return value.toString();
          }
          return value;
        });

        // Add common fields
        final docRef = (existingId != null && strategy == DuplicateStrategy.update)
            ? collection.doc(existingId)
            : collection.doc();

        data['id'] = docRef.id;
        data['companyId'] = companyId;
        if (existingId == null || strategy != DuplicateStrategy.update) {
          data['createdAt'] = FieldValue.serverTimestamp();
        }
        data['updatedAt'] = FieldValue.serverTimestamp();

        batch.set(docRef, data, SetOptions(merge: true));
      } catch (e) {
        // Exit immediately on index errors to avoid labeling as row errors
        if (e is FirebaseException && (e.code == 'failed-precondition' || e.message?.contains('index') == true)) {
          throw Exception('INDEX_REQUIRED: Required database index is missing. Please deploy Firestore indexes and try again.');
        }
        rowErrors.add('Row ${row.index + 1}: ${e.toString()}');
      }
    }

    if (rowErrors.isNotEmpty) {
      throw Exception('Sanitization errors found:\n${rowErrors.join('\n')}');
    }

    try {
      await batch.commit();
    } catch (e) {
      if (e is FirebaseException && (e.code == 'failed-precondition' || e.message?.contains('index') == true)) {
        throw Exception('INDEX_REQUIRED: Required database index is missing. Please deploy Firestore indexes and try again.');
      }
      rethrow;
    }
  }

  String _generateLocalCode(String type, String category, Map<String, int> sessionHighestCodes) {
    final majorType = _mapToAccountType(type, category);
    int startRange;

    switch (majorType) {
      case 'asset':
        startRange = 1000;
        break;
      case 'liability':
        startRange = 2000;
        break;
      case 'equity':
        startRange = 3000;
        break;
      case 'income':
        startRange = 4000;
        break;
      case 'costOfSales':
        startRange = 5000;
        break;
      case 'expense':
        startRange = 6000;
        break;
      default:
        startRange = 7000;
    }

    int nextCode = (sessionHighestCodes[majorType] ?? (startRange - 1)) + 1;
    if (nextCode < startRange) nextCode = startRange;

    sessionHighestCodes[majorType] = nextCode;
    return nextCode.toString();
  }

  String _mapToAccountType(String type, String category) {
    final t = type.toLowerCase();
    final c = category.toLowerCase();
    
    if (t.contains('asset') || c.contains('asset') || c.contains('cash') || c.contains('bank') || c.contains('receivable')) return 'asset';
    if (t.contains('liability') || c.contains('liability') || c.contains('payable')) return 'liability';
    if (t.contains('equity')) return 'equity';
    if (t.contains('revenue') || t.contains('income') || c.contains('sales')) return 'income';
    if (t.contains('cost of sales') || c.contains('cost of goods sold') || c.contains('direct cost')) return 'costOfSales';
    if (t.contains('expense')) return 'expense';
    
    return 'asset'; // Fallback
  }

  String _mapToAccountCategory(String category) {
    final c = category.toLowerCase().trim();
    if (c == 'cash') return 'cash';
    if (c == 'bank') return 'bank';
    if (c.contains('receivable')) return 'accountsReceivable';
    if (c.contains('payable') && !c.contains('vat')) return 'accountsPayable';
    if (c.contains('vat')) return 'vatPayable';
    if (c == 'sales' || c == 'revenue') return 'sales';
    if (c.contains('operating')) return 'operatingExpense';
    if (c.contains('admin')) return 'adminExpense';
    
    // Try to find exact match in AccountCategory
    // Since we don't have easy access to enum names as strings here, 
    // we'll return the sanitized string and hope it matches or use a default
    return c.replaceAll(' ', '');
  }

  String _getCollectionName(MigrationModule module) {
    switch (module) {
      case MigrationModule.customers:
        return 'customers';
      case MigrationModule.suppliers:
        return 'suppliers';
      case MigrationModule.chartOfAccounts:
        return 'chartOfAccounts';
      case MigrationModule.inventory:
        return 'items';
      case MigrationModule.journalEntries:
        return 'journalEntries';
      case MigrationModule.salesInvoices:
        return 'invoices';
      default:
        throw Exception('Module ${module.label} not yet supported for import');
    }
  }
}
