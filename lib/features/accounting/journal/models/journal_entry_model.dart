import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_line_model.dart';

enum JournalStatus { draft, posted, cancelled, reversed }

class JournalEntryModel {
  final String id;
  final String companyId;
  final DateTime date;
  final String reference;
  final String description;
  final List<JournalLineModel> lines;
  final JournalStatus status;
  final String createdBy;
  final DateTime createdAt;

  // Source reference fields
  final String? sourceType;
  final String? sourceId;
  final String? sourceNumber;
  final String? approvalStatus;

  // Header level Job Link (Optional, lines can have different jobs)
  final String? jobId;
  final String? jobNumber;
  final String? jobName;

  JournalEntryModel({
    required this.id,
    required this.companyId,
    required this.date,
    required this.reference,
    required this.description,
    required this.lines,
    this.status = JournalStatus.draft,
    required this.createdBy,
    required this.createdAt,
    this.sourceType,
    this.sourceId,
    this.sourceNumber,
    this.approvalStatus,
    this.jobId,
    this.jobNumber,
    this.jobName,
  });

  JournalEntryModel copyWith({
    String? id,
    String? companyId,
    DateTime? date,
    String? reference,
    String? description,
    List<JournalLineModel>? lines,
    JournalStatus? status,
    String? createdBy,
    DateTime? createdAt,
    String? sourceType,
    String? sourceId,
    String? sourceNumber,
    String? approvalStatus,
    String? jobId,
    String? jobNumber,
    String? jobName,
  }) {
    return JournalEntryModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      date: date ?? this.date,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      lines: lines ?? this.lines,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceNumber: sourceNumber ?? this.sourceNumber,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      jobId: jobId ?? this.jobId,
      jobNumber: jobNumber ?? this.jobNumber,
      jobName: jobName ?? this.jobName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'date': Timestamp.fromDate(date),
      'reference': reference,
      'description': description,
      'lines': lines.map((l) => l.toMap()).toList(),
      'accountIds': lines.map((l) => l.accountId).toSet().toList(),
      'status': status.name,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'sourceType': sourceType,
      'sourceId': sourceId,
      'sourceNumber': sourceNumber,
      'approvalStatus': approvalStatus,
      'jobId': jobId,
      'jobNumber': jobNumber,
      'jobName': jobName,
    };
  }

  factory JournalEntryModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    return JournalEntryModel(
      id: id,
      companyId: map['companyId'] ?? '',
      date: parseDate(map['date']),
      reference: map['reference'] ?? '',
      description: map['description'] ?? '',
      lines: (map['lines'] as List? ?? [])
          .map((l) => JournalLineModel.fromMap(l as Map<String, dynamic>))
          .toList(),
      status: JournalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => JournalStatus.posted,
      ),
      createdBy: map['createdBy'] ?? '',
      createdAt: parseDate(map['createdAt']),
      sourceType: map['sourceType'],
      sourceId: map['sourceId'],
      sourceNumber: map['sourceNumber'],
      approvalStatus: map['approvalStatus'],
      jobId: map['jobId'],
      jobNumber: map['jobNumber'],
      jobName: map['jobName'],
    );
  }
}
