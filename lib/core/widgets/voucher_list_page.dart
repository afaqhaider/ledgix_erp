import 'package:flutter/material.dart';
import 'erp_layout.dart';
import 'erp_data_table.dart';

class VoucherListPage<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Stream<List<T>> stream;
  final List<String> columns;
  final DataRow Function(T, int) rowBuilder;
  final VoidCallback onAddNew;
  final Widget? filterBar;
  final String emptyTitle;
  final String emptyMessage;

  const VoucherListPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.stream,
    required this.columns,
    required this.rowBuilder,
    required this.onAddNew,
    this.filterBar,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ERPPageHeader(
              title: title,
              subtitle: subtitle,
              actions: [
                ElevatedButton.icon(
                  onPressed: onAddNew,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New'),
                ),
              ],
            ),
            ?filterBar,
            Expanded(
              child: StreamBuilder<List<T>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return ERPEmptyState(
                      title: emptyTitle,
                      message: emptyMessage,
                      action: ElevatedButton.icon(
                        onPressed: onAddNew,
                        icon: const Icon(Icons.add),
                        label: const Text('Add New'),
                      ),
                    );
                  }

                  return ERPDataTable<T>(
                    columns: columns,
                    items: items,
                    rowBuilder: rowBuilder,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VoucherActionMenu extends StatelessWidget {
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VoucherActionMenu({
    super.key,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'view':
            onView();
            break;
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: ListTile(
            leading: Icon(Icons.visibility_outlined, size: 20),
            title: Text('View Details'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined, size: 20),
            title: Text('Edit'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red, size: 20),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
            dense: true,
          ),
        ),
      ],
    );
  }
}
