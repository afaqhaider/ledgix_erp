import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/features/quotations/models/quotation_model.dart';
import 'package:ledgixerp/features/quotations/services/quotation_service.dart';
import 'package:ledgixerp/features/quotations/services/quotation_pdf_service.dart';
import 'package:ledgixerp/features/quotations/presentation/screens/add_quotation_screen.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/features/approvals/models/approval_request_model.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuotationsScreen extends StatefulWidget {
  final AppUser user;
  const QuotationsScreen({super.key, required this.user});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  final _quotationService = QuotationService();
  final _companyService = CompanyService();
  final _approvalService = ApprovalService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = widget.user.role.hasPermission(AppPermission.manageInvoices);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Quotations'),
        actions: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddQuotationScreen(user: widget.user),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('New Quotation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<QuotationModel>>(
        stream: _quotationService.getQuotations(widget.user.companyId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final quotations = snapshot.data ?? [];

          if (quotations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.request_quote_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No quotations found',
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: DataTable(
                horizontalMargin: 24,
                columnSpacing: 32,
                columns: const [
                  DataColumn(label: Text('Quotation #', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Approval', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: quotations.map((quo) {
                  final isConverted = quo.status == QuotationStatus.converted;
                  final isApproved = quo.approvalStatus == 'approved';
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(quo.quotationNumber)),
                      DataCell(Text(quo.customerName)),
                      DataCell(Text(DateFormat('dd MMM yyyy').format(quo.quotationDate))),
                      DataCell(Text(NumberFormat('#,##0.00').format(quo.totalAmount))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(quo.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            quo.status.name.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(quo.status),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        quo.approvalStatus == null 
                          ? TextButton(
                              onPressed: () => _submitForApproval(quo),
                              child: const Text('Submit', style: TextStyle(fontSize: 12)),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getApprovalStatusColor(quo.approvalStatus!).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                quo.approvalStatus!.toUpperCase(),
                                style: TextStyle(
                                  color: _getApprovalStatusColor(quo.approvalStatus!),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print_outlined, size: 20),
                              tooltip: 'Print/Download PDF',
                              onPressed: () => _printQuotation(quo),
                            ),
                            if (canManage && !isConverted && (isApproved || widget.user.role.name == 'Admin' || widget.user.role.name == 'Owner'))
                              IconButton(
                                icon: const Icon(Icons.receipt_long, size: 20),
                                tooltip: 'Convert to Invoice',
                                color: theme.colorScheme.primary,
                                onPressed: () => _convertToInvoice(quo),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.draft: return Colors.grey;
      case QuotationStatus.sent: return Colors.blue;
      case QuotationStatus.accepted: return Colors.green;
      case QuotationStatus.rejected: return Colors.red;
      case QuotationStatus.expired: return Colors.orange;
      case QuotationStatus.converted: return Colors.purple;
    }
  }

  Color _getApprovalStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _submitForApproval(QuotationModel quo) async {
    try {
      final request = ApprovalRequestModel(
        id: '',
        companyId: widget.user.companyId!,
        sourceType: 'quotation',
        sourceId: quo.id,
        sourceNumber: quo.quotationNumber,
        requestedByUserId: widget.user.uid,
        requestedByUserName: widget.user.fullName,
        requestedAt: DateTime.now(),
      );

      await _approvalService.submitForApproval(request);
      
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.user.companyId)
          .collection('quotations')
          .doc(quo.id)
          .update({'approvalStatus': 'pending'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation submitted for approval')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _printQuotation(QuotationModel quo) async {
    try {
      final company = await _companyService.getCompany(widget.user.companyId!);
      if (company == null) throw 'Company not found';
      
      final pdfBytes = await QuotationPdfService.generateQuotation(quo, company);
      
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Quotation_${quo.quotationNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _convertToInvoice(QuotationModel quo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Invoice'),
        content: Text('Do you want to convert Quotation ${quo.quotationNumber} to a Sales Invoice?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Convert')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _quotationService.convertToInvoice(quo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quotation converted to Invoice successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error converting to invoice: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }
}
