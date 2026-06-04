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
          FieldDefinition(key: 'trnVatNumber', label: 'TRN / VAT Number', aliases: ['VAT NO', 'TRN Number', 'TRN']),
          FieldDefinition(key: 'address', label: 'Address'),
          FieldDefinition(key: 'country', label: 'Country'),
        ];
      case MigrationModule.chartOfAccounts:
        return [
          FieldDefinition(
            key: 'code',
            label: 'Account Code',
            isRequired: true,
            aliases: ['Code', 'Account ID'],
          ),
          FieldDefinition(
            key: 'name',
            label: 'Account Name',
            isRequired: true,
            aliases: ['Name', 'Account'],
          ),
          FieldDefinition(
            key: 'type',
            label: 'Account Type',
            isRequired: true,
            aliases: ['Type', 'Category'],
          ),
          FieldDefinition(key: 'description', label: 'Description'),
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
