enum MigrationModule {
  customers('Customers'),
  suppliers('Suppliers'),
  chartOfAccounts('Chart of Accounts'),
  bankAccounts('Bank Accounts'),
  salesInvoices('Sales Invoices'),
  purchaseOrders('Purchase Orders'),
  journalEntries('Journal Entries'),
  payments('Payments'),
  creditNotes('Credit Notes'),
  debitNotes('Debit Notes'),
  inventory('Inventory');

  final String label;
  const MigrationModule(this.label);
}

enum DuplicateStrategy {
  skip('Skip Duplicates'),
  update('Update Existing'),
  createNew('Create as New');

  final String label;
  const DuplicateStrategy(this.label);
}

class FieldDefinition {
  final String key;
  final String label;
  final bool isRequired;
  final List<String> aliases;
  final List<String>? options;
  final bool allowCustom;

  FieldDefinition({
    required this.key,
    required this.label,
    this.isRequired = false,
    this.aliases = const [],
    this.options,
    this.allowCustom = false,
  });
}

class ImportRow {
  final int index;
  final Map<String, dynamic> data;
  final Map<String, String?> errors;
  bool isSelected;

  ImportRow({
    required this.index,
    required this.data,
    this.errors = const {},
    this.isSelected = true,
  });

  bool get isValid => errors.isEmpty;
}

class ImportSummary {
  final int totalRows;
  final int validRows;
  final int invalidRows;
  final int duplicateRows;

  ImportSummary({
    required this.totalRows,
    required this.validRows,
    required this.invalidRows,
    required this.duplicateRows,
  });
}
