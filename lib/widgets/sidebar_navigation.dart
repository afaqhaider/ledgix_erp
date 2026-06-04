import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/features/auth/services/auth_service.dart';

class NavigationItem {
  final IconData icon;
  final String label;
  final AppPermission permission;
  final List<NavigationItem>? subItems;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.permission,
    this.subItems,
  });
}

class NavigationSection {
  final String header;
  final IconData icon;
  final List<NavigationItem> items;
  final bool isCollapsible;

  const NavigationSection({
    required this.header,
    required this.icon,
    required this.items,
    this.isCollapsible = true,
  });
}

class SidebarNavigation extends StatefulWidget {
  final UserRole role;
  final String selectedItem;
  final Function(String) onItemSelected;

  const SidebarNavigation({
    super.key,
    required this.role,
    required this.selectedItem,
    required this.onItemSelected,
  });

  static const List<NavigationSection> sections = [
    NavigationSection(
      header: 'Dashboard',
      icon: Icons.dashboard_rounded,
      isCollapsible: false,
      items: [
        NavigationItem(
          icon: Icons.dashboard_rounded,
          label: 'Dashboard',
          permission: AppPermission.viewDashboard,
        ),
      ],
    ),
    NavigationSection(
      header: 'Approvals',
      icon: Icons.fact_check_rounded,
      isCollapsible: false,
      items: [
        NavigationItem(
          icon: Icons.fact_check_rounded,
          label: 'Approvals',
          permission: AppPermission.viewDashboard,
        ),
      ],
    ),
    NavigationSection(
      header: 'Customers',
      icon: Icons.people_alt_rounded,
      items: [
        NavigationItem(
          icon: Icons.people_alt_rounded,
          label: 'Customers',
          permission: AppPermission.viewCustomers,
        ),
        NavigationItem(
          icon: Icons.description_rounded,
          label: 'Quotations',
          permission: AppPermission.viewInvoices,
        ),
        NavigationItem(
          icon: Icons.receipt_long_rounded,
          label: 'Sales Invoices',
          permission: AppPermission.viewInvoices,
        ),
        NavigationItem(
          icon: Icons.payments_rounded,
          label: 'Receipts',
          permission: AppPermission.viewInvoices,
        ),
      ],
    ),
    NavigationSection(
      header: 'Vendors',
      icon: Icons.local_shipping_rounded,
      items: [
        NavigationItem(
          icon: Icons.local_shipping_rounded,
          label: 'Suppliers',
          permission: AppPermission.viewSuppliers,
        ),
        NavigationItem(
          icon: Icons.shopping_cart_rounded,
          label: 'Purchase Orders',
          permission: AppPermission.viewSuppliers,
        ),
        NavigationItem(
          icon: Icons.receipt_long_rounded,
          label: 'Purchase Invoices (Bills)',
          permission: AppPermission.viewBills,
        ),
        NavigationItem(
          icon: Icons.paid_rounded,
          label: 'Supplier Payments',
          permission: AppPermission.viewSuppliers,
        ),
      ],
    ),
    NavigationSection(
      header: 'Operations',
      icon: Icons.precision_manufacturing_rounded,
      items: [
        NavigationItem(
          icon: Icons.work_rounded,
          label: 'Jobs',
          permission: AppPermission.viewDashboard,
        ),
        NavigationItem(
          icon: Icons.task_alt_rounded,
          label: 'Tasks',
          permission: AppPermission.viewDashboard,
        ),
        NavigationItem(
          icon: Icons.more_time_rounded,
          label: 'Shifts',
          permission: AppPermission.viewDashboard,
        ),
      ],
    ),
    NavigationSection(
      header: 'Accounting',
      icon: Icons.account_tree_rounded,
      items: [
        NavigationItem(
          icon: Icons.inventory_2_rounded,
          label: 'Inventory',
          permission: AppPermission.viewAccounting,
        ),
        NavigationItem(
          icon: Icons.account_tree_rounded,
          label: 'Chart of Accounts',
          permission: AppPermission.viewAccounting,
        ),
        NavigationItem(
          icon: Icons.history_edu_rounded,
          label: 'Journal Entries',
          permission: AppPermission.viewAccounting,
        ),
        NavigationItem(
          icon: Icons.settings_applications_rounded,
          label: 'Accounting Settings',
          permission: AppPermission.manageAccounting,
        ),
      ],
    ),
    NavigationSection(
      header: 'Banking',
      icon: Icons.account_balance_rounded,
      items: [
        NavigationItem(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Bank Accounts',
          permission: AppPermission.viewAccounting,
        ),
        NavigationItem(
          icon: Icons.payments_rounded,
          label: 'Cash',
          permission: AppPermission.viewAccounting,
        ),
      ],
    ),
    NavigationSection(
      header: 'Reports',
      icon: Icons.analytics_rounded,
      items: [
        NavigationItem(
          icon: Icons.analytics_rounded,
          label: 'Reports',
          permission: AppPermission.viewReports,
        ),
        NavigationItem(
          icon: Icons.account_balance_rounded,
          label: 'Trial Balance',
          permission: AppPermission.viewReports,
        ),
        NavigationItem(
          icon: Icons.trending_up_rounded,
          label: 'Profit & Loss',
          permission: AppPermission.viewReports,
        ),
      ],
    ),
    NavigationSection(
      header: 'Settings',
      icon: Icons.settings_rounded,
      items: [
        NavigationItem(
          icon: Icons.business_rounded,
          label: 'Company Settings',
          permission: AppPermission.manageSettings,
        ),
        NavigationItem(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Financial Settings',
          permission: AppPermission.manageSettings,
          subItems: [
            NavigationItem(
              icon: Icons.calendar_month_rounded,
              label: 'Financial Period',
              permission: AppPermission.manageSettings,
            ),
            NavigationItem(
              icon: Icons.label_important_rounded,
              label: 'Docs Prefix',
              permission: AppPermission.manageSettings,
            ),
            NavigationItem(
              icon: Icons.credit_card_rounded,
              label: 'Credit Terms (Customers)',
              permission: AppPermission.manageSettings,
            ),
            NavigationItem(
              icon: Icons.payments_rounded,
              label: 'Payment Terms (Quotations)',
              permission: AppPermission.manageSettings,
            ),
          ],
        ),
        NavigationItem(
          icon: Icons.manage_accounts_rounded,
          label: 'User Management',
          permission: AppPermission.manageUsers,
        ),
        NavigationItem(
          icon: Icons.history_rounded,
          label: 'Audit Logs',
          permission: AppPermission.manageSettings,
        ),
        NavigationItem(
          icon: Icons.storage_rounded,
          label: 'Data Management',
          permission: AppPermission.manageSettings,
        ),
      ],
    ),
  ];

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation> {
  bool _isHovered = false;
  bool _isPinned = false;
  String? _expandedSection; // Null means all sections collapsed by default

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sidebarColor = isDark
        ? const Color(0xFF000000)
        : const Color(0xFF0F172A);
    final activeColor = theme.colorScheme.secondary;

    final bool isExpanded = _isHovered || _isPinned;
    final double width = isExpanded ? 260 : 52;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: width,
        color: sidebarColor,
        child: Column(
          children: [
            // Header
            Container(
              height: 64,
              padding: EdgeInsets.symmetric(horizontal: isExpanded ? 20 : 0),
              child: Row(
                mainAxisAlignment: isExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: theme.colorScheme.secondary,
                    size: isExpanded ? 28 : 24,
                  ),
                  if (isExpanded) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'LedGix ERP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isPinned
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _isPinned = !_isPinned),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: SidebarNavigation.sections.map((section) {
                  final visibleItems = section.items
                      .where(
                        (item) => widget.role.hasPermission(item.permission),
                      )
                      .toList();

                  if (visibleItems.isEmpty) return const SizedBox.shrink();

                  final bool isSectionExpanded =
                      _expandedSection == section.header;

                  if (!section.isCollapsible) {
                    return Column(
                      children: visibleItems.map((item) {
                        return _SidebarTile(
                          item: item,
                          isSelected: widget.selectedItem == item.label,
                          isExpanded: isExpanded,
                          activeColor: activeColor,
                          onTap: () => widget.onItemSelected(item.label),
                        );
                      }).toList(),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SidebarHeaderTile(
                        title: section.header,
                        icon: section.icon,
                        isExpanded: isExpanded,
                        isSectionExpanded: isSectionExpanded,
                        onTap: () {
                          if (isExpanded) {
                            setState(() {
                              _expandedSection = isSectionExpanded
                                  ? null
                                  : section.header;
                            });
                          }
                        },
                      ),
                      if (isExpanded && isSectionExpanded)
                        ...visibleItems.expand((item) {
                          final List<Widget> subWidgets = [];
                          final bool isSelected = widget.selectedItem == item.label;
                          
                          subWidgets.add(
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: _SidebarTile(
                                item: item,
                                isSelected: isSelected,
                                isExpanded: isExpanded,
                                activeColor: activeColor,
                                onTap: () => widget.onItemSelected(item.label),
                              ),
                            ),
                          );

                          if (item.subItems != null) {
                            // If parent is selected, or any child is selected, we might want to show children
                            // For simplicity, always show children if parent section is expanded
                            subWidgets.addAll(
                              item.subItems!.where((si) => widget.role.hasPermission(si.permission)).map((subItem) {
                                final bool isSubSelected = widget.selectedItem == subItem.label;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 32),
                                  child: _SidebarTile(
                                    item: subItem,
                                    isSelected: isSubSelected,
                                    isExpanded: isExpanded,
                                    activeColor: activeColor,
                                    onTap: () => widget.onItemSelected(subItem.label),
                                    isSubItem: true,
                                  ),
                                );
                              }),
                            );
                          }
                          return subWidgets;
                        }),
                    ],
                  );
                }).toList(),
              ),
            ),
            const Divider(color: Colors.white10, height: 1),

            // Logout Button
            _LogoutTile(isExpanded: isExpanded),
          ],
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final bool isExpanded;
  const _LogoutTile({required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          AuthService().signOut();
        }
      },
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: isExpanded ? 20 : 0),
        child: Row(
          mainAxisAlignment: isExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
            if (isExpanded) ...[
              const SizedBox(width: 12),
              const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarHeaderTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final bool isSectionExpanded;
  final VoidCallback onTap;

  const _SidebarHeaderTile({
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.isSectionExpanded,
    required this.onTap,
  });

  @override
  State<_SidebarHeaderTile> createState() => _SidebarHeaderTileState();
}

class _SidebarHeaderTileState extends State<_SidebarHeaderTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget content = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        margin: EdgeInsets.symmetric(
          horizontal: widget.isExpanded ? 12 : 4,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: widget.isExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            SizedBox(
              width: widget.isExpanded ? 46 : 44,
              child: Icon(
                widget.icon,
                color: _isHovered || widget.isSectionExpanded
                    ? Colors.white
                    : Colors.white70,
                size: 24,
              ),
            ),
            if (widget.isExpanded)
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: _isHovered || widget.isSectionExpanded
                        ? Colors.white
                        : Colors.white70,
                    fontSize: 14,
                    fontWeight: widget.isSectionExpanded
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (widget.isExpanded)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  widget.isSectionExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(10),
      child: widget.isExpanded
          ? content
          : Tooltip(
              message: widget.title,
              preferBelow: false,
              waitDuration: const Duration(milliseconds: 500),
              child: content,
            ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  final NavigationItem item;
  final bool isSelected;
  final bool isExpanded;
  final Color activeColor;
  final VoidCallback onTap;
  final bool isSubItem;

  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.activeColor,
    required this.onTap,
    this.isSubItem = false,
  });

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _isTileHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool showHighlight = widget.isSelected || _isTileHovered;

    Widget content = MouseRegion(
      onEnter: (_) => setState(() => _isTileHovered = true),
      onExit: (_) => setState(() => _isTileHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        margin: EdgeInsets.symmetric(
          horizontal: widget.isExpanded ? 12 : 4,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? widget.activeColor.withValues(alpha: 0.15)
              : (_isTileHovered
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: widget.isExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            SizedBox(
              width: widget.isExpanded ? 46 : 44,
              child: Icon(
                widget.item.icon,
                color: widget.isSelected
                    ? widget.activeColor
                    : (showHighlight ? Colors.white : Colors.white70),
                size: widget.isSubItem ? 18 : 24,
              ),
            ),
            if (widget.isExpanded)
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    color: widget.isSelected
                        ? Colors.white
                        : (showHighlight ? Colors.white : Colors.white70),
                    fontSize: widget.isSubItem ? 13 : 14,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (widget.isExpanded && widget.isSelected)
              Container(
                width: 4,
                height: 24,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: widget.activeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(10),
      hoverColor: Colors.transparent,
      splashColor: widget.activeColor.withValues(alpha: 0.1),
      child: widget.isExpanded
          ? content
          : Tooltip(
              message: widget.item.label,
              preferBelow: false,
              waitDuration: const Duration(milliseconds: 500),
              child: content,
            ),
    );
  }
}
