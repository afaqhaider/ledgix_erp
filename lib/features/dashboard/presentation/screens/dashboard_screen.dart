import 'package:flutter/material.dart';
import 'package:ledgixerp/core/theme/app_spacing.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/widgets/sidebar_navigation.dart';
import 'package:ledgixerp/features/auth/services/auth_service.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/chart_of_accounts_screen.dart';
import 'package:ledgixerp/features/accounting/journal/presentation/screens/journal_entries_screen.dart';
import 'package:ledgixerp/features/crm/customers/presentation/screens/customers_screen.dart';
import 'package:ledgixerp/features/suppliers/presentation/screens/suppliers_screen.dart';
import 'package:ledgixerp/features/suppliers/presentation/screens/bills_screen.dart';
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
import 'package:ledgixerp/features/operations/presentation/screens/jobs_screen.dart';
import 'package:ledgixerp/features/operations/presentation/screens/tasks_screen.dart';
import 'package:ledgixerp/features/operations/presentation/screens/shifts_screen.dart';
import 'package:ledgixerp/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:ledgixerp/features/notifications/services/notification_service.dart';
import 'package:ledgixerp/features/audit/presentation/screens/audit_logs_screen.dart';
import 'package:ledgixerp/core/audit/audit_service.dart';
import 'package:ledgixerp/features/company/presentation/screens/company_settings_screen.dart';
import 'package:ledgixerp/features/settings/presentation/screens/financial_settings_screen.dart';
import 'package:ledgixerp/features/settings/presentation/screens/financial_period_screen.dart';
import 'package:ledgixerp/features/settings/presentation/screens/docs_prefix_screen.dart';
import 'package:ledgixerp/features/settings/presentation/screens/credit_terms_screen.dart';
import 'package:ledgixerp/features/settings/presentation/screens/payment_terms_screen.dart';
import 'package:ledgixerp/features/settings/presentation/screens/data_management_screen.dart';
import 'package:ledgixerp/features/users/presentation/screens/users_screen.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedPageLabel = 'Dashboard';
  final _dashboardService = DashboardService();
  final _companyService = CompanyService();

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
                    MaterialPageRoute(
                      builder: (_) =>
                          NotificationCenterScreen(user: widget.user),
                    ),
                  ),
                ),
              );
            },
          ),
          const VerticalDivider(width: 1, indent: 12, endIndent: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
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

                  if (confirmed != true) return;

                  try {
                    if (widget.user.companyId != null) {
                      await AuditService()
                          .log(
                            companyId: widget.user.companyId!,
                            userId: widget.user.uid,
                            userName: widget.user.fullName,
                            actionType: 'logout',
                            module: 'auth',
                            documentId: widget.user.uid,
                            description: 'User logged out',
                          )
                          .timeout(const Duration(seconds: 2));
                    }
                  } catch (e) {
                    debugPrint('Error logging logout: $e');
                  }
                  await AuthService().signOut();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Text('Profile Settings'),
                ),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFE2E8F0),
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!isMobile)
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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
      case 'Purchase Invoices (Bills)':
        return BillsScreen(user: widget.user);
      case 'Supplier Payments':
        return SupplierPaymentsScreen(user: widget.user);
      case 'Jobs':
        return JobsScreen(user: widget.user);
      case 'Tasks':
        return TasksScreen(user: widget.user);
      case 'Shifts':
        return ShiftsScreen(user: widget.user);
      case 'Quotations':
        return QuotationsScreen(user: widget.user);
      case 'Sales Invoices':
        return InvoicesScreen(user: widget.user);
      case 'Receipts':
        return CustomerPaymentsScreen(user: widget.user);
      case 'Reports':
        return ReportsScreen(user: widget.user);
      case 'Trial Balance':
        return TrialBalanceScreen(user: widget.user);
      case 'Profit & Loss':
        return ProfitLossScreen(user: widget.user);
      case 'Audit Logs':
        return AuditLogsScreen(user: widget.user);
      case 'Company Settings':
        return CompanySettingsScreen(user: widget.user);
      case 'Financial Settings':
        return FinancialSettingsScreen(user: widget.user);
      case 'Financial Period':
        return FinancialPeriodScreen(user: widget.user);
      case 'Docs Prefix':
        return DocsPrefixScreen(user: widget.user);
      case 'Credit Terms (Customers)':
        return CreditTermsScreen(user: widget.user);
      case 'Payment Terms (Quotations)':
        return PaymentTermsScreen(user: widget.user);
      case 'Data Management':
        return DataManagementScreen(user: widget.user);
      case 'User Management':
        return UsersScreen(user: widget.user);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 1200;

    return StreamBuilder<CompanyModel?>(
      stream: _companyService.getCompany(companyId),
      builder: (context, companySnapshot) {
        final currency = companySnapshot.data?.baseCurrency ?? 'AED';

        return StreamBuilder<DashboardStats>(
          stream: _dashboardService.getDashboardStats(companyId),
          builder: (context, statsSnapshot) {
            if (statsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = statsSnapshot.data ?? DashboardStats();

            return SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth < 600 ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Welcome back, ${widget.user.fullName}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (screenWidth > 600)
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Export Summary'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // KPI Section
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int count = constraints.maxWidth > 1200
                          ? 4
                          : (constraints.maxWidth > 800 ? 2 : 1);
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: count,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: constraints.maxWidth > 600
                            ? 1.8
                            : 2.5,
                        children: [
                          KPICard(
                            title: 'Total Revenue',
                            value: AppFormatters.currency(stats.totalRevenue, symbol: currency),
                            icon: Icons.attach_money_rounded,
                            color: Colors.blue,
                            trend: 'Live',
                            isTrendUp: true,
                          ),
                          KPICard(
                            title: 'Total Expenses',
                            value: AppFormatters.currency(
                              stats.totalExpenses,
                              symbol: currency,
                            ),
                            icon: Icons.shopping_bag_rounded,
                            color: Colors.orange,
                          ),
                          KPICard(
                            title: 'Net Profit',
                            value: AppFormatters.currency(stats.totalProfit, symbol: currency),
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
                    },
                  ),

                  const SizedBox(height: 32),

                  // Charts and Activity
                  if (isNarrow)
                    Column(
                      children: [
                        DashboardChart(
                          title: 'Operational Trends',
                          data: [
                            stats.totalRevenue,
                            stats.totalExpenses,
                            stats.totalProfit,
                          ],
                          labels: ['Revenue', 'Expenses', 'Profit'],
                        ),
                        const SizedBox(height: 24),
                        _buildRecentActivityGrid(companyId, currency),
                        const SizedBox(height: 24),
                        _buildOperationalSidebar(stats),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              DashboardChart(
                                title: 'Operational Trends',
                                data: [
                                  stats.totalRevenue,
                                  stats.totalExpenses,
                                  stats.totalProfit,
                                ],
                                labels: ['Revenue', 'Expenses', 'Profit'],
                              ),
                              const SizedBox(height: 24),
                              _buildRecentActivityGrid(companyId, currency),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
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

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
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

  Widget _buildRecentActivityGrid(String companyId, String currency) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count = constraints.maxWidth > 800 ? 2 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: constraints.maxWidth > 600 ? 1.2 : 1.5,
          children: [
            StreamBuilder(
              stream: _dashboardService.getRecentCustomerPayments(companyId),
              builder: (context, snapshot) {
                final items = (snapshot.data ?? [])
                    .map(
                      (p) => RecentActivityItem(
                        title: p.customerName,
                        subtitle: p.paymentNumber,
                        trailing: AppFormatters.currency(p.amount, symbol: currency),
                        icon: Icons.payment_rounded,
                        iconColor: Colors.green,
                        date: p.paymentDate,
                      ),
                    )
                    .toList();
                return RecentActivityCard(
                  title: 'Recent Receipts',
                  items: items,
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
                        trailing: AppFormatters.currency(q.totalAmount, symbol: currency),
                        icon: Icons.description_rounded,
                        iconColor: Colors.blue,
                        date: q.createdAt,
                      ),
                    )
                    .toList();
                return RecentActivityCard(
                  title: 'Latest Quotations',
                  items: items,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
