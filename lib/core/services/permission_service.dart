class PermissionService {
  final Map<String, List<String>> _rolePermissions = {
    'super_admin': ['all'],
    'owner': ['all'],
    'general_manager': [
      'view_settings',
      'view_coa',
      'view_journal',
      'view_invoices',
      'view_bills',
      'view_inventory',
      'view_reports',
      'create_invoices',
      'edit_invoices',
      'approve_invoices',
      'create_bills',
      'edit_bills',
      'approve_bills',
      'manage_users',
    ],
    'accountant': [
      'view_settings',
      'view_coa',
      'edit_coa',
      'view_journal',
      'create_journal',
      'edit_journal',
      'post_journal',
      'view_invoices',
      'view_bills',
      'view_inventory',
      'view_reports',
      'export_data',
    ],
    'cashier': ['view_payments', 'create_payments', 'view_invoices'],
    'sales': [
      'view_invoices',
      'create_invoices',
      'edit_invoices',
      'view_customers',
      'view_inventory',
    ],
    'purchase': ['view_bills', 'create_bills', 'edit_bills', 'view_suppliers'],
    'storekeeper': ['view_inventory', 'manage_inventory', 'view_goods_receipt'],
    'hr': ['manage_employees', 'view_payroll', 'process_payroll'],
    'employee': ['view_self_payslip', 'request_leave'],
  };

  bool hasPermission(
    String? role,
    String permission, {
    Map<String, dynamic>? customPermissions,
  }) {
    if (role == null) return false;

    // Normalize role string if needed
    final normalizedRole = role.toLowerCase().replaceAll(' ', '_');

    if (normalizedRole == 'super_admin' || normalizedRole == 'owner') {
      return true;
    }

    // Check custom permissions first
    if (customPermissions != null &&
        customPermissions.containsKey(permission)) {
      return customPermissions[permission] == true;
    }

    final permissions = _rolePermissions[normalizedRole] ?? [];
    return permissions.contains(permission) || permissions.contains('all');
  }
}
