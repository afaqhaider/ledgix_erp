import 'package:cloud_firestore/cloud_firestore.dart';

enum JobStatus { pending, inProgress, completed, cancelled }

class JobModel {
  final String id;
  final String companyId;
  final String title;
  final String? description;
  final JobStatus status;
  final DateTime createdAt;

  JobModel({
    required this.id,
    required this.companyId,
    required this.title,
    this.description,
    this.status = JobStatus.pending,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'title': title,
      'description': description,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

enum TaskStatus { todo, inProgress, done }

class TaskModel {
  final String id;
  final String companyId;
  final String title;
  final String? assignedToUserId;
  final TaskStatus status;
  final DateTime? dueDate;

  TaskModel({
    required this.id,
    required this.companyId,
    required this.title,
    this.assignedToUserId,
    this.status = TaskStatus.todo,
    this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'title': title,
      'assignedToUserId': assignedToUserId,
      'status': status.name,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    };
  }
}

class ShiftModel {
  final String id;
  final String companyId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;

  ShiftModel({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    };
  }
}
