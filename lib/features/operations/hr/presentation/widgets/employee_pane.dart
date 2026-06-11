import 'package:flutter/material.dart';
import 'package:ledgixerp/features/operations/hr/models/employee_model.dart';
import 'package:ledgixerp/features/operations/hr/models/department_model.dart';
import 'package:ledgixerp/features/operations/hr/models/designation_model.dart';
import 'package:ledgixerp/features/operations/hr/services/employee_service.dart';
import 'package:ledgixerp/features/operations/shifts/models/shift_model.dart';
import 'package:ledgixerp/features/operations/shifts/services/shift_service.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/widgets/searchable_selector.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';

class EmployeePane extends StatefulWidget {
  final String companyId;
  final EmployeeModel? employee;
  final Function(EmployeeModel)? onSuccess;

  const EmployeePane({
    super.key,
    required this.companyId,
    this.employee,
    this.onSuccess,
  });

  @override
  State<EmployeePane> createState() => _EmployeePaneState();
}

class _EmployeePaneState extends State<EmployeePane> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late DateTime _dateJoined;
  String? _selectedDepartment;
  String? _selectedDesignation;
  ShiftModel? _selectedShift;
  EmployeeStatus _status = EmployeeStatus.active;
  bool _isLoading = false;

  final _employeeService = EmployeeService();
  final _shiftService = ShiftService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name);
    _emailController = TextEditingController(text: widget.employee?.email);
    _mobileController = TextEditingController(text: widget.employee?.mobileNumber);
    _dateJoined = widget.employee?.dateJoined ?? DateTime.now();
    _selectedDepartment = widget.employee?.department;
    _selectedDesignation = widget.employee?.designation;
    _status = widget.employee?.status ?? EmployeeStatus.active;
    
    if (widget.employee?.shiftId != null) {
      _selectedShift = ShiftModel(
        id: widget.employee!.shiftId!,
        companyId: widget.companyId,
        name: widget.employee!.shiftName ?? 'Unknown Shift',
        startTime: const TimeOfDay(hour: 9, minute: 0), // Placeholder
        endTime: const TimeOfDay(hour: 17, minute: 0), // Placeholder
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateJoined,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dateJoined = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartment == null || _selectedDesignation == null) {
      if (mounted) {
        showErpError(
            context: context, message: 'Department and Designation are required.');
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      String employeeNumber = widget.employee?.employeeNumber ?? '';
      if (widget.employee == null) {
        employeeNumber = await _employeeService.generateEmployeeNumber(widget.companyId);
      }

      final employee = EmployeeModel(
        id: widget.employee?.id ?? '',
        companyId: widget.companyId,
        employeeNumber: employeeNumber,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        department: _selectedDepartment!,
        designation: _selectedDesignation!,
        dateJoined: _dateJoined,
        status: _status,
        shiftId: _selectedShift?.id,
        shiftName: _selectedShift?.name,
        createdAt: widget.employee?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.employee == null) {
        await _employeeService.createEmployee(employee);
      } else {
        await _employeeService.updateEmployee(employee);
      }

      if (widget.onSuccess != null) widget.onSuccess!(employee);

      if (mounted) {
        Navigator.pop(context);
        showErpSuccess(
          context: context,
          title: 'Success',
          message: 'Employee ${widget.employee == null ? 'added' : 'updated'} successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        showErpError(context: context, error: e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDepartmentDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Department'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Department Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final deptName = controller.text.trim();
                await _employeeService.addDepartment(
                    widget.companyId, deptName);
                if (mounted && dialogContext.mounted) {
                  setState(() => _selectedDepartment = deptName);
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddDesignationDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Designation'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Designation Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final desigName = controller.text.trim();
                await _employeeService.addDesignation(
                    widget.companyId, desigName);
                if (mounted && dialogContext.mounted) {
                  setState(() => _selectedDesignation = desigName);
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErpSidePane(
      title: widget.employee == null ? 'Add New Employee' : 'Edit Employee',
      isLoading: _isLoading,
      onCancel: () => Navigator.pop(context),
      onSave: _save,
      saveLabel: widget.employee == null ? 'Create Employee' : 'Save Changes',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information', style: ErpFormStyle.sectionHeaderStyle(context)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: ErpFormStyle.inputDecoration(context, 'Employee Name *', icon: Icons.person_outline),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: ErpFormStyle.inputDecoration(context, 'Email Address', icon: Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _mobileController,
                    decoration: ErpFormStyle.inputDecoration(context, 'Mobile Number', icon: Icons.phone_android_outlined),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Job Details', style: ErpFormStyle.sectionHeaderStyle(context)),
            const SizedBox(height: 16),
            StreamBuilder<List<DepartmentModel>>(
              stream: _employeeService.getDepartments(widget.companyId),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                return SearchableSelector<DepartmentModel>(
                  labelText: 'Department *',
                  items: items,
                  itemLabelBuilder: (i) => i.name,
                  initialValue: _selectedDepartment != null ? DepartmentModel(id: '', companyId: widget.companyId, name: _selectedDepartment!) : null,
                  onSelected: (val) => setState(() => _selectedDepartment = val?.name),
                  addLabel: 'Add New Department',
                  onAdd: _showAddDepartmentDialog,
                );
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<DesignationModel>>(
              stream: _employeeService.getDesignations(widget.companyId),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                return SearchableSelector<DesignationModel>(
                  labelText: 'Designation *',
                  items: items,
                  itemLabelBuilder: (i) => i.name,
                  initialValue: _selectedDesignation != null ? DesignationModel(id: '', companyId: widget.companyId, name: _selectedDesignation!) : null,
                  onSelected: (val) => setState(() => _selectedDesignation = val?.name),
                  addLabel: 'Add New Designation',
                  onAdd: _showAddDesignationDialog,
                );
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<ShiftModel>>(
              stream: _shiftService.getShifts(widget.companyId),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                ShiftModel? initialShift;
                if (_selectedShift != null) {
                   initialShift = items.where((s) => s.id == _selectedShift!.id).firstOrNull ?? _selectedShift;
                }
                
                return SearchableSelector<ShiftModel>(
                  labelText: 'Default Shift',
                  items: items,
                  itemLabelBuilder: (i) => i.name,
                  initialValue: initialShift,
                  onSelected: (val) => setState(() => _selectedShift = val),
                );
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: ErpFormStyle.inputDecoration(context, 'Date Joined', icon: Icons.calendar_today_outlined),
                child: Text(AppFormatters.formatDate(_dateJoined)),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            DropdownButtonFormField<EmployeeStatus>(
              value: _status,
              decoration: ErpFormStyle.inputDecoration(context, 'Status'),
              items: EmployeeStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
          ],
        ),
      ),
    );
  }
}
