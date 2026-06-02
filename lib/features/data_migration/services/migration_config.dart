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
            key: 'trn',
            label: 'TRN Number',
            aliases: ['Tax Number', 'VAT NO', 'TRN'],
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
            key: 'name',
            label: 'Supplier Name',
            isRequired: true,
            aliases: ['Supplier', 'Vendor'],
          ),
          FieldDefinition(key: 'email', label: 'Email'),
          FieldDefinition(key: 'phone', label: 'Phone'),
          FieldDefinition(key: 'trn', label: 'TRN Number', aliases: ['VAT NO']),
          FieldDefinition(key: 'address', label: 'Address'),
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
      default:
        return [];
    }
  }
}
