import 'package:flutter/material.dart';
import 'package:ledgixerp/features/operations/hr/models/employee_model.dart';
import 'package:ledgixerp/features/operations/hr/services/employee_service.dart';
import 'package:ledgixerp/features/operations/hr/presentation/widgets/employee_pane.dart';
import 'package:ledgixerp/core/widgets/voucher_list_page.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';

class EmployeesScreen extends StatelessWidget {
  final String companyId;
  const EmployeesScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final employeeService = EmployeeService();

    return VoucherListPage<EmployeeModel>(
      title: 'Employee Master',
      subtitle: 'Manage your workforce, departments and designations',
      stream: employeeService.getEmployees(companyId),
      columns: const [
        'Employee ID',
        'Name',
        'Department',
        'Designation',
        'Joining Date',
        'Status',
        '',
      ],
      rowBuilder: (employee, index) => DataRow(
        cells: [
          DataCell(Text(employee.employeeNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(employee.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(employee.email, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          DataCell(Text(employee.department)),
          DataCell(Text(employee.designation)),
          DataCell(Text(AppFormatters.formatDate(employee.dateJoined))),
          DataCell(
            ERPStatusBadge(
              label: employee.status.label,
              color: employee.status == EmployeeStatus.active ? Colors.green : Colors.grey,
            ),
          ),
          DataCell(
            VoucherActionMenu(
              onView: () => _viewEmployee(context, employee),
              onEdit: () => _editEmployee(context, employee),
              onDelete: () => _deleteEmployee(context, employee),
            ),
          ),
        ],
      ),
      onAddNew: () => showErpSidePane(
        context: context,
        builder: EmployeePane(companyId: companyId),
      ),
      emptyTitle: 'No Employees Found',
      emptyMessage: 'Start by adding your first employee to the system.',
    );
  }

  void _viewEmployee(BuildContext context, EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person_outline),
            const SizedBox(width: 8),
            Text(employee.name),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Employee ID', employee.employeeNumber),
            _detailRow('Email', employee.email),
            _detailRow('Mobile', employee.mobileNumber),
            _detailRow('Department', employee.department),
            _detailRow('Designation', employee.designation),
            _detailRow('Date Joined', AppFormatters.formatDate(employee.dateJoined)),
            _detailRow('Status', employee.status.label),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(value),
        ],
      ),
    );
  }

  void _editEmployee(BuildContext context, EmployeeModel employee) {
    showErpSidePane(
      context: context,
      builder: EmployeePane(
        companyId: companyId,
        employee: employee,
      ),
    );
  }

  void _deleteEmployee(BuildContext context, EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (context) => ERPConfirmDeleteDialog(
        title: 'Delete Employee',
        message: 'Are you sure you want to delete ${employee.name}? This action cannot be undone.',
        onConfirm: () async {
          await EmployeeService().deleteEmployee(companyId, employee.id);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}
