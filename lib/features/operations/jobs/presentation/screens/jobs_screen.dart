import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import 'package:ledgixerp/features/operations/jobs/models/job_model.dart';
import 'package:ledgixerp/features/operations/jobs/services/job_service.dart';
import 'package:ledgixerp/features/settings/services/financial_settings_service.dart';
import 'package:ledgixerp/features/settings/models/financial_settings_model.dart';
import 'add_job_pane.dart';

class JobsScreen extends StatefulWidget {
  final AppUser user;
  const JobsScreen({super.key, required this.user});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final _service = JobService();
  final _settingsService = FinancialSettingsService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FinancialSettingsModel>(
      stream: _settingsService.streamSettings(widget.user.companyId!),
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data;
        final enabled = settings?.jobBasedAccountingEnabled ?? true; // Default to true until loaded to avoid flickering

        if (settingsSnapshot.hasData && !enabled) {
          return Scaffold(
            appBar: AppBar(title: const Text('Jobs / Projects')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.work_off_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Job-Based Accounting is disabled', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Enable it in Settings > Financial Settings to use this feature.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Jobs / Projects'),
            actions: [
              if (enabled)
                ElevatedButton.icon(
                  onPressed: () => _showAddJob(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New Job'),
                ),
              const SizedBox(width: 16),
            ],
          ),
          body: StreamBuilder<List<JobModel>>(
            stream: _service.getJobs(widget.user.companyId!),
            builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final jobs = snapshot.data ?? [];
          if (jobs.isEmpty) {
            return const Center(child: Text('No jobs found. Start by creating a new job.'));
          }

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return ListTile(
                title: Text('${job.jobNumber}: ${job.jobName}'),
                subtitle: Text(job.customerName ?? 'No Customer'),
                trailing: _buildStatusChip(job.status),
                onTap: () {
                  // View job details / Ledger
                },
              );
            },
          );
        },
      ),
    );
  },
);
}

  Widget _buildStatusChip(JobStatus status) {
    Color color;
    switch (status) {
      case JobStatus.draft:
        color = Colors.grey;
        break;
      case JobStatus.active:
        color = Colors.green;
        break;
      case JobStatus.completed:
        color = Colors.blue;
        break;
      case JobStatus.cancelled:
        color = Colors.red;
        break;
    }
    return Chip(
      label: Text(status.label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  void _showAddJob(BuildContext context) {
    SidePanel.show(
      context: context,
      title: 'Create New Job',
      child: AddJobPane(user: widget.user),
    );
  }
}
