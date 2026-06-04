import 'package:flutter/material.dart';
import 'package:ledgixerp/config/app_modules.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/widgets/sidebar_navigation.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/dashboard/services/dashboard_service.dart';
import 'package:ledgixerp/features/dashboard/presentation/widgets/kpi_card.dart';
import 'package:ledgixerp/features/dashboard/presentation/widgets/recent_activity_card.dart';
import 'package:ledgixerp/features/dashboard/presentation/widgets/dashboard_chart.dart';
import 'package:ledgixerp/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:ledgixerp/features/notifications/services/notification_service.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ledgixerp/core/theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AppModule _selectedModule = AppModules.dashboard;
  final _dashboardService = DashboardService();
  final _companyService = CompanyService();

  static const _revenueAccent = Color(0xFF5B8DEF);
  static const _expenseAccent = Color(0xFFD18B45);
  static const _profitAccent = Color(0xFF6E9F7F);
  static const _cashAccent = Color(0xFFE29A43);
  static const _warningAccent = Color(0xFFD99A2B);
  static const _dangerAccent = Color(0xFFB46A5A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 18),
            onPressed: () {},
            visualDensity: VisualDensity.compact,
          ),
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(widget.user.uid),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Badge(
                label: Text(
                  count.toString(),
                  style: const TextStyle(fontSize: 9),
                ),
                isLabelVisible: count > 0,
                child: IconButton(
                  icon: const Icon(Icons.notifications_none, size: 18),
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
          const VerticalDivider(width: 1, indent: 12, endIndent: 12),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 40),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Text(
                    'Profile Settings',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout', style: TextStyle(fontSize: 13)),
                ),
              ],
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFE2E8F0),
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 10),
                    Text(
                      widget.user.fullName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: isMobile
          ? Drawer(
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
            child: Container(
              color: theme.colorScheme.surface,
              child: _buildBody(),
            ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(),
                  if (hasStatsError) ...[
                    const SizedBox(height: 10),
                    _buildDashboardDataNotice(),
                  ],
                  const SizedBox(height: 16),
                  _buildKPIGrid(stats, currency),
                  const SizedBox(height: 16),
                  _buildChartsRow(stats),
                  const SizedBox(height: 16),
                  _buildActivityGrid(companyId, currency, stats),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${widget.user.fullName}',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Here\'s what\'s happening with your business today.',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            side: BorderSide(color: Colors.grey[800]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Export Summary', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildDashboardDataNotice() {
    final theme = Theme.of(context);
    return Container(
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
              'Some dashboard figures could not be refreshed yet.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
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
            trend: '+12.5% vs last month',
            isTrendUp: true,
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
            trend: '+8.2% vs last month',
            isTrendUp: false,
            onTap: () => _selectModule(AppModuleId.supplierPayments),
          ),
          KPICard(
            title: 'Net Profit',
            value: AppFormatters.currency(stats.totalProfit, symbol: currency),
            icon: Icons.show_chart_rounded,
            color: _profitAccent,
            trend: '+20.3% vs last month',
            isTrendUp: true,
            onTap: () => _selectModule(AppModuleId.profitLoss),
          ),
          KPICard(
            title: 'Cash Balance',
            value: AppFormatters.currency(stats.totalProfit, symbol: currency),
            icon: Icons.account_balance_wallet_rounded,
            color: _cashAccent,
            trend: '+5.7% vs last month',
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
                data: [
                  45000,
                  52000,
                  48000,
                  61000,
                  55000,
                  52500,
                ], // Mock trend data
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
              ),
            ),
            if (isWide) ...[
              const SizedBox(width: 16),
              const Expanded(
                flex: 1,
                child: DashboardChart(
                  title: 'Cash Flow',
                  isLineChart: false,
                  data: [32000, 28000, 35000, 41000],
                  labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
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
        int count = constraints.maxWidth > 1200
            ? 3
            : (constraints.maxWidth > 800 ? 2 : 1);
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
            _buildQuickActionsCard(stats),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionsCard(DashboardStats stats) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.darkCard.withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.72);
    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.86);
    final dividerColor = isDark ? Colors.white10 : AppColors.lightBorder;

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
          const Text(
            'Operational Overview',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildActionItem(
            'Pending Approvals',
            '${stats.pendingApprovalsCount} tasks waiting',
            Icons.fact_check_rounded,
            _warningAccent,
            () => _selectModule(AppModuleId.approvals),
          ),
          Divider(height: 24, color: dividerColor),
          _buildActionItem(
            'Approved Today',
            '${stats.approvedTodayCount} documents',
            Icons.check_circle_rounded,
            _profitAccent,
            () => _selectModule(AppModuleId.approvals),
          ),
          Divider(height: 24, color: dividerColor),
          _buildActionItem(
            'Rejected Documents',
            '${stats.rejectedDocsCount} items',
            Icons.cancel_rounded,
            _dangerAccent,
            () => _selectModule(AppModuleId.approvals),
          ),
          Divider(height: 24, color: dividerColor),
          _buildActionItem(
            'Overdue Invoices',
            '${stats.overdueInvoicesCount} invoices',
            Icons.warning_rounded,
            _dangerAccent,
            () => _selectModule(AppModuleId.salesInvoices),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                foregroundColor: theme.colorScheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'View All Activities',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
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
