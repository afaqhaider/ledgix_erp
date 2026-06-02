import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/widgets/sidebar_navigation.dart';
import 'package:ledgixerp/features/auth/services/auth_service.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/chart_of_accounts_screen.dart';
import 'package:ledgixerp/features/accounting/journal/presentation/screens/journal_entries_screen.dart';
import 'package:ledgixerp/features/crm/customers/presentation/screens/customers_screen.dart';
import 'package:ledgixerp/features/suppliers/presentation/screens/suppliers_screen.dart';
import 'package:ledgixerp/features/purchase_orders/presentation/screens/purchase_orders_screen.dart';
import 'package:ledgixerp/features/quotations/presentation/screens/quotations_screen.dart';
import 'package:ledgixerp/features/invoices/presentation/screens/invoices_screen.dart';
import 'package:ledgixerp/features/approvals/presentation/screens/approvals_screen.dart';
import 'package:ledgixerp/features/banking/presentation/screens/bank_accounts_screen.dart';
import 'package:ledgixerp/features/crm/customer_payments/presentation/screens/customer_payments_screen.dart';
import 'package:ledgixerp/features/supplier_payments/presentation/screens/supplier_payments_screen.dart';
import 'package:ledgixerp/features/dashboard/services/dashboard_service.dart';
import 'package:ledgixerp/features/dashboard/presentation/widgets/kpi_card.dart';
import 'package:ledgixerp/features/dashboard/presentation/widgets/recent_activity_card.dart';
import 'package:ledgixerp/features/dashboard/presentation/widgets/dashboard_chart.dart';
import 'package:ledgixerp/features/reports/presentation/screens/reports_screen.dart';
import 'package:ledgixerp/features/reports/presentation/screens/trial_balance_screen.dart';
import 'package:ledgixerp/features/reports/presentation/screens/profit_loss_screen.dart';
import 'package:ledgixerp/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:ledgixerp/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:ledgixerp/features/notifications/services/notification_service.dart';
import 'package:ledgixerp/features/audit/presentation/screens/audit_logs_screen.dart';
import 'package:ledgixerp/core/audit/audit_service.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedPageLabel = 'Dashboard';
  final _dashboardService = DashboardService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedPageLabel),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(widget.user.uid),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Badge(
                label: Text(count.toString()),
                isLabelVisible: count > 0,
                child: IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NotificationCenterScreen(user: widget.user)),
                  ),
                ),
              );
            }
          ),
          const VerticalDivider(width: 1, indent: 12, endIndent: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  await AuditService().log(
                    companyId: widget.user.companyId!,
                    userId: widget.user.uid,
                    userName: widget.user.fullName,
                    actionType: 'logout',
                    module: 'auth',
                    documentId: widget.user.uid,
                    description: 'User logged out',
                  );
                  AuthService().signOut();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Text('Profile Settings'),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ],
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFE2E8F0),
                    child: Icon(Icons.person, size: 20, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.user.role.name.toUpperCase(),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
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
                selectedItem: _selectedPageLabel,
                onItemSelected: (label) {
                  setState(() => _selectedPageLabel = label);
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
              selectedItem: _selectedPageLabel,
              onItemSelected: (label) {
                setState(() => _selectedPageLabel = label);
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
    switch (_selectedPageLabel) {
      case 'Dashboard':
        return _buildDashboardOverview();
      case 'Approvals':
        return ApprovalsScreen(user: widget.user);
      case 'Journal Entries':
        return JournalEntriesScreen(user: widget.user);
      case 'Bank Accounts':
        return BankAccountsScreen(user: widget.user);
      case 'Chart of Accounts':
        return ChartOfAccountsScreen(user: widget.user);
      case 'Inventory':
        return InventoryScreen(user: widget.user);
      case 'Customers':
        return CustomersScreen(user: widget.user);
      case 'Suppliers':
        return SuppliersScreen(user: widget.user);
      case 'Purchase Orders':
        return PurchaseOrdersScreen(user: widget.user);
      case 'Supplier Payments':
        return SupplierPaymentsScreen(user: widget.user);
      case 'Quotations':
        return QuotationsScreen(user: widget.user);
      case 'Sales Invoices':
        return InvoicesScreen(user: widget.user);
      case 'Customer Payments':
        return CustomerPaymentsScreen(user: widget.user);
      case 'Reports':
        return ReportsScreen(user: widget.user);
      case 'Trial Balance':
        return TrialBalanceScreen(user: widget.user);
      case 'Profit & Loss':
        return ProfitLossScreen(user: widget.user);
      case 'Audit Logs':
        return AuditLogsScreen(user: widget.user);
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                '$_selectedPageLabel Module Coming Soon',
                style: const TextStyle(color: Colors.grey, fontSize: 18),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildDashboardOverview() {
    final theme = Theme.of(context);
    final companyId = widget.user.companyId!;

    return StreamBuilder<DashboardStats>(
      stream: _dashboardService.getDashboardStats(companyId),
      builder: (context, statsSnapshot) {
        if (statsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = statsSnapshot.data ?? DashboardStats();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Welcome back, ${widget.user.fullName}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Export Summary'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // KPI Section
              LayoutBuilder(builder: (context, constraints) {
                int count = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: count,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.8,
                  children: [
                    KPICard(
                      title: 'Total Revenue',
                      value: NumberFormat.currency(symbol: '\$').format(stats.totalRevenue),
                      icon: Icons.attach_money_rounded,
                      color: Colors.blue,
                      trend: 'Live',
                      isTrendUp: true,
                    ),
                    KPICard(
                      title: 'Total Expenses',
                      value: NumberFormat.currency(symbol: '\$').format(stats.totalExpenses),
                      icon: Icons.shopping_bag_rounded,
                      color: Colors.orange,
                    ),
                    KPICard(
                      title: 'Net Profit',
                      value: NumberFormat.currency(symbol: '\$').format(stats.totalProfit),
                      icon: Icons.trending_up_rounded,
                      color: Colors.green,
                      isTrendUp: stats.totalProfit > 0,
                    ),
                    KPICard(
                      title: 'Pending Invoices',
                      value: stats.pendingInvoicesCount.toString(),
                      icon: Icons.receipt_long_rounded,
                      color: Colors.purple,
                      trend: '${stats.overdueInvoicesCount} Overdue',
                      isTrendUp: false,
                    ),
                  ],
                );
              }),

              const SizedBox(height: 32),

              // Charts and Activity
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        DashboardChart(
                          title: 'Operational Trends',
                          data: [stats.totalRevenue, stats.totalExpenses, stats.totalProfit],
                          labels: ['Revenue', 'Expenses', 'Profit'],
                        ),
                        const SizedBox(height: 24),
                        _buildRecentActivityGrid(companyId),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  if (MediaQuery.of(context).size.width > 1200)
                    Expanded(
                      flex: 1,
                      child: _buildOperationalSidebar(stats),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOperationalSidebar(DashboardStats stats) {
    return Column(
      children: [
        _buildQuickActionCard(
          'Pending Approvals',
          '${stats.pendingApprovalsCount} tasks waiting',
          Icons.fact_check_rounded,
          Colors.amber,
          () => setState(() => _selectedPageLabel = 'Approvals'),
        ),
        const SizedBox(height: 16),
        _buildQuickActionCard(
          'Overdue Invoices',
          '${stats.overdueInvoicesCount} invoices',
          Icons.warning_rounded,
          Colors.red,
          () => setState(() => _selectedPageLabel = 'Sales Invoices'),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecentActivityGrid(String companyId) {
    return LayoutBuilder(builder: (context, constraints) {
      int count = constraints.maxWidth > 800 ? 2 : 1;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: count,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.2,
        children: [
          StreamBuilder(
            stream: _dashboardService.getRecentCustomerPayments(companyId),
            builder: (context, snapshot) {
              final items = (snapshot.data ?? []).map((p) => RecentActivityItem(
                title: p.customerName,
                subtitle: p.paymentNumber,
                trailing: NumberFormat.simpleCurrency().format(p.amount),
                icon: Icons.payment_rounded,
                iconColor: Colors.green,
                date: p.paymentDate,
              )).toList();
              return RecentActivityCard(title: 'Recent Customer Payments', items: items);
            },
          ),
          StreamBuilder(
            stream: _dashboardService.getLatestQuotations(companyId),
            builder: (context, snapshot) {
              final items = (snapshot.data ?? []).map((q) => RecentActivityItem(
                title: q.customerName,
                subtitle: q.quotationNumber,
                trailing: NumberFormat.simpleCurrency().format(q.totalAmount),
                icon: Icons.description_rounded,
                iconColor: Colors.blue,
                date: q.createdAt,
              )).toList();
              return RecentActivityCard(title: 'Latest Quotations', items: items);
            },
          ),
        ],
      );
    });
  }
}
