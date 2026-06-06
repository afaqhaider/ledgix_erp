import 'package:cloud_firestore/cloud_firestore.dart';

class BranchModel {
  final String id;
  final String companyId;
  final String name;
  final String? code;
  final String? phone;
  final String? email;
  final String? address;
  final bool isMainBranch;
  final bool isActive;
  final DateTime createdAt;

  BranchModel({
    required this.id,
    required this.companyId,
    required this.name,
    this.code,
    this.phone,
    this.email,
    this.address,
    this.isMainBranch = false,
    this.isActive = true,
    required this.createdAt,
  });

  factory BranchModel.fromMap(Map<String, dynamic> map, String id) {
    return BranchModel(
      id: id,
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      code: map['code'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      isMainBranch: map['isMainBranch'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'code': code,
      'phone': phone,
      'email': email,
      'address': address,
      'isMainBranch': isMainBranch,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  BranchModel copyWith({
    String? name,
    String? code,
    String? phone,
    String? email,
    String? address,
    bool? isMainBranch,
    bool? isActive,
  }) {
    return BranchModel(
      id: id,
      companyId: companyId,
      name: name ?? this.name,
      code: code ?? this.code,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      isMainBranch: isMainBranch ?? this.isMainBranch,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
