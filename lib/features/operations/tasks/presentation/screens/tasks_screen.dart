import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../widgets/task_pane.dart';
import 'package:ledgixerp/core/widgets/voucher_list_page.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/core/auth/app_user.dart';

class TasksScreen extends StatelessWidget {
  final AppUser user;
  const TasksScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final taskService = TaskService();
    final companyId = user.companyId!;

    return VoucherListPage<TaskModel>(
      title: 'Tasks',
      subtitle: 'Manage and track project tasks',
      stream: taskService.getTasks(companyId),
      columns: const [
        'Task',
        'Job',
        'Assigned To',
        'Priority',
        'Due Date',
        'Status',
        '',
      ],
      rowBuilder: (task, index) => DataRow(
        cells: [
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (task.description != null && task.description!.isNotEmpty)
                  Text(task.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          DataCell(Text(task.jobNumber ?? '-')),
          DataCell(Text(task.assignedToName ?? 'Unassigned')),
          DataCell(
            ERPStatusBadge(
              label: task.priority.label,
              color: _getPriorityColor(task.priority),
            ),
          ),
          DataCell(Text(task.dueDate != null ? AppFormatters.formatDate(task.dueDate!) : '-')),
          DataCell(
            ERPStatusBadge(
              label: task.status.label,
              color: _getStatusColor(task.status),
            ),
          ),
          DataCell(
            VoucherActionMenu(
              onView: () => _viewTask(context, task),
              onEdit: () => _editTask(context, task, companyId),
              onDelete: () => _deleteTask(context, task, companyId),
            ),
          ),
        ],
      ),
      onAddNew: () => showErpSidePane(
        context: context,
        builder: TaskPane(companyId: companyId),
      ),
      emptyTitle: 'No Tasks Found',
      emptyMessage: 'Create your first task to start tracking work.',
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low: return Colors.blue;
      case TaskPriority.medium: return Colors.orange;
      case TaskPriority.high: return Colors.deepOrange;
      case TaskPriority.urgent: return Colors.red;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo: return Colors.grey;
      case TaskStatus.inProgress: return Colors.blue;
      case TaskStatus.completed: return Colors.green;
      case TaskStatus.cancelled: return Colors.red.shade300;
    }
  }

  void _viewTask(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Status', task.status.label),
            _detailRow('Priority', task.priority.label),
            _detailRow('Job', task.jobNumber ?? '-'),
            _detailRow('Assigned To', task.assignedToName ?? 'Unassigned'),
            _detailRow('Due Date',
                task.dueDate != null ? AppFormatters.formatDate(task.dueDate!) : '-'),
            const SizedBox(height: 8),
            const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(task.description ?? '-'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(value),
        ],
      ),
    );
  }

  void _editTask(BuildContext context, TaskModel task, String companyId) {
    showErpSidePane(
      context: context,
      builder: TaskPane(
        companyId: companyId,
        task: task,
      ),
    );
  }

  void _deleteTask(BuildContext context, TaskModel task, String companyId) {
    showDialog(
      context: context,
      builder: (context) => ERPConfirmDeleteDialog(
        title: 'Delete Task',
        message: 'Are you sure you want to delete this task? This action cannot be undone.',
        onConfirm: () async {
          await TaskService().deleteTask(companyId, task.id);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}
