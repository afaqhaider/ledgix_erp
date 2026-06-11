import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import 'package:ledgixerp/features/operations/jobs/models/job_model.dart';
import 'package:ledgixerp/features/operations/jobs/services/job_service.dart';
import 'package:ledgixerp/features/operations/hr/models/employee_model.dart';
import 'package:ledgixerp/features/operations/hr/services/employee_service.dart';
import 'package:ledgixerp/widgets/searchable_selector.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:intl/intl.dart';

class TaskPane extends StatefulWidget {
  final String companyId;
  final TaskModel? task;

  const TaskPane({super.key, required this.companyId, this.task});

  @override
  State<TaskPane> createState() => _TaskPaneState();
}

class _TaskPaneState extends State<TaskPane> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _dueDate;
  JobModel? _selectedJob;
  EmployeeModel? _assignedTo;
  TaskStatus _status = TaskStatus.todo;
  TaskPriority _priority = TaskPriority.medium;
  bool _isLoading = false;

  List<JobModel> _jobs = [];
  List<EmployeeModel> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadMasterData();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descController.text = widget.task!.description ?? '';
      _dueDate = widget.task!.dueDate;
      _status = widget.task!.status;
      _priority = widget.task!.priority;
    }
  }

  void _loadMasterData() {
    JobService().getActiveJobs(widget.companyId).listen((jobs) {
      if (mounted) {
        setState(() {
          _jobs = jobs;
          if (widget.task?.jobId != null) {
            _selectedJob = jobs.where((j) => j.id == widget.task!.jobId).firstOrNull;
          }
        });
      }
    });

    EmployeeService().getEmployees(widget.companyId).listen((employees) {
      if (mounted) {
        setState(() {
          _employees = employees;
          if (widget.task?.assignedToId != null) {
            _assignedTo = employees.where((e) => e.id == widget.task!.assignedToId).firstOrNull;
          }
        });
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final taskService = TaskService();
      final task = TaskModel(
        id: widget.task?.id ?? '',
        companyId: widget.companyId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        jobId: _selectedJob?.id,
        jobNumber: _selectedJob?.jobNumber,
        jobName: _selectedJob?.jobName,
        assignedToId: _assignedTo?.id,
        assignedToName: _assignedTo?.name,
        status: _status,
        priority: _priority,
        dueDate: _dueDate,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.task == null) {
        await taskService.addTask(task);
      } else {
        await taskService.updateTask(task);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showErpError(context: context, error: e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErpSidePane(
      title: widget.task == null ? 'Create Task' : 'Edit Task',
      onCancel: () => Navigator.pop(context),
      onSave: _save,
      isLoading: _isLoading,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SearchableSelector<JobModel>(
              labelText: 'Link to Job (Optional)',
              items: _jobs,
              itemLabelBuilder: (j) => '${j.jobNumber} - ${j.jobName}',
              onSelected: (val) => setState(() => _selectedJob = val),
              initialValue: _selectedJob,
            ),
            const SizedBox(height: 16),
            SearchableSelector<EmployeeModel>(
              labelText: 'Assign To (Optional)',
              items: _employees,
              itemLabelBuilder: (e) => e.name,
              onSelected: (val) => setState(() => _assignedTo = val),
              initialValue: _assignedTo,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TaskStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: TaskStatus.values
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                        .toList(),
                    onChanged: (val) => setState(() => _status = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<TaskPriority>(
                    initialValue: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: TaskPriority.values
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                        .toList(),
                    onChanged: (val) => setState(() => _priority = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _dueDate = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(_dueDate != null ? DateFormat('yyyy-MM-dd').format(_dueDate!) : 'Not Set'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
