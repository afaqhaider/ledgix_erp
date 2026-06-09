import 'package:flutter/material.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import '../../models/report_models.dart';
import '../../services/financial_report_service.dart';
import '../widgets/hierarchical_report_row.dart';
import '../widgets/job_filter_selector.dart';
import 'package:ledgixerp/features/settings/services/financial_settings_service.dart';
import 'package:ledgixerp/features/settings/models/financial_settings_model.dart';

import 'package:google_fonts/google_fonts.dart';

class ProfitLossScreen extends StatefulWidget {
  final String companyId;

  const ProfitLossScreen({super.key, required this.companyId});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  final _reportService = FinancialReportService();
  final _settingsService = FinancialSettingsService();
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );
  ProfitLossReport? _report;
  bool _isLoading = true;
  bool _isAllExpanded = false;
  bool _showGroups = false;
  String? _selectedJobId;
  bool _jobEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSettings();
    _loadReport();
  }

  Future<void> _initSettings() async {
    final settings = await _settingsService.getSettings(widget.companyId);
    if (mounted) {
      setState(() {
        _jobEnabled = settings.jobBasedAccountingEnabled;
      });
    }
  }

  String _searchQuery = '';

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final report = await _reportService.getProfitLoss(
        widget.companyId,
        _dateRange.start,
        _dateRange.end,
        showGroups: _showGroups,
        jobId: _selectedJobId,
      );
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading report: $e')));
      }
    }
  }

  List<FinancialReportNode> _getFilteredNodes() {
    if (_report == null) return [];
    if (_searchQuery.isEmpty) return _report!.nodes;

    return _report!.nodes
        .map((node) => _filterNode(node))
        .whereType<FinancialReportNode>()
        .toList();
  }

  FinancialReportNode? _filterNode(FinancialReportNode node) {
    bool matches =
        node.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        node.code.toLowerCase().contains(_searchQuery.toLowerCase());

    List<FinancialReportNode> filteredChildren = node.children
        .map((c) => _filterNode(c))
        .whereType<FinancialReportNode>()
        .toList();

    if (matches || filteredChildren.isNotEmpty) {
      return node.copyWith(children: filteredChildren);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredNodes = _getFilteredNodes();

    return Column(
      children: [
        _buildHeader(theme),
        _buildControls(theme),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (filteredNodes.isEmpty)
          const Expanded(
            child: Center(child: Text('No matching records found')),
          )
        else
          Expanded(
            child: Column(
              children: [
                _buildSummaryBar(theme),
                _buildTableHeader(theme),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredNodes.length,
                    itemBuilder: (context, index) {
                      return HierarchicalReportRow(
                        key: ValueKey(
                          'pl-${filteredNodes[index].id}-$_isAllExpanded-$_searchQuery',
                        ),
                        companyId: widget.companyId,
                        node: filteredNodes[index],
                        displayMode: ReportDisplayMode.singleBalance,
                        initiallyExpanded:
                            _isAllExpanded || _searchQuery.isNotEmpty,
                        jobId: _selectedJobId,
                      );
                    },
                  ),
                ),
                _buildTotalFooter(theme),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          StreamBuilder<FinancialSettingsModel>(
            stream: _settingsService.streamSettings(widget.companyId),
            builder: (context, snapshot) {
              final enabled = snapshot.data?.jobBasedAccountingEnabled ?? _jobEnabled;
              if (!enabled) return const SizedBox.shrink();

              return JobFilterSelector(
                companyId: widget.companyId,
                selectedJobId: _selectedJobId,
                onJobSelected: (jobId) {
                  setState(() => _selectedJobId = jobId);
                  _loadReport();
                },
              );
            },
          ),
          Expanded(
            child: SearchBar(
              hintText: 'Search account or category...',
              leading: const Icon(Icons.search, size: 20),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                theme.colorScheme.surfaceContainer,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 16),
          _buildRangePresets(theme),
        ],
      ),
    );
  }

  Widget _buildRangePresets(ThemeData theme) {
    final now = DateTime.now();
    return Row(
      children: [
        _rangePresetButton(
          'This Month',
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
        ),
        _rangePresetButton(
          'This Year',
          DateTimeRange(start: DateTime(now.year, 1, 1), end: now),
        ),
        _rangePresetButton(
          'Last Month',
          DateTimeRange(
            start: DateTime(now.year, now.month - 1, 1),
            end: DateTime(now.year, now.month, 0),
          ),
        ),
      ],
    );
  }

  Widget _rangePresetButton(String label, DateTimeRange range) {
    final isSelected =
        _dateRange.start == range.start && _dateRange.end == range.end;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _dateRange = range);
            _loadReport();
          }
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profit & Loss',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Income and expenditure statement for a period',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() => _showGroups = !_showGroups);
              _loadReport();
            },
            icon: Icon(_showGroups ? Icons.visibility : Icons.visibility_off),
            label: Text(_showGroups ? 'Hide Groups' : 'Show Groups'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => setState(() => _isAllExpanded = !_isAllExpanded),
            icon: Icon(_isAllExpanded ? Icons.unfold_less : Icons.unfold_more),
            label: Text(_isAllExpanded ? 'Collapse All' : 'Expand All'),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                initialDateRange: _dateRange,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (range != null) {
                setState(() => _dateRange = range);
                _loadReport();
              }
            },
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              '${AppFormatters.date(_dateRange.start)} - ${AppFormatters.date(_dateRange.end)}',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            'Period: ${AppFormatters.date(_dateRange.start)} to ${AppFormatters.date(_dateRange.end)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(52, 12, 24, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'ACCOUNT',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              'AMOUNT',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildSummaryRow(theme, 'TOTAL REVENUE', _report?.totalRevenue ?? 0),
          _buildSummaryRow(
            theme,
            'TOTAL COST OF SALES',
            _report?.totalCostOfSales ?? 0,
          ),
          const Divider(),
          _buildSummaryRow(
            theme,
            'GROSS PROFIT',
            (_report?.totalRevenue ?? 0) - (_report?.totalCostOfSales ?? 0),
            isBold: true,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            theme,
            'TOTAL OPERATING EXPENSES',
            _report?.totalExpenses ?? 0,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(thickness: 2),
          ),
          _buildSummaryRow(
            theme,
            'NET PROFIT / LOSS',
            _report?.netProfit ?? 0,
            isBold: true,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme,
    String label,
    double value, {
    bool isBold = false,
    bool isPrimary = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isPrimary ? 15 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isPrimary ? theme.colorScheme.primary : null,
          ),
        ),
        Text(
          AppFormatters.currency(value),
          style: GoogleFonts.jetBrainsMono(
            fontSize: isPrimary ? 17 : 15,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: isPrimary
                ? theme.colorScheme.primary
                : (value < 0 ? Colors.red : null),
          ),
        ),
      ],
    );
  }
}
