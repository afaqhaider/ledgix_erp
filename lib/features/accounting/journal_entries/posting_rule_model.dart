enum PostingSourceType {
  salesInvoice,
  customerPayment,
  supplierPayment,
}

class PostingRuleModel {
  final PostingSourceType sourceType;
  final String debitAccountId;
  final String creditAccountId;
  final String? taxAccountId;

  PostingRuleModel({
    required this.sourceType,
    required this.debitAccountId,
    required this.creditAccountId,
    this.taxAccountId,
  });
}
