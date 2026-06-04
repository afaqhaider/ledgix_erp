import 'package:ledgixerp/core/auth/permission.dart';

enum UserRole {
  superAdmin('Super Admin', 1000),
  owner('Owner', 100),
  generalManager('General Manager', 80),
  accountant('Accountant', 60),
  cashier('Cashier', 40),
  sales('Sales', 40),
  purchase('Purchase', 40),
  storekeeper('Storekeeper', 40),
  hr('HR', 40),
  employee('Employee', 10);

  final String label;
  final int rank;
  const UserRole(this.label, this.rank);

  bool hasPermission(AppPermission permission) {
    if (this == UserRole.superAdmin || this == UserRole.owner) return true;

    // Basic logic for other roles
    switch (permission) {
      case AppPermission.viewDashboard:
        return true;
      case AppPermission.viewReports:
        return rank >= UserRole.accountant.rank;
      case AppPermission.manageSettings:
      case AppPermission.manageUsers:
        return rank >= UserRole.generalManager.rank;
      case AppPermission.viewAccounting:
      case AppPermission.manageAccounting:
        return rank >= UserRole.accountant.rank;
      default:
        return rank >= 40; // Functional roles have most view/edit permissions
    }
  }

  static UserRole fromName(String name) {
    return UserRole.values.firstWhere(
      (e) => e.name == name || e.label == name,
      orElse: () => UserRole.employee,
    );
  }
}
