import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/inventory/presentation/tabs/items_tab.dart';
import 'package:ledgixerp/features/inventory/presentation/tabs/categories_tab.dart';
import 'package:ledgixerp/features/inventory/presentation/tabs/warehouses_tab.dart';
import 'package:ledgixerp/features/inventory/presentation/tabs/uom_tab.dart';
import 'package:ledgixerp/features/inventory/presentation/tabs/grn_tab.dart';
import 'package:ledgixerp/features/inventory/presentation/tabs/dn_tab.dart';
import 'package:ledgixerp/features/inventory/presentation/tabs/transfers_tab.dart';
import 'package:ledgixerp/features/inventory/presentation/tabs/verification_tab.dart';
import 'package:ledgixerp/features/inventory/presentation/tabs/ledger_tab.dart';
import 'package:ledgixerp/features/inventory/presentation/tabs/balance_report_tab.dart';

import 'package:google_fonts/google_fonts.dart';

class InventoryScreen extends StatefulWidget {
  final AppUser user;
  const InventoryScreen({super.key, required this.user});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildHeader(theme),
        _buildTabBar(theme),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              ItemsTab(user: widget.user),
              CategoriesTab(user: widget.user),
              WarehousesTab(user: widget.user),
              UomTab(user: widget.user),
              GrnTab(user: widget.user),
              DnTab(user: widget.user),
              TransfersTab(user: widget.user),
              VerificationTab(user: widget.user),
              LedgerTab(user: widget.user),
              BalanceReportTab(user: widget.user),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Management',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'Track stock, manage warehouses, and handle movements',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Items'),
          Tab(text: 'Categories'),
          Tab(text: 'Warehouses'),
          Tab(text: 'UOM'),
          Tab(text: 'GRN'),
          Tab(text: 'Delivery Notes'),
          Tab(text: 'Transfers'),
          Tab(text: 'Verification'),
          Tab(text: 'Stock Ledger'),
          Tab(text: 'Balance Report'),
        ],
      ),
    );
  }
}
