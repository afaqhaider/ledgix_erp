import 'package:cloud_firestore/cloud_firestore.dart';

class AttachmentModel {
  final String id;
  final String name;
  final String url;
  final String type;
  final DateTime uploadedAt;
  final Map<String, dynamic>? ocrData;

  AttachmentModel({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.uploadedAt,
    this.ocrData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'ocrData': ocrData,
    };
  }

  factory AttachmentModel.fromMap(Map<String, dynamic> map) {
    return AttachmentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      type: map['type'] ?? '',
      uploadedAt: map['uploadedAt'] != null
          ? (map['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
      ocrData: map['ocrData'],
    );
  }
}
