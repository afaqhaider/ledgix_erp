import 'package:flutter/material.dart';
import '../../models/shift_model.dart';
import '../../services/shift_service.dart';
import '../widgets/shift_pane.dart';
import 'package:ledgixerp/core/widgets/voucher_list_page.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/core/auth/app_user.dart';

class ShiftsScreen extends StatelessWidget {
  final AppUser user;
  const ShiftsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final shiftService = ShiftService();
    final companyId = user.companyId!;

    return VoucherListPage<ShiftModel>(
      title: 'Shifts',
      subtitle: 'Define and manage work shifts',
      stream: shiftService.getShifts(companyId),
      columns: const [
        'Shift Name',
        'Start Time',
        'End Time',
        'Description',
        '',
      ],
      rowBuilder: (shift, index) => DataRow(
        cells: [
          DataCell(Text(shift.name, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(shift.startTime.format(context))),
          DataCell(Text(shift.endTime.format(context))),
          DataCell(Text(shift.description ?? '-')),
          DataCell(
            VoucherActionMenu(
              onView: () => _viewShift(context, shift),
              onEdit: () => _editShift(context, shift, companyId),
              onDelete: () => _deleteShift(context, shift, companyId),
            ),
          ),
        ],
      ),
      onAddNew: () => showErpSidePane(
        context: context,
        builder: ShiftPane(companyId: companyId),
      ),
      emptyTitle: 'No Shifts Defined',
      emptyMessage: 'Define your first shift to start scheduling employees.',
    );
  }

  void _viewShift(BuildContext context, ShiftModel shift) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(shift.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Start Time', shift.startTime.format(context)),
            _detailRow('End Time', shift.endTime.format(context)),
            _detailRow('Description', shift.description ?? '-'),
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

  void _editShift(BuildContext context, ShiftModel shift, String companyId) {
    showErpSidePane(
      context: context,
      builder: ShiftPane(
        companyId: companyId,
        shift: shift,
      ),
    );
  }

  void _deleteShift(BuildContext context, ShiftModel shift, String companyId) {
    showDialog(
      context: context,
      builder: (context) => ERPConfirmDeleteDialog(
        title: 'Delete Shift',
        message: 'Are you sure you want to delete ${shift.name}? This action cannot be undone.',
        onConfirm: () async {
          await ShiftService().deleteShift(companyId, shift.id);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}
