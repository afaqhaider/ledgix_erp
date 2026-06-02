import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { approval, invoice, payment, system }

class NotificationModel {
  final String id;
  final String userId;
  final String companyId;
  final String title;
  final String message;
  final NotificationType type;
  final String? relatedDocId;
  final String? relatedDocType;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedDocId,
    this.relatedDocType,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'companyId': companyId,
      'title': title,
      'message': message,
      'type': type.name,
      'relatedDocId': relatedDocId,
      'relatedDocType': relatedDocType,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      companyId: map['companyId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.system,
      ),
      relatedDocId: map['relatedDocId'],
      relatedDocType: map['relatedDocType'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
