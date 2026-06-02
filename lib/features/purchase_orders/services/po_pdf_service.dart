import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/features/purchase_orders/models/purchase_order_model.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';

class POPdfService {
  static Future<Uint8List> generatePO(PurchaseOrderModel po, CompanyModel company) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(company.companyLegalName, style: pw.TextStyle(font: fontBold, fontSize: 18)),
                      pw.Text(company.country, style: pw.TextStyle(font: font)),
                      if (company.trnVatNumber != null) pw.Text('TRN: ${company.trnVatNumber}', style: pw.TextStyle(font: font)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('PURCHASE ORDER', style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.blue)),
                      pw.Text('PO #: ${po.poNumber}', style: pw.TextStyle(font: fontBold)),
                      pw.Text('Date: ${DateFormat('dd MMM yyyy').format(po.poDate)}', style: pw.TextStyle(font: font)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              
              // Supplier Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SUPPLIER', style: pw.TextStyle(font: fontBold, color: PdfColors.grey700)),
                      pw.Text(po.supplierName, style: pw.TextStyle(font: fontBold)),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('EXPECTED DELIVERY', style: pw.TextStyle(font: fontBold, color: PdfColors.grey700)),
                      pw.Text(DateFormat('dd MMM yyyy').format(po.expectedDeliveryDate), style: pw.TextStyle(font: fontBold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildHeaderCell('Description', fontBold),
                      _buildHeaderCell('Qty', fontBold, align: pw.TextAlign.center),
                      _buildHeaderCell('Unit Price', fontBold, align: pw.TextAlign.right),
                      _buildHeaderCell('Total', fontBold, align: pw.TextAlign.right),
                    ],
                  ),
                  ...po.items.map((item) => pw.TableRow(
                    children: [
                      _buildDataCell(item.description, font),
                      _buildDataCell(item.quantity.toString(), font, align: pw.TextAlign.center),
                      _buildDataCell(NumberFormat('#,##0.00').format(item.unitPrice), font, align: pw.TextAlign.right),
                      _buildDataCell(NumberFormat('#,##0.00').format(item.lineTotal), fontBold, align: pw.TextAlign.right),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 32),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildTotalRow('Subtotal', po.subtotal, font),
                      _buildTotalRow('VAT Amount', po.vatAmount, font),
                      pw.Divider(color: PdfColors.grey400),
                      _buildTotalRow('TOTAL AMOUNT', po.totalAmount, fontBold, fontSize: 16),
                    ],
                  ),
                ],
              ),

              if (po.notes != null) ...[
                pw.SizedBox(height: 32),
                pw.Text('NOTES:', style: pw.TextStyle(font: fontBold)),
                pw.Text(po.notes!, style: pw.TextStyle(font: font)),
              ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeaderCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(font: font), textAlign: align),
    );
  }

  static pw.Widget _buildDataCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(font: font), textAlign: align),
    );
  }

  static pw.Widget _buildTotalRow(String label, double value, pw.Font font, {double fontSize = 12}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$label: ', style: pw.TextStyle(font: font, fontSize: fontSize)),
          pw.SizedBox(width: 16),
          pw.Text(NumberFormat('#,##0.00').format(value), style: pw.TextStyle(font: font, fontSize: fontSize)),
        ],
      ),
    );
  }
}
