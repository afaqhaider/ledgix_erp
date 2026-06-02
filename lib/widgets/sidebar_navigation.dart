import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import 'package:ledgixerp/core/auth/permission.dart';

class SidebarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final AppPermission permission;

  const SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.permission,
  });
}

class SidebarNavigation extends StatelessWidget {
  final UserRole role;
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const SidebarNavigation({
    super.key,
    required this.role,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const List<SidebarItem> _allItems = [
    SidebarItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      permission: AppPermission.viewDashboard,
    ),
    SidebarItem(
      icon: Icons.account_balance_outlined,
      selectedIcon: Icons.account_balance,
      label: 'Accounting',
      permission: AppPermission.viewAccounting,
    ),
    SidebarItem(
      icon: Icons.people_outlined,
      selectedIcon: Icons.people,
      label: 'Customers',
      permission: AppPermission.viewCustomers,
    ),
    SidebarItem(
      icon: Icons.local_shipping_outlined,
      selectedIcon: Icons.local_shipping,
      label: 'Suppliers',
      permission: AppPermission.viewSuppliers,
    ),
    SidebarItem(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
      label: 'Invoices',
      permission: AppPermission.viewInvoices,
    ),
    SidebarItem(
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments,
      label: 'Expenses',
      permission: AppPermission.manageInvoices, // Using manageInvoices for expenses for now
    ),
    SidebarItem(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: 'Reports',
      permission: AppPermission.viewReports,
    ),
    SidebarItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
      permission: AppPermission.manageSettings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExtended = MediaQuery.of(context).size.width > 1200;

    final visibleItems = _allItems.where((item) => role.hasPermission(item.permission)).toList();

    return NavigationRail(
      extended: isExtended,
      minExtendedWidth: 240,
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFF0F172A)
          : const Color(0xFF020617),
      selectedIndex: selectedIndex >= visibleItems.length ? 0 : selectedIndex,
      onDestinationSelected: (index) {
        // Map the visible index back to something meaningful or just use it as is
        onDestinationSelected(index);
      },
      indicatorColor: theme.colorScheme.secondary.withValues(alpha: 0.2),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 32,
              color: theme.colorScheme.secondary,
            ),
            if (isExtended) ...[
              const SizedBox(width: 12),
              const Text(
                'LedGix ERP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
      destinations: visibleItems.map((item) {
        return NavigationRailDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon),
          label: Text(item.label),
        );
      }).toList(),
    );
  }
}
