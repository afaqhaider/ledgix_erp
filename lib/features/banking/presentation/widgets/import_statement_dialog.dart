import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:ledgixerp/features/banking/models/bank_reconciliation_model.dart';
import 'package:ledgixerp/features/banking/services/bank_reconciliation_service.dart';

class ImportStatementDialog extends StatefulWidget {
  final String companyId;
  final String bankAccountId;

  const ImportStatementDialog({
    super.key,
    required this.companyId,
    required this.bankAccountId,
  });

  @override
  State<ImportStatementDialog> createState() => _ImportStatementDialogState();
}

class _ImportStatementDialogState extends State<ImportStatementDialog> {
  final _reconService = BankReconciliationService();
  PlatformFile? _pickedFile;
  bool _isImporting = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
      withData: true,
    );

    if (result != null) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _import() async {
    if (_pickedFile == null || _pickedFile!.bytes == null) return;

    setState(() => _isImporting = true);
    try {
      List<BankStatementEntry> entries = [];
      if (_pickedFile!.extension == 'csv') {
        entries = await _parseCsv(_pickedFile!.bytes!);
      } else {
        entries = await _parseExcel(_pickedFile!.bytes!);
      }

      if (entries.isEmpty) {
        throw Exception('No valid entries found in the file.');
      }

      await _reconService.importEntries(widget.companyId, entries);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing statement: $e')),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<List<BankStatementEntry>> _parseCsv(Uint8List bytes) async {
    final csvString = String.fromCharCodes(bytes);
    final rows = const CsvDecoder().convert(csvString);

    if (rows.isEmpty) return [];

    List<BankStatementEntry> entries = [];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 2) continue;

      entries.add(
        BankStatementEntry(
          id: '',
          companyId: widget.companyId,
          bankAccountId: widget.bankAccountId,
          date: _parseDate(row[0]),
          description: row.length > 1 ? row[1]?.toString() ?? '' : '',
          reference: row.length > 2 ? row[2]?.toString() : null,
          debit: row.length > 3 ? _parseDouble(row[3]) : 0.0,
          credit: row.length > 4 ? _parseDouble(row[4]) : 0.0,
          balance: row.length > 5 ? _parseDouble(row[5]) : 0.0,
          importedAt: DateTime.now(),
        ),
      );
    }
    return entries;
  }

  Future<List<BankStatementEntry>> _parseExcel(Uint8List bytes) async {
    var excel = excel_pkg.Excel.decodeBytes(bytes);
    List<BankStatementEntry> entries = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table]!;
      for (var i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.length < 2) continue;

        entries.add(
          BankStatementEntry(
            id: '',
            companyId: widget.companyId,
            bankAccountId: widget.bankAccountId,
            date: _parseExcelValue(row[0]?.value),
            description: row.length > 1 ? row[1]?.value?.toString() ?? '' : '',
            reference: row.length > 2 ? row[2]?.value?.toString() : null,
            debit: _parseDoubleExcel(row[3]?.value),
            credit: _parseDoubleExcel(row[4]?.value),
            balance: _parseDoubleExcel(row[5]?.value),
            importedAt: DateTime.now(),
          ),
        );
      }
      break;
    }
    return entries;
  }

  DateTime _parseExcelValue(excel_pkg.CellValue? value) {
    if (value == null) return DateTime.now();
    if (value is excel_pkg.DateTimeCellValue) {
      return DateTime(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
        value.second,
      );
    }
    if (value is excel_pkg.DateCellValue) {
      return DateTime(value.year, value.month, value.day);
    }
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  double _parseDoubleExcel(excel_pkg.CellValue? value) {
    if (value == null) return 0.0;
    if (value is excel_pkg.DoubleCellValue) return value.value;
    if (value is excel_pkg.IntCellValue) return value.value.toDouble();
    if (value is excel_pkg.TextCellValue) {
      return double.tryParse(value.value.toString().replaceAll(',', '')) ?? 0.0;
    }
    return double.tryParse(value.toString().replaceAll(',', '')) ?? 0.0;
  }

  DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    return DateTime.tryParse(val.toString()) ?? DateTime.now();
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString().replaceAll(',', '')) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Bank Statement'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select a CSV or XLSX file. Expected columns: Date, Description, Reference, Debit, Credit, Balance.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (_pickedFile != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pickedFile!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _pickedFile = null),
                    ),
                  ],
                ),
              ),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _pickFile,
              icon: const Icon(Icons.file_open),
              label: const Text('Pick Statement File'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _pickedFile == null || _isImporting ? null : _import,
          child: _isImporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Start Import'),
        ),
      ],
    );
  }
}
