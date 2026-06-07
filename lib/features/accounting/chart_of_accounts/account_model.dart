import 'package:cloud_firestore/cloud_firestore.dart';

enum AccountType {
  asset('Asset'),
  liability('Liability'),
  equity('Equity'),
  income('Revenue'),
  costOfSales('Cost of Sales'),
  expense('Expense'),
  otherIncome('Other Revenue'),
  otherExpense('Other Expense');

  final String label;
  const AccountType(this.label);
}

enum AccountCategory {
  // Assets
  currentAsset('Current Asset'),
  nonCurrentAsset('Non Current Asset'),
  cash('Cash'),
  bank('Bank'),
  accountsReceivable('Accounts Receivable'),
  inventory('Inventory'),

  // Liabilities
  currentLiability('Current Liability'),
  nonCurrentLiability('Non Current Liability'),
  accountsPayable('Accounts Payable'),
  vatPayable('VAT Payable'),
  vatInput('VAT Input / Recoverable VAT'),
  vatOutput('VAT Output / VAT Payable'),

  // Equity
  ownerEquity('Owner Equity'),
  retainedEarnings('Retained Earnings'),
  currentYearEarnings('Current Year Earnings'),

  // Income
  sales('Sales'),
  serviceIncome('Service Income'),
  otherIncome('Other Income'),

  // Cost of Sales
  directCost('Direct Cost'),
  cogs('Cost of Goods Sold'),

  // Expense
  operatingExpense('Operating Expense'),
  adminExpense('Admin Expense'),
  staffCost('Staff Cost'),
  rent('Rent'),
  utilities('Utilities'),
  depreciation('Depreciation');

  final String label;
  const AccountCategory(this.label);
}

enum BalanceType {
  debit('Debit'),
  credit('Credit');

  final String label;
  const BalanceType(this.label);

  String get shortLabel => this == BalanceType.debit ? 'Dr' : 'Cr';
}

class AccountModel {
  final String id;
  final String companyId;
  final String accountCode;
  final String accountName;
  final AccountType accountType;
  final AccountCategory accountCategory;
  final String? parentAccountId;
  final int level;
  final bool isGroup;
  final bool allowPosting;
  final BalanceType normalBalance;
  final bool isSystemAccount;
  final bool isActive;
  final double openingBalance;
  final BalanceType openingBalanceType;
  final double currentBalance; // New field for denormalized balance
  final DateTime openingBalanceDate;
  final DateTime createdAt;

  AccountModel({
    required this.id,
    required this.companyId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.accountCategory,
    this.parentAccountId,
    this.level = 0,
    this.isGroup = false,
    this.allowPosting = true,
    required this.normalBalance,
    this.isSystemAccount = false,
    this.isActive = true,
    this.openingBalance = 0.0,
    required this.openingBalanceType,
    this.currentBalance = 0.0,
    required this.openingBalanceDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'accountCode': accountCode,
      'accountName': accountName,
      'accountType': accountType.name,
      'accountCategory': accountCategory.name,
      'parentAccountId': parentAccountId,
      'level': level,
      'isGroup': isGroup,
      'allowPosting': allowPosting,
      'normalBalance': normalBalance.name,
      'isSystemAccount': isSystemAccount,
      'isActive': isActive,
      'openingBalance': openingBalance,
      'openingBalanceType': openingBalanceType.name,
      'currentBalance': currentBalance,
      'openingBalanceDate': Timestamp.fromDate(openingBalanceDate),
      'createdAt': Timestamp.fromDate(createdAt),
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
      accountCategory: AccountCategory.values.firstWhere(
        (e) => e.name == map['accountCategory'],
        orElse: () => AccountCategory.currentAsset,
      ),
      parentAccountId: map['parentAccountId'],
      level: map['level'] ?? 0,
      isGroup: map['isGroup'] ?? false,
      allowPosting: map['allowPosting'] ?? true,
      normalBalance: BalanceType.values.firstWhere(
        (e) => e.name == map['normalBalance'],
        orElse: () => BalanceType.debit,
      ),
      isSystemAccount: map['isSystemAccount'] ?? false,
      isActive: map['isActive'] ?? true,
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0.0,
      openingBalanceType: BalanceType.values.firstWhere(
        (e) => e.name == map['openingBalanceType'],
        orElse: () => BalanceType.debit,
      ),
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
      openingBalanceDate:
          (map['openingBalanceDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  AccountModel copyWith({
    double? currentBalance,
    // Add other fields as needed
  }) {
    return AccountModel(
      id: id,
      companyId: companyId,
      accountCode: accountCode,
      accountName: accountName,
      accountType: accountType,
      accountCategory: accountCategory,
      parentAccountId: parentAccountId,
      level: level,
      isGroup: isGroup,
      allowPosting: allowPosting,
      normalBalance: normalBalance,
      isSystemAccount: isSystemAccount,
      isActive: isActive,
      openingBalance: openingBalance,
      openingBalanceType: openingBalanceType,
      currentBalance: currentBalance ?? this.currentBalance,
      openingBalanceDate: openingBalanceDate,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
