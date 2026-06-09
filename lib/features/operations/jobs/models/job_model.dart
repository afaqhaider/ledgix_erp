import 'package:cloud_firestore/cloud_firestore.dart';

enum JobStatus {
  draft('Draft'),
  active('Active'),
  completed('Completed'),
  cancelled('Cancelled');

  final String label;
  const JobStatus(this.label);
}

class JobModel {
  final String id;
  final String companyId;
  final String jobNumber;
  final String jobName;
  final String? customerId;
  final String? customerName;
  final DateTime startDate;
  final DateTime? expectedEndDate;
  final JobStatus status;
  final double expectedRevenue;
  final double expectedCost;
  final double expectedProfitLoss;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  JobModel({
    required this.id,
    required this.companyId,
    required this.jobNumber,
    required this.jobName,
    this.customerId,
    this.customerName,
    required this.startDate,
    this.expectedEndDate,
    this.status = JobStatus.draft,
    this.expectedRevenue = 0.0,
    this.expectedCost = 0.0,
    this.expectedProfitLoss = 0.0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'jobNumber': jobNumber,
      'jobName': jobName,
      'customerId': customerId,
      'customerName': customerName,
      'startDate': Timestamp.fromDate(startDate),
      'expectedEndDate': expectedEndDate != null ? Timestamp.fromDate(expectedEndDate!) : null,
      'status': status.name,
      'expectedRevenue': expectedRevenue,
      'expectedCost': expectedCost,
      'expectedProfitLoss': expectedProfitLoss,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  factory JobModel.fromMap(Map<String, dynamic> map, String id) {
    return JobModel(
      id: id,
      companyId: map['companyId'] ?? '',
      jobNumber: map['jobNumber'] ?? '',
      jobName: map['jobName'] ?? '',
      customerId: map['customerId'],
      customerName: map['customerName'],
      startDate: (map['startDate'] as Timestamp).toDate(),
      expectedEndDate: (map['expectedEndDate'] as Timestamp?)?.toDate(),
      status: JobStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => JobStatus.draft,
      ),
      expectedRevenue: (map['expectedRevenue'] as num?)?.toDouble() ?? 0.0,
      expectedCost: (map['expectedCost'] as num?)?.toDouble() ?? 0.0,
      expectedProfitLoss: (map['expectedProfitLoss'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  JobModel copyWith({
    String? jobName,
    String? customerId,
    String? customerName,
    DateTime? startDate,
    DateTime? expectedEndDate,
    JobStatus? status,
    double? expectedRevenue,
    double? expectedCost,
    double? expectedProfitLoss,
    String? notes,
    DateTime? updatedAt,
  }) {
    return JobModel(
      id: id,
      companyId: companyId,
      jobNumber: jobNumber,
      jobName: jobName ?? this.jobName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      startDate: startDate ?? this.startDate,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      status: status ?? this.status,
      expectedRevenue: expectedRevenue ?? this.expectedRevenue,
      expectedCost: expectedCost ?? this.expectedCost,
      expectedProfitLoss: expectedProfitLoss ?? this.expectedProfitLoss,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
    );
  }
}
