import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  todo('Todo'),
  inProgress('In Progress'),
  completed('Completed'),
  cancelled('Cancelled');

  final String label;
  const TaskStatus(this.label);
}

enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  urgent('Urgent');

  final String label;
  const TaskPriority(this.label);
}

class TaskModel {
  final String id;
  final String companyId;
  final String title;
  final String? description;
  final String? jobId;
  final String? jobNumber;
  final String? jobName;
  final String? assignedToId;
  final String? assignedToName;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.companyId,
    required this.title,
    this.description,
    this.jobId,
    this.jobNumber,
    this.jobName,
    this.assignedToId,
    this.assignedToName,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'title': title,
      'description': description,
      'jobId': jobId,
      'jobNumber': jobNumber,
      'jobName': jobName,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
      'status': status.name,
      'priority': priority.name,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      companyId: map['companyId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      jobId: map['jobId'],
      jobNumber: map['jobNumber'],
      jobName: map['jobName'],
      assignedToId: map['assignedToId'],
      assignedToName: map['assignedToName'],
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.todo,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  TaskModel copyWith({
    String? title,
    String? description,
    String? jobId,
    String? jobNumber,
    String? jobName,
    String? assignedToId,
    String? assignedToName,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id,
      companyId: companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      jobId: jobId ?? this.jobId,
      jobNumber: jobNumber ?? this.jobNumber,
      jobName: jobName ?? this.jobName,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
