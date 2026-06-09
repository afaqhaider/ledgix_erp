import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/settings/models/financial_settings_model.dart';
import 'package:ledgixerp/features/operations/jobs/models/job_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getJobsRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('jobs');
  }

  Future<String> generateJobNumber(String companyId) async {
    final settingsDoc = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('settings')
        .doc('financial')
        .get();

    if (!settingsDoc.exists) return 'JOB-00001';

    final settings = FinancialSettingsModel.fromMap(settingsDoc.data()!, companyId);
    final nextNumber = settings.nextJobNumber;
    final prefix = settings.jobPrefix;
    
    return '$prefix-${nextNumber.toString().padLeft(5, '0')}';
  }

  Future<void> createJob(JobModel job) async {
    await _firestore.runTransaction((transaction) async {
      final jobRef = _getJobsRef(job.companyId).doc(job.id);
      transaction.set(jobRef, job.toMap());

      // Increment nextJobNumber in financial settings
      final settingsRef = _firestore
          .collection('companies')
          .doc(job.companyId)
          .collection('settings')
          .doc('financial');
      
      transaction.update(settingsRef, {
        'nextJobNumber': FieldValue.increment(1),
      });
    });
  }

  Future<void> updateJob(JobModel job) async {
    await _getJobsRef(job.companyId).doc(job.id).update(job.toMap());
  }

  Stream<List<JobModel>> getJobs(String companyId) {
    return _getJobsRef(companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<JobModel>> getActiveJobs(String companyId) {
    return _getJobsRef(companyId)
        .where('status', isEqualTo: JobStatus.active.name)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
