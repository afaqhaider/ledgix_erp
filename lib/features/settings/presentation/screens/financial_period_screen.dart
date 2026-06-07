import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ledgixerp/widgets/form_layout.dart';
import '../../../../core/auth/app_user.dart';
import '../../models/financial_settings_model.dart';
import '../../services/financial_settings_service.dart';

class FinancialPeriodScreen extends StatefulWidget {
  final AppUser user;
  const FinancialPeriodScreen({super.key, required this.user});

  @override
  State<FinancialPeriodScreen> createState() => _FinancialPeriodScreenState();
}

class _FinancialPeriodScreenState extends State<FinancialPeriodScreen> {
  final _service = FinancialSettingsService();
  bool _isLoading = true;
  late FinancialSettingsModel _settings;
  final _activePeriodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _service.getSettings(widget.user.companyId!);
    if (mounted) {
      setState(() {
        _settings = settings;
        _activePeriodController.text = settings.activeAccountingPeriod;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final updated = _settings.copyWith(
      activeAccountingPeriod: _activePeriodController.text,
    );
    await _service.updateSettings(updated);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Financial period updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        _buildHeader(theme),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              FormLayout(
                maxWidth: 600,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _activePeriodController,
                      decoration: const InputDecoration(
                        labelText: 'Active Accounting Period (YYYY-MM)',
                        helperText: 'e.g., 2024-03',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: SwitchListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: const Text('Lock Past Periods', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Transactions cannot be posted to closed months'),
                        value: _settings.lockPastPeriods,
                        onChanged: (val) => setState(
                          () => _settings = _settings.copyWith(lockPastPeriods: val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Period Settings'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
                  'Financial Period',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Manage active and locked accounting periods',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
