import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/reports/models/report_models.dart';
import 'report_drill_down_modal.dart';

enum ReportDisplayMode {
  trialBalance, // Dr, Cr
  generalLedger, // Opening, Dr, Cr, Closing
  singleBalance, // Balance (BS, PL)
}

class HierarchicalReportRow extends StatefulWidget {
  final String companyId;
  final FinancialReportNode node;
  final ReportDisplayMode displayMode;
  final bool initiallyExpanded;

  const HierarchicalReportRow({
    super.key,
    required this.companyId,
    required this.node,
    required this.displayMode,
    this.initiallyExpanded = false,
  });

  @override
  State<HierarchicalReportRow> createState() => _HierarchicalReportRowState();
}

class _HierarchicalReportRowState extends State<HierarchicalReportRow> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(HierarchicalReportRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
    }
  }

  void _handleTap() {
    if (widget.node.children.isNotEmpty) {
      setState(() => _isExpanded = !_isExpanded);
    } else if (widget.node.type == 'account') {
      ReportDrillDownModal.show(
        context,
        companyId: widget.companyId,
        accountId: widget.node.id,
        accountName: widget.node.name,
        accountCode: widget.node.code,
        category: widget.node.category!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final node = widget.node;
    final hasChildren = node.children.isNotEmpty;

    return Column(
      children: [
        InkWell(
          onTap: _handleTap,
          child: Container(
            padding: EdgeInsets.only(
              left: (16.0 * node.level) + 16.0,
              right: 24,
              top: node.level == 0 ? 14 : 10,
              bottom: node.level == 0 ? 14 : 10,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              color: node.level == 0 
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : node.level == 1 
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1)
                  : null,
            ),
            child: Row(
              children: [
                if (hasChildren)
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 20,
                    color: theme.colorScheme.primary,
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                if (node.code.isNotEmpty) ...[
                  SizedBox(
                    width: 80,
                    child: Text(
                      node.code,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    node.name,
                    style: GoogleFonts.inter(
                      fontSize: node.level == 0 ? 15 : 14,
                      fontWeight: node.level == 0 ? FontWeight.w800 : (node.isGroup ? FontWeight.w700 : FontWeight.w500),
                      color: (!hasChildren && node.type == 'account') ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
                ..._buildValueCells(theme, node),
              ],
            ),
          ),
        ),
        if (_isExpanded && hasChildren)
          ...node.children.map((child) => HierarchicalReportRow(
                key: ValueKey(child.id),
                companyId: widget.companyId,
                node: child,
                displayMode: widget.displayMode,
                initiallyExpanded: widget.initiallyExpanded,
              )),
      ],
    );
  }

  List<Widget> _buildValueCells(ThemeData theme, FinancialReportNode node) {
    switch (widget.displayMode) {
      case ReportDisplayMode.trialBalance:
        return [
          _buildValueCell(node.debit, theme, isBold: node.isGroup),
          _buildValueCell(node.credit, theme, isBold: node.isGroup),
        ];
      case ReportDisplayMode.generalLedger:
        return [
          _buildValueCell(node.openingBalance, theme, isBold: node.isGroup),
          _buildValueCell(node.debit, theme, isBold: node.isGroup),
          _buildValueCell(node.credit, theme, isBold: node.isGroup),
          _buildValueCell(node.balance, theme, isBold: node.isGroup),
        ];
      case ReportDisplayMode.singleBalance:
        return [
          _buildValueCell(node.balance, theme, isBold: node.isGroup),
        ];
    }
  }

  Widget _buildValueCell(double value, ThemeData theme, {bool isBold = false}) {
    double width = widget.displayMode == ReportDisplayMode.generalLedger ? 110 : 140;
    return SizedBox(
      width: width,
      child: Text(
        value == 0 ? '—' : AppFormatters.currency(value),
        textAlign: TextAlign.right,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: (value < 0 && widget.displayMode != ReportDisplayMode.trialBalance) ? Colors.red : null,
        ),
      ),
    );
  }
}
