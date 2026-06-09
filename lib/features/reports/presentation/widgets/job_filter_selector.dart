import 'package:flutter/material.dart';
import 'package:ledgixerp/features/operations/jobs/models/job_model.dart';
import 'package:ledgixerp/features/operations/jobs/services/job_service.dart';
import 'package:ledgixerp/features/settings/services/financial_settings_service.dart';

class JobFilterSelector extends StatefulWidget {
  final String companyId;
  final String? selectedJobId;
  final Function(String?) onJobSelected;

  const JobFilterSelector({
    super.key,
    required this.companyId,
    this.selectedJobId,
    required this.onJobSelected,
  });

  @override
  State<JobFilterSelector> createState() => _JobFilterSelectorState();
}

class _JobFilterSelectorState extends State<JobFilterSelector> {
  final _settingsService = FinancialSettingsService();
  final _jobService = JobService();
  bool _isEnabled = false;
  List<JobModel> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkEnabledAndLoadJobs();
  }

  Future<void> _checkEnabledAndLoadJobs() async {
    final settings = await _settingsService.getSettings(widget.companyId);
    if (!settings.jobBasedAccountingEnabled) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Listen to active jobs
    _jobService.getActiveJobs(widget.companyId).listen((jobs) {
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _isEnabled = true;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2));
    if (!_isEnabled) return const SizedBox.shrink();

    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      child: DropdownButtonFormField<String?>(
        initialValue: widget.selectedJobId,
        decoration: InputDecoration(
          labelText: 'Filter by Job',
          isDense: true,
          prefixIcon: const Icon(Icons.assignment_outlined, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('All Jobs')),
          ..._jobs.map((job) => DropdownMenuItem(
                value: job.id,
                child: Text('${job.jobNumber}: ${job.jobName}', overflow: TextOverflow.ellipsis),
              )),
        ],
        onChanged: widget.onJobSelected,
      ),
    );
  }
}
