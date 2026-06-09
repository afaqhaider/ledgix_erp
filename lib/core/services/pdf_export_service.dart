import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/suppliers/models/bill_model.dart';
import '../../features/expenses/models/expense_voucher_model.dart';
import '../../features/crm/customer_payments/models/customer_payment_model.dart';
import '../../features/reports/services/cash_flow_service.dart';
import '../../features/reports/services/job_report_service.dart';
import 'package:intl/intl.dart';

class PdfExportService {
  // --- INVOICE ---
  Future<void> printInvoice(InvoiceModel invoice) async {
    final pdf = await generateInvoicePdf(invoice);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<Uint8List> exportInvoicePdf(InvoiceModel invoice) async {
    final pdf = await generateInvoicePdf(invoice);
    return pdf.save();
  }

  Future<pw.Document> generateInvoicePdf(InvoiceModel invoice) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Sales Invoice', invoice.invoiceNumber, invoice.invoiceDate),
              pw.SizedBox(height: 20),
              pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(invoice.customerName),
              pw.SizedBox(height: 30),
              
              // Items Table
              pw.TableHelper.fromTextArray(
                headers: ['Description', 'Qty', 'Unit Price', 'Total'],
                data: invoice.items.map((item) => [
                  item.description,
                  item.quantity.toString(),
                  item.unitPrice.toStringAsFixed(2),
                  item.lineTotal.toStringAsFixed(2),
                ]).toList(),
              ),
              
              pw.SizedBox(height: 20),
              _buildFooter(invoice.subtotal, invoice.vatAmount, invoice.totalAmount),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // --- BILL ---
  Future<void> printBill(BillModel bill) async {
    final pdf = await generateBillPdf(bill);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<pw.Document> generateBillPdf(BillModel bill) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Vendor Bill', bill.billNumber, bill.billDate),
              pw.SizedBox(height: 20),
              pw.Text('Vendor:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(bill.supplierName),
              pw.SizedBox(height: 30),
              
              // Items Table
              pw.TableHelper.fromTextArray(
                headers: ['Description', 'Qty', 'Unit Price', 'Total'],
                data: bill.items.map((item) => [
                  item.description,
                  item.quantity.toString(),
                  item.unitPrice.toStringAsFixed(2),
                  item.lineTotal.toStringAsFixed(2),
                ]).toList(),
              ),
              
              pw.SizedBox(height: 20),
              _buildFooter(bill.subtotal, bill.vatAmount, bill.totalAmount),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // --- EXPENSE VOUCHER ---
  Future<void> printExpenseVoucher(ExpenseVoucherModel voucher) async {
    final pdf = await generateExpenseVoucherPdf(voucher);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<pw.Document> generateExpenseVoucherPdf(ExpenseVoucherModel voucher) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Expense Voucher', voucher.voucherNumber, voucher.date),
              pw.SizedBox(height: 20),
              pw.Text('Paid From: ${voucher.fromAccountName}'),
              pw.Text('Description: ${voucher.description}'),
              pw.SizedBox(height: 30),
              
              // Lines Table
              pw.TableHelper.fromTextArray(
                headers: ['Account', 'Description', 'Amount', 'VAT', 'Total'],
                data: voucher.lines.map((line) => [
                  line.accountName,
                  line.description,
                  line.amount.toStringAsFixed(2),
                  line.vatAmount.toStringAsFixed(2),
                  line.total.toStringAsFixed(2),
                ]).toList(),
              ),
              
              pw.SizedBox(height: 20),
              _buildFooter(voucher.totalAmount - voucher.totalVat, voucher.totalVat, voucher.totalAmount),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // --- RECEIPT (CUSTOMER PAYMENT) ---
  Future<void> printReceipt(CustomerPaymentModel payment) async {
    final pdf = await generateReceiptPdf(payment);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<pw.Document> generateReceiptPdf(CustomerPaymentModel payment) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Official Receipt', payment.paymentNumber, payment.paymentDate),
              pw.SizedBox(height: 20),
              pw.Text('Received From:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(payment.customerName),
              pw.SizedBox(height: 10),
              pw.Text('Payment Method: ${payment.paymentMethod.name.toUpperCase()}'),
              if (payment.referenceNumber != null) pw.Text('Reference: ${payment.referenceNumber}'),
              pw.SizedBox(height: 30),
              
              if (payment.allocations.isNotEmpty) ...[
                pw.Text('Allocations:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.TableHelper.fromTextArray(
                  headers: ['Invoice #', 'Amount'],
                  data: payment.allocations.map((a) => [
                    a.invoiceNumber,
                    a.amount.toStringAsFixed(2),
                  ]).toList(),
                ),
              ] else if (payment.invoiceNumber != null) ...[
                pw.Text('Payment against Invoice: ${payment.invoiceNumber}'),
              ] else ...[
                pw.Text('Payment Type: ${payment.receiptType.label}'),
              ],
              
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      children: [
                        pw.Text('Total Amount Received', style: pw.TextStyle(fontSize: 14)),
                        pw.Text(payment.amount.toStringAsFixed(2), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.Spacer(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Authorized Signature'),
                  pw.Text('Customer Signature'),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // --- CASH FLOW REPORT ---
  Future<void> printCashFlowReport(CashFlowData data, DateTime start, DateTime end) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('LedGix ERP', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('Cash Flow Statement', style: pw.TextStyle(fontSize: 18)),
              pw.Text('Period: ${dateFormat.format(start)} - ${dateFormat.format(end)}'),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              _buildReportLine('Cash at beginning of period', data.openingCash, isBold: true),
              pw.SizedBox(height: 10),
              
              pw.Text('Cash flows from operating activities', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              _buildReportLine('Net cash from operating activities', data.operatingActivities, indent: 20),
              pw.SizedBox(height: 10),

              pw.Text('Cash flows from investing activities', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              _buildReportLine('Net cash used in investing activities', data.investingActivities, indent: 20),
              pw.SizedBox(height: 10),

              pw.Text('Cash flows from financing activities', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              _buildReportLine('Net cash from financing activities', data.financingActivities, indent: 20),
              pw.SizedBox(height: 10),

              pw.Divider(),
              _buildReportLine('Net increase/(decrease) in cash', data.netCashIncrease, isBold: true),
              _buildReportLine('Cash at end of period', data.closingCash, isBold: true),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // --- JOB REPORT ---
  Future<void> printJobReport(List<JobReportData> reports) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('LedGix ERP', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('Job Profitability Report', style: pw.TextStyle(fontSize: 18)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              pw.TableHelper.fromTextArray(
                headers: ['Job #', 'Job Name', 'Revenue', 'Expenses', 'Profit/Loss', 'Margin %'],
                data: reports.map((r) => [
                  r.job.jobNumber,
                  r.job.jobName,
                  r.actualRevenue.toStringAsFixed(2),
                  r.actualExpense.toStringAsFixed(2),
                  r.actualProfitLoss.toStringAsFixed(2),
                  '${r.profitMargin.toStringAsFixed(1)}%',
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerRight,
                headerAlignment: pw.Alignment.centerRight,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // --- PRIVATE HELPERS ---

  pw.Widget _buildHeader(String title, String number, DateTime date) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('LedGix ERP', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text(title, style: pw.TextStyle(fontSize: 18)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('$title #: $number'),
            pw.Text('Date: ${DateFormat('MMM dd, yyyy').format(date)}'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFooter(double subtotal, double vat, double total) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Subtotal: ${subtotal.toStringAsFixed(2)}'),
            pw.Text('VAT: ${vat.toStringAsFixed(2)}'),
            pw.Divider(),
            pw.Text('Total: ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildReportLine(String label, double amount, {bool isBold = false, double indent = 0}) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(left: indent),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: isBold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
          pw.Text(
            amount.toStringAsFixed(2),
            style: isBold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }
}
