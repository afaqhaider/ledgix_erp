import 'package:cloud_firestore/cloud_firestore.dart';

enum BankAccountType { cash, bank, card, wallet }

class BankAccountModel {
  final String id;
  final String companyId;
  final String accountName;
  final BankAccountType accountType;
  final String? bankName;
  final String? accountNumber;
  final String? iban;
  final String currency;
  final String linkedChartAccountId;
  final double openingBalance;
  final double currentBalance;
  final bool isActive;
  final DateTime createdAt;

  BankAccountModel({
    required this.id,
    required this.companyId,
    required this.accountName,
    required this.accountType,
    this.bankName,
    this.accountNumber,
    this.iban,
    required this.currency,
    required this.linkedChartAccountId,
    required this.openingBalance,
    this.currentBalance = 0.0,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'accountName': accountName,
      'accountType': accountType.name,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'iban': iban,
      'currency': currency,
      'linkedChartAccountId': linkedChartAccountId,
      'openingBalance': openingBalance,
      'currentBalance': currentBalance,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BankAccountModel.fromMap(Map<String, dynamic> map, String id) {
    return BankAccountModel(
      id: id,
      companyId: map['companyId'] ?? '',
      accountName: map['accountName'] ?? '',
      accountType: BankAccountType.values.firstWhere(
        (e) => e.name == map['accountType'],
        orElse: () => BankAccountType.bank,
      ),
      bankName: map['bankName'],
      accountNumber: map['accountNumber'],
      iban: map['iban'],
      currency: map['currency'] ?? 'USD',
      linkedChartAccountId: map['linkedChartAccountId'] ?? '',
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
