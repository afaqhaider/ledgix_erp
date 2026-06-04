import 'package:ledgixerp/core/auth/permission.dart';

enum UserRole {
  owner(100),
  financeManager(80),
  controller(60),
  admin(50),
  accountant(40),
  dataEntry(20);

  final int rank;
  const UserRole(this.rank);

  Set<AppPermission> get defaultPermissions {
    switch (this) {
      case UserRole.owner:
        return AppPermission.values.toSet();
      case UserRole.financeManager:
        return {...AppPermission.values.toSet()}
          ..remove(AppPermission.manageCompany);
      case UserRole.controller:
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
          AppPermission.viewBills,
          AppPermission.manageBills,
          AppPermission.viewReports,
          AppPermission.approveTransactions,
          AppPermission.viewApprovals,
        };
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
          AppPermission.viewBills,
          AppPermission.manageBills,
          AppPermission.viewReports,
          AppPermission.manageSettings,
          AppPermission.viewApprovals,
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
          AppPermission.viewBills,
          AppPermission.manageBills,
          AppPermission.viewReports,
          AppPermission.viewApprovals,
        };
      case UserRole.dataEntry:
        return {
          AppPermission.viewDashboard,
          AppPermission.viewCustomers,
          AppPermission.viewSuppliers,
          AppPermission.viewInvoices,
          AppPermission.viewBills,
          AppPermission.viewAccounting,
        };
    }
  }

  bool hasPermission(AppPermission permission) =>
      defaultPermissions.contains(permission);
}
