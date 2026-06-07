import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import '../../models/app_user_model.dart';
import '../../services/user_service.dart';
import '../widgets/invite_user_dialog.dart';

class UsersScreen extends StatefulWidget {
  final AppUser user;
  const UsersScreen({super.key, required this.user});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _userService = CompanyUserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showInviteDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Invite User'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<CompanyMemberModel>>(
        stream: _userService.getCompanyMembers(widget.user.companyId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final members = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: members
                    .map(
                      (m) => DataRow(
                        cells: [
                          DataCell(Text(m.displayName)),
                          DataCell(Text(m.email)),
                          DataCell(
                            DropdownButton<UserRole>(
                              value: m.role,
                              underline: const SizedBox(),
                              items: UserRole.values
                                  .where(
                                    (r) =>
                                        r != UserRole.owner ||
                                        m.role == UserRole.owner,
                                  )
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(
                                        r.name.toUpperCase(),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged:
                                  (m.role == UserRole.owner &&
                                      m.uid == widget.user.uid)
                                  ? null // Cannot change own owner role
                                  : (newRole) {
                                      if (newRole != null) {
                                        _userService.updateMemberRole(
                                          widget.user.companyId!,
                                          m.uid,
                                          newRole,
                                        );
                                      }
                                    },
                            ),
                          ),
                          DataCell(_buildStatusChip(m.status)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (m.uid !=
                                    widget.user.uid) // Cannot disable self
                                  IconButton(
                                    icon: Icon(
                                      m.status == UserStatus.disabled
                                          ? Icons.check_circle_outline
                                          : Icons.block,
                                      size: 20,
                                      color: m.status == UserStatus.disabled
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    onPressed: () {
                                      final newStatus =
                                          m.status == UserStatus.disabled
                                          ? UserStatus.active
                                          : UserStatus.disabled;
                                      _userService.updateMemberStatus(
                                        widget.user.companyId!,
                                        m.uid,
                                        newStatus,
                                      );
                                    },
                                    tooltip: m.status == UserStatus.disabled
                                        ? 'Enable User'
                                        : 'Disable User',
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(UserStatus status) {
    Color color;
    switch (status) {
      case UserStatus.active:
        color = Colors.green;
        break;
      case UserStatus.invited:
        color = Colors.orange;
        break;
      case UserStatus.disabled:
        color = Colors.red;
        break;
    }
    return Chip(
      label: Text(
        status.name.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => InviteUserDialog(
        companyId: widget.user.companyId!,
        inviterUserId: widget.user.uid,
      ),
    );
  }
}
