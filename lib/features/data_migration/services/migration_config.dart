import '../models/migration_models.dart';

class MigrationConfig {
  static List<FieldDefinition> getFields(MigrationModule module) {
    switch (module) {
      case MigrationModule.customers:
        return [
          FieldDefinition(
            key: 'name',
            label: 'Customer Name',
            isRequired: true,
            aliases: ['Name', 'Customer', 'Client'],
          ),
          FieldDefinition(
            key: 'email',
            label: 'Email',
            aliases: ['Email Address'],
          ),
          FieldDefinition(
            key: 'phone',
            label: 'Phone',
            aliases: ['Mobile', 'Contact', 'Telephone'],
          ),
          FieldDefinition(
            key: 'taxNumber',
            label: 'Tax Number (TRN)',
            aliases: ['Tax Number', 'VAT NO', 'TRN', 'TRN Number'],
          ),
          FieldDefinition(key: 'address', label: 'Address'),
          FieldDefinition(
            key: 'openingBalance',
            label: 'Opening Balance',
            aliases: ['Balance'],
          ),
        ];
      case MigrationModule.suppliers:
        return [
          FieldDefinition(
            key: 'supplierCode',
            label: 'Supplier Code',
            isRequired: true,
            aliases: ['Code', 'Supplier ID', 'Vendor Code'],
          ),
          FieldDefinition(
            key: 'supplierName',
            label: 'Supplier Name',
            isRequired: true,
            aliases: ['Supplier', 'Vendor', 'Name', 'Supplier Name'],
          ),
          FieldDefinition(key: 'email', label: 'Email'),
          FieldDefinition(key: 'phone', label: 'Phone'),
          FieldDefinition(
            key: 'trnVatNumber',
            label: 'TRN / VAT Number',
            aliases: ['VAT NO', 'TRN Number', 'TRN'],
          ),
          FieldDefinition(key: 'address', label: 'Address'),
          FieldDefinition(key: 'country', label: 'Country'),
        ];
      case MigrationModule.chartOfAccounts:
        return [
          FieldDefinition(
            key: 'name',
            label: 'Account Name',
            isRequired: true,
            aliases: ['Name', 'Account'],
          ),
          FieldDefinition(
            key: 'category',
            label: 'Category',
            isRequired: false, // Validated manually: Type or Category required
            aliases: ['Category', 'Subcategory', 'Classification'],
            options: [
              'Current Asset', 'Non Current Asset', 'Cash', 'Bank', 'Accounts Receivable',
              'Current Liability', 'Non Current Liability', 'Accounts Payable', 'VAT Payable',
              'Owner Equity', 'Retained Earnings', 'Current Year Earnings',
              'Sales', 'Service Income', 'Other Income',
              'Direct Cost', 'Cost of Goods Sold',
              'Operating Expense', 'Admin Expense', 'Staff Cost', 'Rent', 'Utilities', 'Depreciation'
            ],
            allowCustom: true,
          ),
          FieldDefinition(
            key: 'type',
            label: 'Account Type',
            isRequired: false, // Validated manually: Type or Category required
            aliases: ['Type', 'Major Type'],
            options: ['Asset', 'Liability', 'Equity', 'Revenue', 'Cost of Sales', 'Expense', 'Other Revenue', 'Other Expense'],
          ),
          FieldDefinition(
            key: 'code',
            label: 'Account Code',
            isRequired: false,
            aliases: ['Code', 'Account ID', 'Number'],
          ),
          FieldDefinition(
            key: 'parentCode',
            label: 'Parent Code',
            aliases: ['Parent', 'Parent Account', 'Group'],
          ),
          FieldDefinition(
            key: 'isPostable',
            label: 'Is Postable?',
            aliases: ['Postable', 'Allow Posting', 'Posting'],
            options: ['Yes', 'No'],
          ),
          FieldDefinition(
            key: 'openingBalance',
            label: 'Opening Balance',
            aliases: ['Balance', 'Opening'],
          ),
          FieldDefinition(
            key: 'normalBalance',
            label: 'Normal Balance',
            aliases: ['Normal', 'Balance Type', 'Dr/Cr'],
            options: ['Dr', 'Cr'],
          ),
        ];
      case MigrationModule.journalEntries:
        return [
          FieldDefinition(key: 'date', label: 'Date', isRequired: true),
          FieldDefinition(key: 'reference', label: 'Reference'),
          FieldDefinition(key: 'accountCode', label: 'Account Code', isRequired: true),
          FieldDefinition(key: 'description', label: 'Description'),
          FieldDefinition(key: 'debit', label: 'Debit'),
          FieldDefinition(key: 'credit', label: 'Credit'),
        ];
      case MigrationModule.salesInvoices:
        return [
          FieldDefinition(key: 'invoiceNumber', label: 'Invoice #', isRequired: true),
          FieldDefinition(key: 'date', label: 'Date', isRequired: true),
          FieldDefinition(key: 'customerName', label: 'Customer', isRequired: true),
          FieldDefinition(key: 'itemCode', label: 'Item Code'),
          FieldDefinition(key: 'quantity', label: 'Quantity'),
          FieldDefinition(key: 'unitPrice', label: 'Price'),
        ];
      case MigrationModule.inventory:
        return [
          FieldDefinition(
            key: 'sku',
            label: 'SKU / Item Code',
            isRequired: true,
            aliases: ['SKU', 'Item Code', 'Part Number'],
          ),
          FieldDefinition(
            key: 'name',
            label: 'Product Name',
            isRequired: true,
            aliases: ['Name', 'Product', 'Item'],
          ),
          FieldDefinition(key: 'description', label: 'Description'),
          FieldDefinition(
            key: 'salePrice',
            label: 'Sale Price',
            aliases: ['Price', 'Selling Price'],
          ),
          FieldDefinition(
            key: 'costPrice',
            label: 'Cost Price',
            aliases: ['Cost', 'Purchase Price'],
          ),
        ];
      default:
        return [];
    }
  }
}
