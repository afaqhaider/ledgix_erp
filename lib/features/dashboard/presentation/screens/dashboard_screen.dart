import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ledgixerp/config/app_modules.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/widgets/sidebar_navigation.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/dashboard/services/dashboard_service.dart';
import 'package:ledgixerp/features/dashboard/presentation/widgets/kpi_card.dart';
import 'package:ledgixerp/features/dashboard/presentation/widgets/recent_activity_card.dart';
import 'package:ledgixerp/features/dashboard/presentation/widgets/dashboard_chart.dart';
import 'package:ledgixerp/features/invoices/presentation/screens/add_invoice_screen.dart';
import 'package:ledgixerp/features/suppliers/presentation/screens/add_bill_screen.dart';
import 'package:ledgixerp/features/crm/customer_payments/presentation/screens/add_customer_payment_screen.dart';
import 'package:ledgixerp/features/supplier_payments/presentation/screens/add_supplier_payment_screen.dart';
import 'package:ledgixerp/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:ledgixerp/features/notifications/services/notification_service.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/features/search/services/search_service.dart';
import 'package:ledgixerp/features/weather/presentation/widgets/weather_display.dart';
import 'package:ledgixerp/features/users/presentation/widgets/profile_menu_button.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();
  AppModule _selectedModule = AppModules.dashboard;
  final _dashboardService = DashboardService();
  final _companyService = CompanyService();
  final _searchService = SearchService();
  bool _isQuickActionsCollapsed = false;
  int _quickActionTabIndex = 0; // 0 for Add, 1 for View

  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlayEntry;
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _removeSearchOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _removeSearchOverlay() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  void _showSearchOverlay() {
    _removeSearchOverlay();
    _searchOverlayEntry = _createSearchOverlayEntry();
    Overlay.of(context).insert(_searchOverlayEntry!);
  }

  OverlayEntry _createSearchOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 480,
        child: CompositedTransformFollower(
          link: _searchLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(-80, 48), // Adjusted for center search bar
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : _searchResults.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No results found'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              leading: Icon(_getSearchIcon(result.type), size: 20),
                              title: Text(result.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(result.subtitle, style: const TextStyle(fontSize: 11)),
                              trailing: Text(DateFormat('MMM dd').format(result.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              onTap: () {
                                _handleSearchResultTap(result);
                                _removeSearchOverlay();
                                _searchController.clear();
                              },
                            );
                          },
                        ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSearchIcon(String type) {
    switch (type) {
      case 'customer': return Icons.person_outline;
      case 'supplier': return Icons.local_shipping_outlined;
      case 'invoice': return Icons.receipt_long_outlined;
      case 'bill': return Icons.assignment_outlined;
      case 'journal': return Icons.history_edu_outlined;
      case 'payment': return Icons.payments_outlined;
      default: return Icons.search;
    }
  }

  void _handleSearchResultTap(SearchResult result) {
    AppModuleId? targetId;
    switch (result.type) {
      case 'customer': targetId = AppModuleId.customers; break;
      case 'invoice': targetId = AppModuleId.salesInvoices; break;
      case 'bill': targetId = AppModuleId.bills; break;
      case 'journal': targetId = AppModuleId.journalEntries; break;
      case 'payment': targetId = result.data.containsKey('customerName') ? AppModuleId.receipts : AppModuleId.supplierPayments; break;
    }
    
    if (targetId != null) {
      setState(() => _selectedModule = AppModules.moduleById(targetId!));
    }
  }

  void _onSearchChanged(String query) async {
    if (query.length < 2) {
      _removeSearchOverlay();
      return;
    }

    _showSearchOverlay();
    setState(() => _isSearching = true);
    
    final results = await _searchService.globalSearch(widget.user.companyId!, query);
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
      _showSearchOverlay(); 
    }
  }

  static const _revenueAccent = Color(0xFF5B8DEF);
  static const _expenseAccent = Color(0xFFD18B45);
  static const _profitAccent = Color(0xFF6E9F7F);
  static const _cashAccent = Color(0xFFE29A43);
  static const _dangerAccent = Color(0xFFB46A5A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: isMobile
          ? Drawer(
              backgroundColor: theme.scaffoldBackgroundColor,
              child: SidebarNavigation(
                role: widget.user.role,
                companyId: widget.user.companyId,
                selectedModuleId: _selectedModule.id,
                onModuleSelected: (module) {
                  setState(() => _selectedModule = module);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            SidebarNavigation(
              role: widget.user.role,
              companyId: widget.user.companyId,
              selectedModuleId: _selectedModule.id,
              onModuleSelected: (module) {
                setState(() => _selectedModule = module);
              },
            ),
          Expanded(
            child: ClipRect(
              child: Navigator(
                key: _shellNavigatorKey,
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (context) => Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Column(
                      children: [
                        _buildTopBar(context, isMobile),
                        Expanded(
                          child: Container(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: _buildBody(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    final canGoBack = _selectedModule.id != AppModuleId.dashboard;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          if (canGoBack)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to Dashboard',
              onPressed: () => setState(() => _selectedModule = AppModules.dashboard),
            )
          else if (isMobile)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          const SizedBox(width: 8),
          const Spacer(),
          Expanded(
            flex: 4,
            child: CompositedTransformTarget(
              link: _searchLayerLink,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8)),
                ),
                child: TextField(
                  controller: _searchController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Global Search',
                    hintStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),
          ),
          const Spacer(),
          if (!isMobile) ...[
            WeatherDisplay(companyId: widget.user.companyId!, isCompact: true),
            const SizedBox(width: 24),
            const _ClockWidget(),
            const SizedBox(width: 16),
          ],
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(widget.user.companyId!, widget.user.uid),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Badge(
                label: Text(
                  count.toString(),
                  style: const TextStyle(fontSize: 9),
                ),
                isLabelVisible: count > 0,
                child: IconButton(
                  icon: const Icon(Icons.notifications_none, size: 22),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          NotificationCenterScreen(user: widget.user),
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ProfileMenuButton(uid: widget.user.uid),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedModule.id == AppModuleId.dashboard) {
      return _buildDashboardOverview();
    }
    return _selectedModule.buildPage(widget.user);
  }

  void _selectModule(AppModuleId moduleId) {
    setState(() => _selectedModule = AppModules.moduleById(moduleId));
  }

  Widget _buildDashboardOverview() {
    final companyId = widget.user.companyId!;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth < 600 ? 12.0 : 24.0;

    return StreamBuilder<CompanyModel?>(
      stream: _companyService.getCompany(companyId),
      builder: (context, companySnapshot) {
        final currency = companySnapshot.data?.baseCurrency ?? 'AED';

        return StreamBuilder<DashboardStats>(
          stream: _dashboardService.getDashboardStats(companyId),
          initialData: DashboardStats(),
          builder: (context, statsSnapshot) {
            final stats = statsSnapshot.data ?? DashboardStats();
            final hasStatsError = statsSnapshot.hasError;

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showQuickActionsRail = constraints.maxWidth >= 760;
                  final mainContent = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasStatsError) ...[
                        _buildDashboardDataNotice(statsSnapshot.error),
                        const SizedBox(height: 16),
                      ],
                      _buildKPIGrid(stats, currency),
                      const SizedBox(height: 16),
                      _buildChartsRow(stats),
                      const SizedBox(height: 16),
                      _buildActivityGrid(companyId, currency, stats),
                    ],
                  );

                  if (!showQuickActionsRail) return mainContent;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: mainContent),
                      const SizedBox(width: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        width: _isQuickActionsCollapsed ? 48 : 280,
                        child: _buildQuickActionsRail(),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDashboardDataNotice(Object? error) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: error != null
          ? () => showErpError(
                context: context,
                title: 'Dashboard Sync Error',
                message:
                    'We encountered an issue while fetching some dashboard figures. This usually happens due to missing database indexes or connection issues.',
                error: error,
              )
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.08),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.18),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Some dashboard figures could not be refreshed. Tap for details.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIGrid(DashboardStats stats, String currency) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1100
            ? 4
            : (constraints.maxWidth > 600 ? 2 : 1);
        const spacing = 12.0;
        final cardHeight = columns == 1 ? 104.0 : 112.0;
        final cards = <Widget>[
          KPICard(
            title: 'Total Revenue',
            value: AppFormatters.currency(stats.totalRevenue, symbol: currency),
            icon: Icons.payments_rounded,
            color: _revenueAccent,
            trend: stats.revenueTrend,
            isTrendUp: stats.isRevenueUp,
            onTap: () => _selectModule(AppModuleId.salesInvoices),
          ),
          KPICard(
            title: 'Total Expenses',
            value: AppFormatters.currency(
              stats.totalExpenses,
              symbol: currency,
            ),
            icon: Icons.receipt_long_rounded,
            color: _expenseAccent,
            trend: stats.expenseTrend,
            isTrendUp: !stats.isExpenseUp, // Good if expenses decreased
            onTap: () => _selectModule(AppModuleId.bills),
          ),
          KPICard(
            title: 'Net Profit',
            value: AppFormatters.currency(stats.totalProfit, symbol: currency),
            icon: Icons.show_chart_rounded,
            color: _profitAccent,
            trend: stats.profitTrend,
            isTrendUp: stats.isProfitUp,
            onTap: () => _selectModule(AppModuleId.profitLoss),
          ),
          KPICard(
            title: 'Cash Balance',
            value: AppFormatters.currency(stats.cashBalance, symbol: currency),
            icon: Icons.account_balance_wallet_rounded,
            color: _cashAccent,
            trend: null,
            isTrendUp: true,
            onTap: () => _selectModule(AppModuleId.bankAccounts),
          ),
        ];

        Widget buildRow(List<Widget> rowCards) {
          return SizedBox(
            height: cardHeight,
            child: Row(
              children: [
                for (var index = 0; index < rowCards.length; index++) ...[
                  if (index > 0) const SizedBox(width: spacing),
                  Expanded(child: rowCards[index]),
                ],
              ],
            ),
          );
        }

        if (columns == 1) {
          return Column(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                if (index > 0) const SizedBox(height: spacing),
                SizedBox(
                  height: cardHeight,
                  width: double.infinity,
                  child: cards[index],
                ),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var start = 0; start < cards.length; start += columns) {
          final end = (start + columns).clamp(0, cards.length);
          rows.add(buildRow(cards.sublist(start, end)));
        }

        return Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) const SizedBox(height: spacing),
              rows[index],
            ],
          ],
        );
      },
    );
  }

  Widget _buildChartsRow(DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 900;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: DashboardChart(
                title: 'Revenue vs Expenses',
                isLineChart: true,
                data: stats.revenueChartData,
                secondaryData: stats.expenseChartData,
                labels: stats.chartLabels,
              ),
            ),
            if (isWide) ...[
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: DashboardChart(
                  title: 'Cash Flow',
                  isLineChart: false,
                  data: stats.cashFlowData,
                  labels: stats.cashFlowLabels,
                  emptyMessage: 'No cash flow data available yet',
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActivityGrid(
    String companyId,
    String currency,
    DashboardStats stats,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count = constraints.maxWidth > 800 ? 2 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.95,
          children: [
            StreamBuilder(
              stream: _dashboardService.getRecentCustomerPayments(companyId),
              builder: (context, snapshot) {
                final items = (snapshot.data ?? [])
                    .map(
                      (p) => RecentActivityItem(
                        title: p.customerName,
                        subtitle: p.paymentNumber,
                        trailing: AppFormatters.currency(
                          p.amount,
                          symbol: currency,
                        ),
                        icon: Icons.payment_rounded,
                        iconColor: _profitAccent,
                        date: p.paymentDate,
                      ),
                    )
                    .toList();
                return RecentActivityCard(
                  title: 'Recent Receipts',
                  items: items,
                  onViewAll: () => _selectModule(AppModuleId.receipts),
                );
              },
            ),
            StreamBuilder(
              stream: _dashboardService.getLatestQuotations(companyId),
              builder: (context, snapshot) {
                final items = (snapshot.data ?? [])
                    .map(
                      (q) => RecentActivityItem(
                        title: q.customerName,
                        subtitle: q.quotationNumber,
                        trailing: AppFormatters.currency(
                          q.totalAmount,
                          symbol: currency,
                        ),
                        icon: Icons.description_rounded,
                        iconColor: _revenueAccent,
                        date: q.createdAt,
                      ),
                    )
                    .toList();
                return RecentActivityCard(
                  title: 'Latest Quotations',
                  items: items,
                  onViewAll: () => _selectModule(AppModuleId.quotations),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionsRail() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surfaceContainer;
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    final dividerColor = theme.dividerColor;

    if (_isQuickActionsCollapsed) {
      return InkWell(
        onTap: () => setState(() => _isQuickActionsCollapsed = false),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 236,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.18)
                    : const Color(0xFF94A3B8).withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.keyboard_arrow_left_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Center(
                    child: Text(
                      'Quick Actions',
                      maxLines: 1,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0xFF94A3B8).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Collapse quick actions',
                onPressed: () =>
                    setState(() => _isQuickActionsCollapsed = true),
                icon: const Icon(Icons.keyboard_arrow_right_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tab Header
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _quickActionTabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _quickActionTabIndex == 0
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Add',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _quickActionTabIndex == 0
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _quickActionTabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _quickActionTabIndex == 1
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'View',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _quickActionTabIndex == 1
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_quickActionTabIndex == 0) ...[
            _buildActionItem(
              'Invoice',
              'Sales invoice',
              Icons.receipt_long_rounded,
              _revenueAccent,
              () => _openAddInvoice(context),
            ),
            Divider(height: 20, color: dividerColor),
            _buildActionItem(
              'Bill',
              'Vendor bill',
              Icons.assignment_rounded,
              _expenseAccent,
              () => _openAddBill(context),
            ),
            Divider(height: 20, color: dividerColor),
            _buildActionItem(
              'Receipt',
              'Customer receipt',
              Icons.payments_rounded,
              _profitAccent,
              () => _openAddReceipt(context),
            ),
            Divider(height: 20, color: dividerColor),
            _buildActionItem(
              'Payment',
              'Supplier payment',
              Icons.account_balance_wallet_rounded,
              _cashAccent,
              () => _openAddPayment(context),
            ),
            Divider(height: 20, color: dividerColor),
            _buildActionItem(
              'Expense',
              'Expense bill',
              Icons.trending_down_rounded,
              _dangerAccent,
              () => _openAddExpense(context),
            ),
          ] else ...[
            _buildActionItem(
              'Invoices',
              'Sales invoices list',
              Icons.receipt_long_outlined,
              _revenueAccent,
              () => _selectModule(AppModuleId.salesInvoices),
            ),
            Divider(height: 20, color: dividerColor),
            _buildActionItem(
              'Receipts',
              'Customer receipts list',
              Icons.payments_outlined,
              _profitAccent,
              () => _selectModule(AppModuleId.receipts),
            ),
            Divider(height: 20, color: dividerColor),
            _buildActionItem(
              'Bills',
              'Vendor bills list',
              Icons.assignment_outlined,
              _expenseAccent,
              () => _selectModule(AppModuleId.bills),
            ),
            Divider(height: 20, color: dividerColor),
            _buildActionItem(
              'Payments',
              'Supplier payments list',
              Icons.paid_outlined,
              _cashAccent,
              () => _selectModule(AppModuleId.supplierPayments),
            ),
            Divider(height: 20, color: dividerColor),
            _buildActionItem(
              'Expenses',
              'Direct expense bills',
              Icons.trending_down_rounded,
              _dangerAccent,
              () => _selectModule(AppModuleId.bills),
            ),
            Divider(height: 20, color: dividerColor),
            _buildActionItem(
              'Customers',
              'Customer directory',
              Icons.people_outline_rounded,
              _profitAccent,
              () => _selectModule(AppModuleId.customers),
            ),
            Divider(height: 20, color: dividerColor),
            _buildActionItem(
              'Vendors',
              'Supplier directory',
              Icons.local_shipping_outlined,
              _expenseAccent,
              () => _selectModule(AppModuleId.suppliers),
            ),
          ],
        ],
      ),
    );
  }

  void _openAddInvoice(BuildContext context) {
    showErpSidePane(
      context: context,
      builder: AddInvoiceScreen(user: widget.user, isPane: true),
    );
  }

  void _openAddBill(BuildContext context) {
    showErpSidePane(
      context: context,
      builder: AddBillScreen(user: widget.user, isPane: true),
    );
  }

  void _openAddReceipt(BuildContext context) {
    showErpSidePane(
      context: context,
      builder: AddCustomerPaymentScreen(user: widget.user, isPane: true),
    );
  }

  void _openAddPayment(BuildContext context) {
    showErpSidePane(
      context: context,
      builder: AddSupplierPaymentScreen(user: widget.user, isPane: true),
    );
  }

  void _openAddExpense(BuildContext context) {
    showErpSidePane(
      context: context,
      builder: AddBillScreen(user: widget.user, isPane: true),
    );
  }

  Widget _buildActionItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}

class _ClockWidget extends StatefulWidget {
  const _ClockWidget();

  @override
  State<_ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<_ClockWidget> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          DateFormat('HH:mm:ss').format(_now),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        Text(
          DateFormat('EEE, MMM d').format(_now),
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

