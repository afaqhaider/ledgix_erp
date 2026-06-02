import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_line_model.dart';

enum JournalStatus { draft, posted, cancelled }

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

  JournalEntryModel({
    required this.id,
    required this.companyId,
    required this.date,
    required this.reference,
    required this.description,
    required this.lines,
    this.status = JournalStatus.posted,
    required this.createdBy,
    required this.createdAt,
    this.sourceType,
    this.sourceId,
    this.sourceNumber,
    this.approvalStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'date': date,
      'reference': reference,
      'description': description,
      'lines': lines.map((l) => l.toMap()).toList(),
      'status': status.name,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'sourceNumber': sourceNumber,
      'approvalStatus': approvalStatus,
    };
  }

  factory JournalEntryModel.fromMap(Map<String, dynamic> map, String id) {
    return JournalEntryModel(
      id: id,
      companyId: map['companyId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      reference: map['reference'] ?? '',
      description: map['description'] ?? '',
      lines: (map['lines'] as List)
          .map((l) => JournalLineModel.fromMap(l as Map<String, dynamic>))
          .toList(),
      status: JournalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => JournalStatus.posted,
      ),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      sourceType: map['sourceType'],
      sourceId: map['sourceId'],
      sourceNumber: map['sourceNumber'],
      approvalStatus: map['approvalStatus'],
    );
  }
}
