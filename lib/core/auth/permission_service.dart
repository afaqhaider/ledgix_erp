import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/core/auth/user_role.dart';

class PermissionService {
  static bool hasPermission(UserRole role, AppPermission permission) {
    return role.hasPermission(permission);
  }

  static bool canViewAccounting(UserRole role) =>
      hasPermission(role, AppPermission.viewAccounting);
  static bool canViewCustomers(UserRole role) =>
      hasPermission(role, AppPermission.viewCustomers);
  static bool canViewSuppliers(UserRole role) =>
      hasPermission(role, AppPermission.viewSuppliers);
  static bool canViewInvoices(UserRole role) =>
      hasPermission(role, AppPermission.viewInvoices);
  static bool canViewReports(UserRole role) =>
      hasPermission(role, AppPermission.viewReports);
  static bool canManageSettings(UserRole role) =>
      hasPermission(role, AppPermission.manageSettings);
}
