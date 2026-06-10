import 'package:flutter/material.dart';

class ERPDataTable<T> extends StatelessWidget {
  final List<String> columns;
  final List<T> items;
  final DataRow Function(T, int) rowBuilder;
  final bool showCheckboxColumn;

  const ERPDataTable({
    super.key,
    required this.columns,
    required this.items,
    required this.rowBuilder,
    this.showCheckboxColumn = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: showCheckboxColumn,
          headingRowColor: WidgetStateProperty.all(
            theme.brightness == Brightness.dark 
              ? Colors.white.withValues(alpha: 0.05) 
              : Colors.black.withValues(alpha: 0.02)
          ),
          columns: columns.map((col) => DataColumn(
            label: Text(
              col,
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
          )).toList(),
          rows: items.asMap().entries.map((entry) => rowBuilder(entry.value, entry.key)).toList(),
        ),
      ),
    );
  }
}
