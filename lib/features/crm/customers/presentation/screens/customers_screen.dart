import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/features/crm/customers/models/customer_model.dart';
import 'package:ledgixerp/features/crm/customers/services/customer_service.dart';
import 'package:ledgixerp/features/crm/customers/presentation/widgets/add_customer_dialog.dart';

class CustomersScreen extends StatefulWidget {
  final AppUser user;
  const CustomersScreen({super.key, required this.user});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _customerService = CustomerService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = widget.user.role.hasPermission(AppPermission.manageCustomers);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () => _showAddCustomerDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Add Customer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<CustomerModel>>(
        stream: _customerService.getCustomers(widget.user.companyId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final customers = snapshot.data ?? [];

          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No customers found',
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _showAddCustomerDialog(context),
                      child: const Text('Add Your First Customer'),
                    ),
                  ],
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: DataTable(
                horizontalMargin: 24,
                columnSpacing: 40,
                columns: const [
                  DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: customers.map((customer) {
                  return DataRow(
                    cells: [
                      DataCell(Text(customer.name)),
                      DataCell(Text(customer.email)),
                      DataCell(Text(customer.phone ?? '-')),
                      DataCell(
                        Icon(
                          customer.isActive ? Icons.check_circle : Icons.cancel,
                          color: customer.isActive ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: canManage ? () {} : null,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddCustomerDialog(companyId: widget.user.companyId!),
    );
  }
}
