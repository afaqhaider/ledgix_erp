import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/crm/customers/models/customer_model.dart';
import 'package:ledgixerp/features/crm/customers/services/customer_service.dart';
import 'package:ledgixerp/widgets/searchable_selector.dart';
import 'package:ledgixerp/features/operations/jobs/models/job_model.dart';
import 'package:ledgixerp/features/operations/jobs/services/job_service.dart';

class AddJobPane extends StatefulWidget {
  final AppUser user;
  const AddJobPane({super.key, required this.user});

  @override
  State<AddJobPane> createState() => _AddJobPaneState();
}

class _AddJobPaneState extends State<AddJobPane> {
  final _formKey = GlobalKey<FormState>();
  final _service = JobService();
  final _customerService = CustomerService();
  
  bool _isLoading = false;
  List<CustomerModel> _customers = [];

  final _nameController = TextEditingController();
  final _revenueController = TextEditingController(text: '0');
  final _costController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  
  CustomerModel? _selectedCustomer;
  DateTime _startDate = DateTime.now();
  JobStatus _status = JobStatus.active;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _customerService.getCustomers(widget.user.companyId!).listen((list) {
      if (mounted) setState(() => _customers = list);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Job Name'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          SearchableSelector<CustomerModel>(
            labelText: 'Customer (Optional)',
            items: _customers,
            itemLabelBuilder: (c) => c.name,
            onSelected: (val) => setState(() => _selectedCustomer = val),
            initialValue: _selectedCustomer,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                  trailing: const Icon(Icons.calendar_today, size: 20),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => _startDate = date);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<JobStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: JobStatus.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.label),
                  )).toList(),
                  onChanged: (val) => setState(() => _status = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _revenueController,
                  decoration: const InputDecoration(labelText: 'Expected Revenue'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _costController,
                  decoration: const InputDecoration(labelText: 'Expected Cost'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes'),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading 
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create Job'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final companyId = widget.user.companyId!;
      final jobNumber = await _service.generateJobNumber(companyId);
      final rev = double.tryParse(_revenueController.text) ?? 0.0;
      final cost = double.tryParse(_costController.text) ?? 0.0;

      final job = JobModel(
        id: const Uuid().v4(),
        companyId: companyId,
        jobNumber: jobNumber,
        jobName: _nameController.text,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name,
        startDate: _startDate,
        status: _status,
        expectedRevenue: rev,
        expectedCost: cost,
        expectedProfitLoss: rev - cost,
        notes: _notesController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.user.uid,
      );

      await _service.createJob(job);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
