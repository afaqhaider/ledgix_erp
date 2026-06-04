import 'package:cloud_firestore/cloud_firestore.dart';

enum ReconciliationStatus { matched, unmatched, partial, ignored }

class BankStatementEntry {
  final String id;
  final String companyId;
  final String bankAccountId;
  final DateTime date;
  final String description;
  final String? reference;
  final double debit;
  final double credit;
  final double balance;
  final DateTime importedAt;
  final String? matchedTransactionId;
  final String?
  matchedTransactionType; // e.g., 'journal_entry', 'customer_payment', 'supplier_payment'
  final ReconciliationStatus status;
  final String? matchedBy;
  final DateTime? matchedAt;
  final String? unmatchedBy;
  final DateTime? unmatchedAt;

  BankStatementEntry({
    required this.id,
    required this.companyId,
    required this.bankAccountId,
    required this.date,
    required this.description,
    this.reference,
    this.debit = 0.0,
    this.credit = 0.0,
    this.balance = 0.0,
    required this.importedAt,
    this.matchedTransactionId,
    this.matchedTransactionType,
    this.status = ReconciliationStatus.unmatched,
    this.matchedBy,
    this.matchedAt,
    this.unmatchedBy,
    this.unmatchedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'bankAccountId': bankAccountId,
      'date': Timestamp.fromDate(date),
      'description': description,
      'reference': reference,
      'debit': debit,
      'credit': credit,
      'balance': balance,
      'importedAt': Timestamp.fromDate(importedAt),
      'matchedTransactionId': matchedTransactionId,
      'matchedTransactionType': matchedTransactionType,
      'status': status.name,
      'matchedBy': matchedBy,
      'matchedAt': matchedAt != null ? Timestamp.fromDate(matchedAt!) : null,
      'unmatchedBy': unmatchedBy,
      'unmatchedAt': unmatchedAt != null
          ? Timestamp.fromDate(unmatchedAt!)
          : null,
    };
  }

  factory BankStatementEntry.fromMap(Map<String, dynamic> map, String id) {
    return BankStatementEntry(
      id: id,
      companyId: map['companyId'] ?? '',
      bankAccountId: map['bankAccountId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: map['description'] ?? '',
      reference: map['reference'],
      debit: (map['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (map['credit'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      importedAt: (map['importedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      matchedTransactionId: map['matchedTransactionId'],
      matchedTransactionType: map['matchedTransactionType'],
      status: ReconciliationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReconciliationStatus.unmatched,
      ),
      matchedBy: map['matchedBy'],
      matchedAt: (map['matchedAt'] as Timestamp?)?.toDate(),
      unmatchedBy: map['unmatchedBy'],
      unmatchedAt: (map['unmatchedAt'] as Timestamp?)?.toDate(),
    );
  }

  BankStatementEntry copyWith({
    String? matchedTransactionId,
    String? matchedTransactionType,
    ReconciliationStatus? status,
    String? matchedBy,
    DateTime? matchedAt,
    String? unmatchedBy,
    DateTime? unmatchedAt,
  }) {
    return BankStatementEntry(
      id: id,
      companyId: companyId,
      bankAccountId: bankAccountId,
      date: date,
      description: description,
      reference: reference,
      debit: debit,
      credit: credit,
      balance: balance,
      importedAt: importedAt,
      matchedTransactionId: matchedTransactionId ?? this.matchedTransactionId,
      matchedTransactionType:
          matchedTransactionType ?? this.matchedTransactionType,
      status: status ?? this.status,
      matchedBy: matchedBy ?? this.matchedBy,
      matchedAt: matchedAt ?? this.matchedAt,
      unmatchedBy: unmatchedBy ?? this.unmatchedBy,
      unmatchedAt: unmatchedAt ?? this.unmatchedAt,
    );
  }
}
