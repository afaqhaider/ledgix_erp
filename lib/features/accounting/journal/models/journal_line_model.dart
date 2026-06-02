class JournalLineModel {
  final String accountId;
  final String accountName;
  final String accountCode;
  final double debit;
  final double credit;
  final String? memo;

  JournalLineModel({
    required this.accountId,
    required this.accountName,
    required this.accountCode,
    required this.debit,
    required this.credit,
    this.memo,
  });

  Map<String, dynamic> toMap() {
    return {
      'accountId': accountId,
      'accountName': accountName,
      'accountCode': accountCode,
      'debit': debit,
      'credit': credit,
      'memo': memo,
    };
  }

  factory JournalLineModel.fromMap(Map<String, dynamic> map) {
    return JournalLineModel(
      accountId: map['accountId'] ?? '',
      accountName: map['accountName'] ?? '',
      accountCode: map['accountCode'] ?? '',
      debit: (map['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (map['credit'] as num?)?.toDouble() ?? 0.0,
      memo: map['memo'],
    );
  }
}
