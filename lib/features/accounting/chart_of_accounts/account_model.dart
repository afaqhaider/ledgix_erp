import 'package:cloud_firestore/cloud_firestore.dart';

enum AccountType {
  asset('Asset'),
  liability('Liability'),
  equity('Equity'),
  income('Income'),
  costOfSales('Cost of Sales'),
  expense('Expense');

  final String label;
  const AccountType(this.label);
}

class AccountModel {
  final String id;
  final String companyId;
  final String accountCode;
  final String accountName;
  final AccountType accountType;
  final String? parentAccountId;
  final bool isActive;
  final DateTime createdAt;

  AccountModel({
    required this.id,
    required this.companyId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    this.parentAccountId,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'accountCode': accountCode,
      'accountName': accountName,
      'accountType': accountType.name,
      'parentAccountId': parentAccountId,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map, String id) {
    return AccountModel(
      id: id,
      companyId: map['companyId'] ?? '',
      accountCode: map['accountCode'] ?? '',
      accountName: map['accountName'] ?? '',
      accountType: AccountType.values.firstWhere(
        (e) => e.name == map['accountType'],
        orElse: () => AccountType.asset,
      ),
      parentAccountId: map['parentAccountId'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
