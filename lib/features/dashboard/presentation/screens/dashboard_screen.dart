import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ledgixerp/widgets/sidebar_navigation.dart';
import 'package:ledgixerp/features/auth/services/auth_service.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/chart_of_accounts_screen.dart';
import 'package:ledgixerp/core/auth/permission.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    // Determine the visible items to map the index to the correct screen
    final visibleItems = SidebarNavigation.allItems
        .where((item) => widget.user.role.hasPermission(item.permission))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(visibleItems)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          const VerticalDivider(width: 1, indent: 12, endIndent: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
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
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
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
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
            ),
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              child: _buildBody(visibleItems),
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle(List<SidebarItem> visibleItems) {
    if (_selectedIndex >= visibleItems.length) return 'LedGix ERP';
    return visibleItems[_selectedIndex].label;
  }

  Widget _buildBody(List<SidebarItem> visibleItems) {
    if (_selectedIndex >= visibleItems.length) return const Center(child: Text('Page not found'));

    final selectedPermission = visibleItems[_selectedIndex].permission;

    switch (selectedPermission) {
      case AppPermission.viewDashboard:
        return _buildDashboardOverview();
      case AppPermission.viewAccounting:
        return ChartOfAccountsScreen(user: widget.user);
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(visibleItems[_selectedIndex].icon, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                '${visibleItems[_selectedIndex].label} Module Coming Soon',
                style: const TextStyle(color: Colors.grey, fontSize: 18),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildDashboardOverview() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dashboard Overview',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildStatGrid(context),
          const SizedBox(height: 32),
          _buildChartsSection(context),
          const SizedBox(height: 32),
          _buildRecentSection(context),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = width > 1400 ? 4 : (width > 900 ? 2 : 1);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 2.2,
      children: const [
        _StatCard(
          title: 'Total Revenue',
          value: '\$1,284,500',
          percentage: '+12.5%',
          isPositive: true,
          icon: Icons.attach_money,
          color: Colors.blue,
        ),
        _StatCard(
          title: 'Total Expenses',
          value: '\$432,100',
          percentage: '+5.2%',
          isPositive: false,
          icon: Icons.shopping_cart_outlined,
          color: Colors.orange,
        ),
        _StatCard(
          title: 'Total Profit',
          value: '\$852,400',
          percentage: '+18.2%',
          isPositive: true,
          icon: Icons.trending_up,
          color: Colors.green,
        ),
        _StatCard(
          title: 'Pending Invoices',
          value: '42',
          percentage: '-2.4%',
          isPositive: true,
          icon: Icons.description_outlined,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1100;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildRevenueChart(context)),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildExpenseBreakdown(context)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildRevenueChart(context),
              const SizedBox(height: 24),
              _buildExpenseBreakdown(context),
            ],
          );
        }
      },
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue vs Expenses',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(2, 2),
                        FlSpot(4, 5),
                        FlSpot(6, 3.5),
                        FlSpot(8, 4),
                        FlSpot(10, 8),
                        FlSpot(12, 7),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 1),
                        FlSpot(2, 1.5),
                        FlSpot(4, 2.5),
                        FlSpot(6, 2),
                        FlSpot(8, 2.8),
                        FlSpot(10, 3),
                        FlSpot(12, 4),
                      ],
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseBreakdown(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(
                      color: Colors.blue,
                      value: 40,
                      title: 'HR',
                      radius: 50,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: 30,
                      title: 'Inv',
                      radius: 50,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      color: Colors.purple,
                      value: 15,
                      title: 'Ops',
                      radius: 50,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      color: Colors.grey,
                      value: 15,
                      title: 'Misc',
                      radius: 50,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Invoices',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildInvoiceRow(
              'INV-2024-001',
              'Acme Corp',
              '\$12,400.00',
              'Paid',
              Colors.green,
            ),
            _buildInvoiceRow(
              'INV-2024-002',
              'Global Tech',
              '\$8,200.00',
              'Pending',
              Colors.orange,
            ),
            _buildInvoiceRow(
              'INV-2024-003',
              'Starlight Inc',
              '\$2,100.00',
              'Overdue',
              Colors.red,
            ),
            _buildInvoiceRow(
              'INV-2024-004',
              'Nexus Solutions',
              '\$15,000.00',
              'Paid',
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(
    String id,
    String client,
    String amount,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              id,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(client)),
          Expanded(child: Text(amount)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String percentage;
  final bool isPositive;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.percentage,
    required this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        percentage,
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
