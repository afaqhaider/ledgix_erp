import 'package:flutter/material.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Financial period updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Period')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _activePeriodController,
            decoration: const InputDecoration(
              labelText: 'Active Accounting Period (YYYY-MM)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Lock Past Periods'),
            value: _settings.lockPastPeriods,
            onChanged: (val) => setState(() => _settings = _settings.copyWith(lockPastPeriods: val)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
