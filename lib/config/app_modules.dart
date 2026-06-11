import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/chart_of_accounts_screen.dart';
import 'package:ledgixerp/features/accounting/journal/presentation/screens/journal_entries_screen.dart';
import 'package:ledgixerp/features/approvals/presentation/screens/approval_center_screen.dart';
import 'package:ledgixerp/features/audit/presentation/screens/audit_logs_screen.dart';
import 'package:ledgixerp/features/banking/presentation/screens/bank_accounts_screen.dart';
import 'package:ledgixerp/features/banking/presentation/screens/bank_reconciliation_screen.dart';
import 'package:ledgixerp/features/company/presentation/screens/company_settings_screen.dart';
import 'package:ledgixerp/features/crm/customer_payments/presentation/screens/customer_payments_screen.dart';
import 'package:ledgixerp/features/crm/customers/presentation/screens/customers_screen.dart';
import 'package:ledgixerp/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:ledgixerp/features/invoices/presentation/screens/invoices_screen.dart';
import 'package:ledgixerp/features/operations/shifts/presentation/screens/shifts_screen.dart';
import 'package:ledgixerp/features/operations/tasks/presentation/screens/tasks_screen.dart';
import 'package:ledgixerp/features/purchase_orders/presentation/screens/purchase_orders_screen.dart';
import 'package:ledgixerp/features/quotations/presentation/screens/quotations_screen.dart';
import 'package:ledgixerp/features/expenses/presentation/screens/expense_vouchers_screen.dart';
import 'package:ledgixerp/features/operations/jobs/presentation/screens/jobs_screen.dart';
import 'package:ledgixerp/features/reports/presentation/screens/job_report_screen.dart';
import 'package:ledgixerp/features/reports/presentation/screens/cash_flow_screen.dart';
import 'package:ledgixerp/features/reports/presentation/screens/account_statement_screen.dart';
import 'package:ledgixerp/features/reports/presentation/screens/balance_sheet_screen.dart';
import 'package:ledgixerp/features/reports/presentation/screens/general_ledger_screen.dart';
import 'package:ledgixerp/features/reports/presentation/screens/profit_loss_screen.dart';
import 'package:ledgixerp/features/reports/presentation/screens/trial_balance_screen.dart';
import 'package:ledgixerp/features/settings/presentation/screens/approval_rules_screen.dart';
import 'package:ledgixerp/features/settings/presentation/screens/credit_terms_screen.dart';
import 'package:ledgixerp/features/settings/presentation/screens/data_management_screen.dart';
import 'package:ledgixerp/features/settings/presentation/screens/docs_prefix_screen.dart';
import 'package:ledgixerp/features/settings/presentation/screens/financial_period_screen.dart';
import 'package:ledgixerp/features/settings/presentation/screens/financial_settings_screen.dart';
import 'package:ledgixerp/features/settings/presentation/screens/payment_terms_screen.dart';
import 'package:ledgixerp/features/supplier_payments/presentation/screens/supplier_payments_screen.dart';
import 'package:ledgixerp/features/suppliers/presentation/screens/bills_screen.dart';
import 'package:ledgixerp/features/suppliers/presentation/screens/suppliers_screen.dart';
import 'package:ledgixerp/features/users/presentation/screens/users_screen.dart';
import 'package:ledgixerp/features/operations/hr/presentation/screens/employees_screen.dart';
import 'package:ledgixerp/features/operations/hr/presentation/screens/attendance_screen.dart';

enum AppModuleId {
  dashboard,
  approvals,
  customers,
  quotations,
  salesInvoices,
  receipts,
  suppliers,
  purchaseOrders,
  bills,
  supplierPayments,
  employees,
  attendance,
  jobs,
  tasks,
  shifts,
  inventory,
  expenseVouchers,
  chartOfAccounts,
  journalEntries,
  accountingSettings,
  bankAccounts,
  bankReconciliation,
  cash,
  reports,
  financialReports,
  trialBalance,
  profitLoss,
  balanceSheet,
  statementOfChangesInEquity,
  generalLedger,
  jobReports,
  cashFlowStatement,
  accountStatement,
  companySettings,
  financialSettings,
  financialPeriod,
  docsPrefix,
  creditTerms,
  paymentTerms,
  userManagement,
  auditLogs,
  dataManagement,
  approvalRules,
}

typedef AppModulePageBuilder = Widget Function(AppUser user);

class AppModule {
  final AppModuleId id;
  final IconData icon;
  final String label;
  final AppPermission permission;
  final AppModulePageBuilder? pageBuilder;
  final List<AppModule> subModules;

  const AppModule({
    required this.id,
    required this.icon,
    required this.label,
    required this.permission,
    this.pageBuilder,
    this.subModules = const [],
  });

  bool get hasPage => pageBuilder != null;

  Widget buildPage(AppUser user) {
    final builder = pageBuilder;
    if (builder == null) {
      return ComingSoonScreen(moduleName: label);
    }
    return builder(user);
  }
}

class AppNavigationSection {
  final String header;
  final IconData icon;
  final List<AppModule> modules;
  final bool isCollapsible;

  const AppNavigationSection({
    required this.header,
    required this.icon,
    required this.modules,
    this.isCollapsible = true,
  });
}

class ComingSoonScreen extends StatelessWidget {
  final String moduleName;

  const ComingSoonScreen({super.key, required this.moduleName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '$moduleName Module Coming Soon',
            style: const TextStyle(color: Colors.grey, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class AppModules {
  const AppModules._();

  static const dashboard = AppModule(
    id: AppModuleId.dashboard,
    icon: Icons.home_rounded,
    label: 'Home',
    permission: AppPermission.viewDashboard,
  );

  static final List<AppNavigationSection> sections = [
    const AppNavigationSection(
      header: 'Home',
      icon: Icons.home_rounded,
      isCollapsible: false,
      modules: [dashboard],
    ),
    AppNavigationSection(
      header: 'Approvals',
      icon: Icons.fact_check_rounded,
      isCollapsible: false,
      modules: [
        AppModule(
          id: AppModuleId.approvals,
          icon: Icons.fact_check_rounded,
          label: 'Approvals',
          permission: AppPermission.viewApprovals,
          pageBuilder: (user) => ApprovalCenterScreen(user: user),
        ),
      ],
    ),
    AppNavigationSection(
      header: 'Customers',
      icon: Icons.people_alt_rounded,
      modules: [
        AppModule(
          id: AppModuleId.customers,
          icon: Icons.people_alt_rounded,
          label: 'Customers',
          permission: AppPermission.viewCustomers,
          pageBuilder: (user) => CustomersScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.quotations,
          icon: Icons.description_rounded,
          label: 'Quotations',
          permission: AppPermission.viewInvoices,
          pageBuilder: (user) => QuotationsScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.salesInvoices,
          icon: Icons.receipt_long_rounded,
          label: 'Sales Invoices',
          permission: AppPermission.viewInvoices,
          pageBuilder: (user) => InvoicesScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.receipts,
          icon: Icons.payments_rounded,
          label: 'Receipts',
          permission: AppPermission.viewInvoices,
          pageBuilder: (user) => CustomerPaymentsScreen(user: user),
        ),
      ],
    ),
    AppNavigationSection(
      header: 'Vendors',
      icon: Icons.local_shipping_rounded,
      modules: [
        AppModule(
          id: AppModuleId.suppliers,
          icon: Icons.local_shipping_rounded,
          label: 'Suppliers',
          permission: AppPermission.viewSuppliers,
          pageBuilder: (user) => SuppliersScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.purchaseOrders,
          icon: Icons.shopping_cart_rounded,
          label: 'Purchase Orders',
          permission: AppPermission.viewSuppliers,
          pageBuilder: (user) => PurchaseOrdersScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.bills,
          icon: Icons.receipt_long_rounded,
          label: 'Purchase Invoices (Bills)',
          permission: AppPermission.viewBills,
          pageBuilder: (user) => BillsScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.supplierPayments,
          icon: Icons.paid_rounded,
          label: 'Supplier Payments',
          permission: AppPermission.viewSuppliers,
          pageBuilder: (user) => SupplierPaymentsScreen(user: user),
        ),
      ],
    ),
    AppNavigationSection(
      header: 'Operations',
      icon: Icons.precision_manufacturing_rounded,
      modules: [
        AppModule(
          id: AppModuleId.employees,
          icon: Icons.badge_rounded,
          label: 'HR (Employees)',
          permission: AppPermission.viewOperations,
          pageBuilder: (user) => EmployeesScreen(companyId: user.companyId!),
        ),
        AppModule(
          id: AppModuleId.attendance,
          icon: Icons.how_to_reg_rounded,
          label: 'Attendance',
          permission: AppPermission.viewOperations,
          pageBuilder: (user) => AttendanceScreen(companyId: user.companyId!),
        ),
        AppModule(
          id: AppModuleId.jobs,
          icon: Icons.work_rounded,
          label: 'Jobs',
          permission: AppPermission.viewOperations,
          pageBuilder: (user) => JobsScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.tasks,
          icon: Icons.task_alt_rounded,
          label: 'Tasks',
          permission: AppPermission.viewOperations,
          pageBuilder: (user) => TasksScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.shifts,
          icon: Icons.more_time_rounded,
          label: 'Shifts',
          permission: AppPermission.viewOperations,
          pageBuilder: (user) => ShiftsScreen(user: user),
        ),
      ],
    ),
    AppNavigationSection(
      header: 'Inventory',
      icon: Icons.inventory_2_rounded,
      isCollapsible: false,
      modules: [
        AppModule(
          id: AppModuleId.inventory,
          icon: Icons.inventory_2_rounded,
          label: 'Inventory',
          permission: AppPermission.viewAccounting,
          pageBuilder: (user) => InventoryScreen(user: user),
        ),
      ],
    ),
    AppNavigationSection(
      header: 'Accounting',
      icon: Icons.account_tree_rounded,
      modules: [
        AppModule(
          id: AppModuleId.chartOfAccounts,
          icon: Icons.account_tree_rounded,
          label: 'Chart of Accounts',
          permission: AppPermission.viewAccounting,
          pageBuilder: (user) => ChartOfAccountsScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.journalEntries,
          icon: Icons.history_edu_rounded,
          label: 'Journal Entries',
          permission: AppPermission.viewAccounting,
          pageBuilder: (user) => JournalEntriesScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.expenseVouchers,
          icon: Icons.trending_down_rounded,
          label: 'Expense Vouchers',
          permission: AppPermission.viewAccounting,
          pageBuilder: (user) => ExpenseVouchersScreen(user: user),
        ),
        const AppModule(
          id: AppModuleId.accountingSettings,
          icon: Icons.settings_applications_rounded,
          label: 'Accounting Settings',
          permission: AppPermission.manageAccounting,
        ),
      ],
    ),
    AppNavigationSection(
      header: 'Banking',
      icon: Icons.account_balance_rounded,
      modules: [
        AppModule(
          id: AppModuleId.bankAccounts,
          icon: Icons.account_balance_wallet_rounded,
          label: 'Bank Accounts',
          permission: AppPermission.viewAccounting,
          pageBuilder: (user) => BankAccountsScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.bankReconciliation,
          icon: Icons.sync_alt_rounded,
          label: 'Bank Reconciliation',
          permission: AppPermission.viewAccounting,
          pageBuilder: (user) => BankReconciliationScreen(user: user),
        ),
        const AppModule(
          id: AppModuleId.cash,
          icon: Icons.payments_rounded,
          label: 'Cash',
          permission: AppPermission.viewAccounting,
        ),
      ],
    ),
    AppNavigationSection(
      header: 'Reports',
      icon: Icons.analytics_rounded,
      modules: [
        AppModule(
          id: AppModuleId.financialReports,
          icon: Icons.account_balance_rounded,
          label: 'Financial Reports',
          permission: AppPermission.viewReports,
          subModules: [
            AppModule(
              id: AppModuleId.profitLoss,
              icon: Icons.trending_up_rounded,
              label: 'Profit & Loss',
              permission: AppPermission.viewReports,
              pageBuilder: (user) => ProfitLossScreen(companyId: user.companyId!),
            ),
            AppModule(
              id: AppModuleId.balanceSheet,
              icon: Icons.pie_chart_rounded,
              label: 'Balance Sheet',
              permission: AppPermission.viewReports,
              pageBuilder: (user) => BalanceSheetScreen(companyId: user.companyId!),
            ),
            AppModule(
              id: AppModuleId.cashFlowStatement,
              icon: Icons.unfold_more_rounded,
              label: 'Cash Flow Statement',
              permission: AppPermission.viewReports,
              pageBuilder: (user) => CashFlowScreen(companyId: user.companyId!),
            ),
            const AppModule(
              id: AppModuleId.statementOfChangesInEquity,
              icon: Icons.account_balance_rounded,
              label: 'Statement of Changes in Equity',
              permission: AppPermission.viewReports,
            ),
          ],
        ),
        AppModule(
          id: AppModuleId.trialBalance,
          icon: Icons.account_balance_rounded,
          label: 'Trial Balance',
          permission: AppPermission.viewReports,
          pageBuilder: (user) => TrialBalanceScreen(companyId: user.companyId!),
        ),
        AppModule(
          id: AppModuleId.generalLedger,
          icon: Icons.list_alt_rounded,
          label: 'General Ledger',
          permission: AppPermission.viewReports,
          pageBuilder: (user) =>
              GeneralLedgerScreen(companyId: user.companyId!),
        ),
        AppModule(
          id: AppModuleId.accountStatement,
          icon: Icons.description_rounded,
          label: 'Account Statement',
          permission: AppPermission.viewReports,
          pageBuilder: (user) =>
              AccountStatementScreen(companyId: user.companyId!),
        ),
        AppModule(
          id: AppModuleId.jobReports,
          icon: Icons.assignment_turned_in_rounded,
          label: 'Job Reports',
          permission: AppPermission.viewReports,
          pageBuilder: (user) => JobReportScreen(companyId: user.companyId!),
        ),
      ],
    ),
    AppNavigationSection(
      header: 'Settings',
      icon: Icons.settings_rounded,
      modules: [
        AppModule(
          id: AppModuleId.companySettings,
          icon: Icons.business_rounded,
          label: 'Basic Settings',
          permission: AppPermission.manageSettings,
          pageBuilder: (user) => CompanySettingsScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.financialSettings,
          icon: Icons.account_balance_wallet_rounded,
          label: 'Financial Settings',
          permission: AppPermission.manageSettings,
          pageBuilder: (user) => FinancialSettingsScreen(user: user),
          subModules: [
            AppModule(
              id: AppModuleId.financialPeriod,
              icon: Icons.calendar_month_rounded,
              label: 'Financial Period',
              permission: AppPermission.manageSettings,
              pageBuilder: (user) => FinancialPeriodScreen(user: user),
            ),
            AppModule(
              id: AppModuleId.docsPrefix,
              icon: Icons.label_important_rounded,
              label: 'Docs Prefix',
              permission: AppPermission.manageSettings,
              pageBuilder: (user) => DocsPrefixScreen(user: user),
            ),
            AppModule(
              id: AppModuleId.creditTerms,
              icon: Icons.credit_card_rounded,
              label: 'Credit Terms',
              permission: AppPermission.manageSettings,
              pageBuilder: (user) => CreditTermsScreen(user: user),
            ),
            AppModule(
              id: AppModuleId.paymentTerms,
              icon: Icons.payments_rounded,
              label: 'Payment Terms',
              permission: AppPermission.manageSettings,
              pageBuilder: (user) => PaymentTermsScreen(user: user),
            ),
          ],
        ),
        AppModule(
          id: AppModuleId.userManagement,
          icon: Icons.manage_accounts_rounded,
          label: 'User Management',
          permission: AppPermission.manageUsers,
          pageBuilder: (user) => UsersScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.auditLogs,
          icon: Icons.history_rounded,
          label: 'Audit Logs',
          permission: AppPermission.manageSettings,
          pageBuilder: (user) => AuditLogsScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.dataManagement,
          icon: Icons.storage_rounded,
          label: 'Data Management',
          permission: AppPermission.manageSettings,
          pageBuilder: (user) => DataManagementScreen(user: user),
        ),
        AppModule(
          id: AppModuleId.approvalRules,
          icon: Icons.rule_rounded,
          label: 'Approval Rules',
          permission: AppPermission.manageSettings,
          pageBuilder: (user) => ApprovalRulesScreen(user: user),
        ),
      ],
    ),
  ];

  static AppModule moduleById(AppModuleId id) {
    for (final module in allModules) {
      if (module.id == id) return module;
    }
    return dashboard;
  }

  static List<AppModule> get allModules {
    return sections
        .expand((section) => section.modules)
        .expand((module) => [module, ...module.subModules])
        .toList(growable: false);
  }
}
