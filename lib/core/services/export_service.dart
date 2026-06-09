import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ExportService {
  /// Exports data to an Excel file and shares it.
  Future<void> exportToExcel({
    required String fileName,
    required String sheetName,
    required List<String> headers,
    required List<List<dynamic>> data,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[sheetName];

    // Add headers
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }

    // Add data
    for (var row = 0; row < data.length; row++) {
      for (var col = 0; col < data[row].length; col++) {
        final value = data[row][col];
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
            )
            .value = _toCellValue(
          value,
        );
      }
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return;

    if (kIsWeb) {
      // For web, use printing package to 'print' (download) the bytes
      await Printing.sharePdf(
        bytes: Uint8List.fromList(fileBytes),
        filename: '$fileName.xlsx',
      );
    } else {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.xlsx');
      await file.writeAsBytes(fileBytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Exported $fileName'));
    }
  }

  CellValue? _toCellValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return DoubleCellValue(value.toDouble());
    if (value is bool) return BoolCellValue(value);
    return TextCellValue(value.toString());
  }

  /// Exports a standard report to PDF.
  Future<void> exportReportToPdf({
    required String title,
    required String subTitle,
    required List<String> headers,
    required List<List<String>> data,
    Map<String, String>? summary,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            _buildHeader(title, subTitle),
            pw.SizedBox(height: 20),
            _buildTable(headers, data),
            if (summary != null) ...[
              pw.SizedBox(height: 20),
              _buildSummary(summary),
            ],
            pw.SizedBox(height: 20),
            pw.Text(
              'Generated on: ${DateTime.now().toString()}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: title,
    );
  }

  pw.Widget _buildHeader(String title, String subTitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(subTitle, style: const pw.TextStyle(fontSize: 14)),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildTable(List<String> headers, List<List<String>> data) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft,
      },
    );
  }

  pw.Widget _buildSummary(Map<String, String> summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Divider(),
        ...summary.entries.map(
          (e) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  '${e.key}: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(e.value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
