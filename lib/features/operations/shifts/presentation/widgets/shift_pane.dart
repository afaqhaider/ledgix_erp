import 'package:flutter/material.dart';
import '../../models/shift_model.dart';
import '../../services/shift_service.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class ShiftPane extends StatefulWidget {
  final String companyId;
  final ShiftModel? shift;

  const ShiftPane({super.key, required this.companyId, this.shift});

  @override
  State<ShiftPane> createState() => _ShiftPaneState();
}

class _ShiftPaneState extends State<ShiftPane> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.shift != null) {
      _nameController.text = widget.shift!.name;
      _descController.text = widget.shift!.description ?? '';
      _startTime = widget.shift!.startTime;
      _endTime = widget.shift!.endTime;
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final shiftService = ShiftService();
      if (widget.shift == null) {
        await shiftService.addShift(
          ShiftModel(
            id: '',
            companyId: widget.companyId,
            name: _nameController.text.trim(),
            startTime: _startTime,
            endTime: _endTime,
            description: _descController.text.trim(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        await shiftService.updateShift(
          widget.shift!.copyWith(
            name: _nameController.text.trim(),
            startTime: _startTime,
            endTime: _endTime,
            description: _descController.text.trim(),
            updatedAt: DateTime.now(),
          ),
        );
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
      title: widget.shift == null ? 'Add Shift' : 'Edit Shift',
      onCancel: () => Navigator.pop(context),
      onSave: _save,
      isLoading: _isLoading,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Shift Name',
                hintText: 'e.g. Morning Shift',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(_startTime.format(context)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(_endTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
