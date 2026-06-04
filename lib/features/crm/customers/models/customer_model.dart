import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String companyId;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? taxNumber;
  final bool isActive;
  final DateTime createdAt;

  // Portal Access fields
  final bool portalAccessEnabled;
  final List<String> portalUserIds;
  final List<String> invitedEmails;

  CustomerModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.taxNumber,
    this.isActive = true,
    required this.createdAt,
    this.portalAccessEnabled = false,
    this.portalUserIds = const [],
    this.invitedEmails = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'taxNumber': taxNumber,
      'isActive': isActive,
      'createdAt': createdAt,
      'portalAccessEnabled': portalAccessEnabled,
      'portalUserIds': portalUserIds,
      'invitedEmails': invitedEmails,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map, String id) {
    return CustomerModel(
      id: id,
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      address: map['address'],
      taxNumber: map['taxNumber'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      portalAccessEnabled: map['portalAccessEnabled'] ?? false,
      portalUserIds: List<String>.from(map['portalUserIds'] ?? []),
      invitedEmails: List<String>.from(map['invitedEmails'] ?? []),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
