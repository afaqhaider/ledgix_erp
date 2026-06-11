import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ShiftModel {
  final String id;
  final String companyId;
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShiftModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'startTime': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ShiftModel.fromMap(Map<String, dynamic> map, String id) {
    TimeOfDay parseTime(String time) {
      final parts = time.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return ShiftModel(
      id: id,
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      startTime: parseTime(map['startTime'] ?? '09:00'),
      endTime: parseTime(map['endTime'] ?? '18:00'),
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  ShiftModel copyWith({
    String? name,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? description,
    DateTime? updatedAt,
  }) {
    return ShiftModel(
      id: id,
      companyId: companyId,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
