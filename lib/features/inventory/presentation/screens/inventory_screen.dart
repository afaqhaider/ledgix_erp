import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/theme/app_colors.dart';
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

class InventoryScreen extends StatefulWidget {
  final AppUser user;
  const InventoryScreen({super.key, required this.user});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
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
      ),
      body: TabBarView(
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
    );
  }
}
