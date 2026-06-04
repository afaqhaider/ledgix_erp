import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';

class SupplierModel {
  final String id;
  final String companyId;
  final String supplierCode;
  final String supplierName;
  final String? contactPerson;
  final String email;
  final String? phone;
  final String? address;
  final String? country;
  final String? trnVatNumber;
  final double openingBalance;
  final BalanceType openingBalanceType;
  final bool isActive;
  final DateTime createdAt;

  // Portal Access fields
  final bool portalAccessEnabled;
  final List<String> portalUserIds;
  final List<String> invitedEmails;

  SupplierModel({
    required this.id,
    required this.companyId,
    required this.supplierCode,
    required this.supplierName,
    this.contactPerson,
    required this.email,
    this.phone,
    this.address,
    this.country,
    this.trnVatNumber,
    this.openingBalance = 0.0,
    required this.openingBalanceType,
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
      'supplierCode': supplierCode,
      'supplierName': supplierName,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'address': address,
      'country': country,
      'trnVatNumber': trnVatNumber,
      'openingBalance': openingBalance,
      'openingBalanceType': openingBalanceType.name,
      'isActive': isActive,
      'createdAt': createdAt,
      'portalAccessEnabled': portalAccessEnabled,
      'portalUserIds': portalUserIds,
      'invitedEmails': invitedEmails,
    };
  }

  factory SupplierModel.fromMap(Map<String, dynamic> map, String id) {
    return SupplierModel(
      id: id,
      companyId: map['companyId'] ?? '',
      supplierCode: map['supplierCode'] ?? '',
      supplierName: map['supplierName'] ?? '',
      contactPerson: map['contactPerson'],
      email: map['email'] ?? '',
      phone: map['phone'],
      address: map['address'],
      country: map['country'],
      trnVatNumber: map['trnVatNumber'],
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0.0,
      openingBalanceType: BalanceType.values.firstWhere(
        (e) => e.name == map['openingBalanceType'],
        orElse: () => BalanceType.credit,
      ),
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
      other is SupplierModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
