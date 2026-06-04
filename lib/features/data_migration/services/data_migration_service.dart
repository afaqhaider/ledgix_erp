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
              .map((row) => row.map((cell) => cell?.value).toList())
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
    String companyId,
  ) async {
    final batch = _firestore.batch();
    final collection = _firestore
        .collection('companies')
        .doc(companyId)
        .collection(_getCollectionName(module));

    for (var row in rows) {
      if (!row.isValid) continue;

      final docRef = collection.doc();
      final data = Map<String, dynamic>.from(row.data);

      // Add common fields
      data['id'] = docRef.id;
      data['companyId'] = companyId;
      data['createdAt'] = FieldValue.serverTimestamp();

      // Module specific defaults/fixes
      if (module == MigrationModule.suppliers) {
        data['openingBalanceType'] = data['openingBalanceType'] ?? 'credit';
        data['openingBalance'] =
            double.tryParse(data['openingBalance']?.toString() ?? '0') ?? 0.0;
        data['isActive'] = data['isActive'] ?? true;
        data['portalAccessEnabled'] = false;
        data['portalUserIds'] = [];
        data['invitedEmails'] = [];
      } else if (module == MigrationModule.customers) {
        data['isActive'] = data['isActive'] ?? true;
        data['openingBalance'] =
            double.tryParse(data['openingBalance']?.toString() ?? '0') ?? 0.0;
        data['portalAccessEnabled'] = false;
        data['portalUserIds'] = [];
        data['invitedEmails'] = [];
      } else if (module == MigrationModule.inventory) {
        data['type'] = data['type'] ?? 'storable';
        data['uom'] = data['uom'] ?? 'Units';
        data['salePrice'] =
            double.tryParse(data['salePrice']?.toString() ?? '0') ?? 0.0;
        data['costPrice'] =
            double.tryParse(data['costPrice']?.toString() ?? '0') ?? 0.0;
        data['stockQuantity'] = 0.0;
        data['stockBatches'] = [];
      }

      batch.set(docRef, data);
    }

    await batch.commit();
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
        return 'products';
      default:
        throw Exception('Module ${module.label} not yet supported for import');
    }
  }
}
