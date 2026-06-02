import 'package:ledgixerp/core/auth/permission.dart';

enum UserRole {
  owner,
  admin,
  accountant,
  manager,
  staff;

  Set<AppPermission> get permissions {
    switch (this) {
      case UserRole.owner:
        return AppPermission.values.toSet();
      case UserRole.admin:
        return {
          AppPermission.viewDashboard,
          AppPermission.manageUsers,
          AppPermission.viewAccounting,
          AppPermission.manageAccounting,
          AppPermission.viewCustomers,
          AppPermission.manageCustomers,
          AppPermission.viewSuppliers,
          AppPermission.manageSuppliers,
          AppPermission.viewInvoices,
          AppPermission.manageInvoices,
          AppPermission.viewReports,
          AppPermission.manageSettings,
        };
      case UserRole.accountant:
        return {
          AppPermission.viewDashboard,
          AppPermission.viewAccounting,
          AppPermission.manageAccounting,
          AppPermission.viewCustomers,
          AppPermission.manageCustomers,
          AppPermission.viewSuppliers,
          AppPermission.manageSuppliers,
          AppPermission.viewInvoices,
          AppPermission.manageInvoices,
          AppPermission.viewReports,
        };
      case UserRole.manager:
        return {
          AppPermission.viewDashboard,
          AppPermission.viewCustomers,
          AppPermission.manageCustomers,
          AppPermission.viewSuppliers,
          AppPermission.manageSuppliers,
          AppPermission.viewInvoices,
          AppPermission.manageInvoices,
          AppPermission.viewReports,
        };
      case UserRole.staff:
        return {AppPermission.viewDashboard};
    }
  }

  bool hasPermission(AppPermission permission) =>
      permissions.contains(permission);
}
