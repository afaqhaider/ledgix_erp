import 'package:flutter/material.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import '../../models/report_models.dart';
import '../../services/financial_report_service.dart';
import '../widgets/hierarchical_report_row.dart';
import '../widgets/job_filter_selector.dart';
import 'package:ledgixerp/features/settings/services/financial_settings_service.dart';
import 'package:ledgixerp/features/settings/models/financial_settings_model.dart';

import 'package:google_fonts/google_fonts.dart';

class BalanceSheetScreen extends StatefulWidget {
  final String companyId;

  const BalanceSheetScreen({super.key, required this.companyId});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
  final _reportService = FinancialReportService();
  final _settingsService = FinancialSettingsService();
  DateTime _asOfDate = DateTime.now();
  BalanceSheetReport? _report;
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
      final report = await _reportService.getBalanceSheet(
        widget.companyId,
        _asOfDate,
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
                          'bs-${filteredNodes[index].id}-$_isAllExpanded-$_searchQuery',
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
              hintText: 'Search asset, liability or equity...',
              leading: const Icon(Icons.search, size: 20),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                theme.colorScheme.surfaceContainer,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 16),
          _buildDatePresets(theme),
        ],
      ),
    );
  }

  Widget _buildDatePresets(ThemeData theme) {
    return Row(
      children: [
        _presetButton('Today', DateTime.now()),
        _presetButton(
          'Last Month',
          DateTime(DateTime.now().year, DateTime.now().month, 0),
        ),
        _presetButton('Last Year', DateTime(DateTime.now().year, 1, 0)),
      ],
    );
  }

  Widget _presetButton(String label, DateTime date) {
    final isSelected = DateUtils.isSameDay(_asOfDate, date);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _asOfDate = date);
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
                  'Balance Sheet',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Snapshot of financial position as of a specific date',
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
              final date = await showDatePicker(
                context: context,
                initialDate: _asOfDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                setState(() => _asOfDate = date);
                _loadReport();
              }
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(AppFormatters.date(_asOfDate)),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'As of: ${AppFormatters.date(_asOfDate)}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          if (_report != null)
            Row(
              children: [
                if (!_report!.isBalanced)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'OUT OF BALANCE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Text(
                  'Difference: ${AppFormatters.currency((_report!.totalAssets - (_report!.totalLiabilities + _report!.totalEquity)).abs())}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _report!.isBalanced ? Colors.green : Colors.red,
                  ),
                ),
              ],
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
              'BALANCE',
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
          _buildSummaryRow(
            theme,
            'TOTAL ASSETS',
            _report?.totalAssets ?? 0,
            isBold: true,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            theme,
            'TOTAL LIABILITIES',
            _report?.totalLiabilities ?? 0,
          ),
          _buildSummaryRow(theme, 'TOTAL EQUITY', _report?.totalEquity ?? 0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          _buildSummaryRow(
            theme,
            'TOTAL LIABILITIES & EQUITY',
            (_report?.totalLiabilities ?? 0) + (_report?.totalEquity ?? 0),
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
            color: isPrimary ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
