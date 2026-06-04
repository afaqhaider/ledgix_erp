enum AppPermission {
  // Generic Actions
  view('View'),
  create('Create'),
  edit('Edit'),
  delete('Delete'),
  approve('Approve'),
  post('Post'),
  export('Export'),

  // Module Specific View Permissions
  viewDashboard('View Home'),
  viewApprovals('View Approvals'),
  viewCustomers('View Customers'),
  viewSuppliers('View Suppliers'),
  viewInvoices('View Invoices'),
  viewBills('View Bills'),
  viewOperations('View Operations'),
  viewAccounting('View Accounting'),
  viewReports('View Reports'),

  // Module Specific Manage Permissions
  manageCustomers('Manage Customers'),
  manageSuppliers('Manage Suppliers'),
  manageInvoices('Manage Invoices'),
  manageBills('Manage Bills'),
  manageAccounting('Manage Accounting'),
  manageSettings('Manage Settings'),
  manageUsers('Manage Users');

  final String label;
  const AppPermission(this.label);
}
