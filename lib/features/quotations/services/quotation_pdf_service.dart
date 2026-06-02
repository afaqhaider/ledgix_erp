import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/features/quotations/models/quotation_model.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';

class QuotationPdfService {
  static Future<Uint8List> generateQuotation(QuotationModel quotation, CompanyModel company) async {
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
                      pw.Text('SALES QUOTATION', style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.blue)),
                      pw.Text('Quotation #: ${quotation.quotationNumber}', style: pw.TextStyle(font: fontBold)),
                      pw.Text('Date: ${DateFormat('dd MMM yyyy').format(quotation.quotationDate)}', style: pw.TextStyle(font: font)),
                      pw.Text('Valid Until: ${DateFormat('dd MMM yyyy').format(quotation.validUntilDate)}', style: pw.TextStyle(font: font)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              
              // Customer Info
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('QUOTATION FOR', style: pw.TextStyle(font: fontBold, color: PdfColors.grey700)),
                  pw.Text(quotation.customerName, style: pw.TextStyle(font: fontBold)),
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
                  ...quotation.items.map((item) => pw.TableRow(
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
                      _buildTotalRow('Subtotal', quotation.subtotal, font),
                      _buildTotalRow('VAT Amount', quotation.vatAmount, font),
                      pw.Divider(color: PdfColors.grey400),
                      _buildTotalRow('TOTAL AMOUNT', quotation.totalAmount, fontBold, fontSize: 16),
                    ],
                  ),
                ],
              ),

              if (quotation.notes != null) ...[
                pw.SizedBox(height: 32),
                pw.Text('NOTES:', style: pw.TextStyle(font: fontBold)),
                pw.Text(quotation.notes!, style: pw.TextStyle(font: font)),
              ],
              if (quotation.termsAndConditions != null) ...[
                pw.SizedBox(height: 16),
                pw.Text('TERMS & CONDITIONS:', style: pw.TextStyle(font: fontBold)),
                pw.Text(quotation.termsAndConditions!, style: pw.TextStyle(font: font, fontSize: 10)),
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
