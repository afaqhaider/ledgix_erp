import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String type; // 'customer', 'supplier', 'invoice', 'bill', 'journal', 'payment'
  final DateTime date;
  final Map<String, dynamic> data;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.date,
    required this.data,
  });
}

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<SearchResult>> globalSearch(String companyId, String query) async {
    if (query.length < 2) return [];
    
    final searchQuery = query.toLowerCase().trim();
    final List<SearchResult> results = [];

    // Search Collections in Parallel
    final futures = [
      _searchCollection(companyId, 'customers', 'name', searchQuery, 'customer'),
      _searchCollection(companyId, 'suppliers', 'name', searchQuery, 'supplier'),
      _searchCollection(companyId, 'salesInvoices', 'invoiceNumber', searchQuery, 'invoice'),
      _searchCollection(companyId, 'supplierBills', 'billNumber', searchQuery, 'bill'),
      _searchCollection(companyId, 'journalEntries', 'reference', searchQuery, 'journal'),
      _searchCollection(companyId, 'customerPayments', 'paymentNumber', searchQuery, 'payment'),
      _searchCollection(companyId, 'supplierPayments', 'paymentNumber', searchQuery, 'payment'),
    ];

    final searchBatches = await Future.wait(futures);
    for (var batch in searchBatches) {
      results.addAll(batch);
    }

    // Sort by date (descending)
    results.sort((a, b) => b.date.compareTo(a.date));
    
    return results.take(20).toList();
  }

  Future<List<SearchResult>> _searchCollection(
    String companyId,
    String collection,
    String field,
    String query,
    String type,
  ) async {
    try {
      // Basic text search using startAt/endAt
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection(collection)
          .where(field, isGreaterThanOrEqualTo: query.toUpperCase())
          .where(field, isLessThanOrEqualTo: '${query.toUpperCase()}\uf8ff')
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _mapToSearchResult(doc.id, data, type);
      }).toList();
    } catch (e) {
      debugPrint('Search Error ($collection): $e');
      return [];
    }
  }

  SearchResult _mapToSearchResult(String id, Map<String, dynamic> data, String type) {
    String title = '';
    String subtitle = '';
    DateTime date = DateTime.now();

    switch (type) {
      case 'customer':
      case 'supplier':
        title = data['name'] ?? 'Unknown';
        subtitle = data['email'] ?? data['phone'] ?? 'Contact';
        date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        break;
      case 'invoice':
        title = data['invoiceNumber'] ?? 'INV-?';
        subtitle = '${data['customerName']} - ${data['totalAmount']}';
        date = (data['invoiceDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        break;
      case 'bill':
        title = data['billNumber'] ?? 'BILL-?';
        subtitle = '${data['supplierName']} - ${data['totalAmount']}';
        date = (data['billDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        break;
      case 'journal':
        title = data['reference'] ?? 'JV-?';
        subtitle = data['description'] ?? 'Journal Entry';
        date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        break;
      case 'payment':
        title = data['paymentNumber'] ?? 'PAY-?';
        subtitle = '${data['customerName'] ?? data['supplierName'] ?? 'Member'} - ${data['amount']}';
        date = (data['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        break;
    }

    return SearchResult(
      id: id,
      title: title,
      subtitle: subtitle,
      type: type,
      date: date,
      data: data,
    );
  }
}
