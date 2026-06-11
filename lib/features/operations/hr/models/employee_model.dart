import 'package:cloud_firestore/cloud_firestore.dart';

enum EmployeeStatus {
  active('Active'),
  inactive('Inactive');

  final String label;
  const EmployeeStatus(this.label);
}

class EmployeeModel {
  final String id;
  final String companyId;
  final String employeeNumber; // Auto-generated ID
  final String name;
  final String mobileNumber;
  final String email;
  final String department;
  final String designation;
  final DateTime dateJoined;
  final EmployeeStatus status;
  final String? profilePhotoUrl;
  final String? shiftId;
  final String? shiftName;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmployeeModel({
    required this.id,
    required this.companyId,
    required this.employeeNumber,
    required this.name,
    required this.mobileNumber,
    required this.email,
    required this.department,
    required this.designation,
    required this.dateJoined,
    this.status = EmployeeStatus.active,
    this.profilePhotoUrl,
    this.shiftId,
    this.shiftName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'employeeNumber': employeeNumber,
      'name': name,
      'mobileNumber': mobileNumber,
      'email': email,
      'department': department,
      'designation': designation,
      'dateJoined': Timestamp.fromDate(dateJoined),
      'status': status.name,
      'profilePhotoUrl': profilePhotoUrl,
      'shiftId': shiftId,
      'shiftName': shiftName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    return EmployeeModel(
      id: id,
      companyId: map['companyId'] ?? '',
      employeeNumber: map['employeeNumber'] ?? '',
      name: map['name'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      email: map['email'] ?? '',
      department: map['department'] ?? '',
      designation: map['designation'] ?? '',
      dateJoined: parseDate(map['dateJoined']),
      status: EmployeeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => EmployeeStatus.active,
      ),
      profilePhotoUrl: map['profilePhotoUrl'],
      shiftId: map['shiftId'],
      shiftName: map['shiftName'],
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  EmployeeModel copyWith({
    String? id,
    String? companyId,
    String? employeeNumber,
    String? name,
    String? mobileNumber,
    String? email,
    String? department,
    String? designation,
    DateTime? dateJoined,
    EmployeeStatus? status,
    String? profilePhotoUrl,
    String? shiftId,
    String? shiftName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      dateJoined: dateJoined ?? this.dateJoined,
      status: status ?? this.status,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      shiftId: shiftId ?? this.shiftId,
      shiftName: shiftName ?? this.shiftName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
