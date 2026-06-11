import 'package:flutter/material.dart';
import 'package:ledgixerp/features/operations/hr/models/attendance_model.dart';
import 'package:ledgixerp/features/operations/hr/models/employee_model.dart';
import 'package:ledgixerp/features/operations/hr/services/attendance_service.dart';
import 'package:ledgixerp/features/operations/hr/services/employee_service.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/core/widgets/erp_layout.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';

class AttendanceScreen extends StatefulWidget {
  final String companyId;
  const AttendanceScreen({super.key, required this.companyId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _attendanceService = AttendanceService();
  final _employeeService = EmployeeService();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ERPPageHeader(
            title: 'Attendance',
            subtitle: 'Manage and track daily employee attendance',
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Text(
                    AppFormatters.date(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<EmployeeModel>>(
              stream: _employeeService.getEmployees(widget.companyId),
              builder: (context, empSnap) {
                if (!empSnap.hasData) return const Center(child: CircularProgressIndicator());
                
                final employees = empSnap.data!;
                
                return StreamBuilder<List<AttendanceModel>>(
                  stream: _attendanceService.getAttendanceForDate(widget.companyId, _selectedDate),
                  builder: (context, attSnap) {
                    if (!attSnap.hasData) return const Center(child: CircularProgressIndicator());
                    
                    final attendanceList = attSnap.data!;
                    final attendanceMap = {for (var a in attendanceList) a.employeeId: a};

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Employee')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Check-In')),
                            DataColumn(label: Text('Check-Out')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: employees.map((emp) {
                            final attendance = attendanceMap[emp.id];
                            return DataRow(
                              cells: [
                                DataCell(Text(emp.name)),
                                DataCell(
                                  attendance == null 
                                    ? const ERPStatusBadge(label: 'Not Marked', color: Colors.grey)
                                    : ERPStatusBadge(
                                        label: attendance.status.label,
                                        color: _getStatusColor(attendance.status),
                                      ),
                                ),
                                DataCell(Text(attendance?.checkIn != null ? AppFormatters.formatTime(attendance!.checkIn!) : '-')),
                                DataCell(Text(attendance?.checkOut != null ? AppFormatters.formatTime(attendance!.checkOut!) : '-')),
                                DataCell(
                                  Row(
                                    children: [
                                      if (attendance == null || attendance.checkIn == null)
                                        IconButton(
                                          icon: const Icon(Icons.login, color: Colors.green),
                                          tooltip: 'Check-In',
                                          onPressed: () => _attendanceService.checkIn(widget.companyId, emp.id, emp.name),
                                        ),
                                      if (attendance != null && attendance.checkIn != null && attendance.checkOut == null)
                                        IconButton(
                                          icon: const Icon(Icons.logout, color: Colors.orange),
                                          tooltip: 'Check-Out',
                                          onPressed: () => _attendanceService.checkOut(widget.companyId, emp.id),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () => _editAttendance(emp, attendance),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Colors.green;
      case AttendanceStatus.absent: return Colors.red;
      case AttendanceStatus.late: return Colors.orange;
      case AttendanceStatus.halfDay: return Colors.blue;
      case AttendanceStatus.onLeave: return Colors.purple;
    }
  }

  void _editAttendance(EmployeeModel employee, AttendanceModel? attendance) {
    showDialog(
      context: context,
      builder: (context) {
        AttendanceStatus status = attendance?.status ?? AttendanceStatus.present;
        final notesController = TextEditingController(text: attendance?.notes);

        return AlertDialog(
          title: Text('Edit Attendance - ${employee.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<AttendanceStatus>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: AttendanceStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                onChanged: (val) { if (val != null) status = val; },
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final now = DateTime.now();
                final model = attendance?.copyWith(
                  status: status,
                  notes: notesController.text,
                ) ?? AttendanceModel(
                  id: '',
                  companyId: widget.companyId,
                  employeeId: employee.id,
                  employeeName: employee.name,
                  date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
                  status: status,
                  notes: notesController.text,
                  createdAt: now,
                  updatedAt: now,
                );
                await _attendanceService.recordAttendance(model);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
