import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import 'package:ledgixerp/core/auth/permission.dart';

class NavigationItem {
  final IconData icon;
  final String label;
  final AppPermission permission;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.permission,
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
          label: 'Customer Payments',
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
          icon: Icons.paid_rounded,
          label: 'Supplier Payments',
          permission: AppPermission.viewSuppliers,
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
          icon: Icons.manage_accounts_rounded,
          label: 'User Settings',
          permission: AppPermission.manageSettings,
        ),
        NavigationItem(
          icon: Icons.history_rounded,
          label: 'Audit Logs',
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
  String? _expandedSection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final sidebarColor = isDark ? const Color(0xFF020617) : const Color(0xFF0F172A);
    final activeColor = theme.colorScheme.primary;
    
    final bool isExpanded = _isHovered || _isPinned;
    final double width = isExpanded ? 260 : 76;

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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.secondary, size: 28),
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
                        _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
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
                      .where((item) => widget.role.hasPermission(item.permission))
                      .toList();

                  if (visibleItems.isEmpty) return const SizedBox.shrink();

                  final bool isSectionExpanded = _expandedSection == section.header;

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
                              _expandedSection = isSectionExpanded ? null : section.header;
                            });
                          }
                        },
                      ),
                      if (isExpanded && isSectionExpanded)
                        ...visibleItems.map((item) {
                          final bool isSelected = widget.selectedItem == item.label;
                          return Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: _SidebarTile(
                              item: item,
                              isSelected: isSelected,
                              isExpanded: isExpanded,
                              activeColor: activeColor,
                              onTap: () => widget.onItemSelected(item.label),
                            ),
                          );
                        }),
                    ],
                  );
                }).toList(),
              ),
            ),
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
    final theme = Theme.of(context);

    Widget content = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: _isHovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: widget.isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            SizedBox(
              width: widget.isExpanded ? 46 : 52,
              child: Icon(
                widget.icon,
                color: _isHovered || widget.isSectionExpanded ? Colors.white : Colors.white70,
                size: 24,
              ),
            ),
            if (widget.isExpanded)
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: _isHovered || widget.isSectionExpanded ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: widget.isSectionExpanded ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (widget.isExpanded)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  widget.isSectionExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
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

  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.activeColor,
    required this.onTap,
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: widget.isSelected 
              ? widget.activeColor.withValues(alpha: 0.15) 
              : (_isTileHovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: widget.isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            SizedBox(
              width: widget.isExpanded ? 46 : 52,
              child: Icon(
                widget.item.icon,
                color: widget.isSelected ? widget.activeColor : (showHighlight ? Colors.white : Colors.white70),
                size: 24,
              ),
            ),
            if (widget.isExpanded)
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    color: widget.isSelected ? Colors.white : (showHighlight ? Colors.white : Colors.white70),
                    fontSize: 14,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
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
