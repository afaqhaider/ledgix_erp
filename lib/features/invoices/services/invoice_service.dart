import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getInvoicesRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('salesInvoices');
  }

  Stream<List<InvoiceModel>> getInvoices(String companyId) {
    return _getInvoicesRef(companyId)
        .orderBy('invoiceDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return InvoiceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<String> generateNextInvoiceNumber(String companyId) async {
    final snapshot = await _getInvoicesRef(companyId)
        .orderBy('invoiceNumber', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'INV-0001';
    }

    final lastNumberStr = snapshot.docs.first.get('invoiceNumber') as String;
    final numberMatch = RegExp(r'\d+').firstMatch(lastNumberStr);
    if (numberMatch != null) {
      final lastNumber = int.parse(numberMatch.group(0)!);
      final nextNumber = lastNumber + 1;
      return 'INV-${nextNumber.toString().padLeft(4, '0')}';
    }

    return 'INV-0001';
  }

  Future<void> addInvoice(InvoiceModel invoice) async {
    await _getInvoicesRef(invoice.companyId).doc().set(invoice.toMap());
  }

  Future<void> updateInvoiceStatus(String companyId, String invoiceId, InvoiceStatus status) async {
    await _getInvoicesRef(companyId).doc(invoiceId).update({'status': status.name});
  }
}
