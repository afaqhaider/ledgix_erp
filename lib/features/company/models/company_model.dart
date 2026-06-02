import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String companyLegalName;
  final String tradeName;
  final String? companyLogoUrl;
  final String primaryBrandColor;
  final String secondaryBrandColor;
  final String country;
  final String baseCurrency;
  final String? trnVatNumber;
  final String? phone;
  final String? email;
  final String? website;
  final String? address;
  final int financialYearStartMonth;
  final String timezone;
  final DateTime createdAt;
  final String createdByUserId;

  CompanyModel({
    required this.id,
    required this.companyLegalName,
    required this.tradeName,
    this.companyLogoUrl,
    required this.primaryBrandColor,
    required this.secondaryBrandColor,
    required this.country,
    required this.baseCurrency,
    this.trnVatNumber,
    this.phone,
    this.email,
    this.website,
    this.address,
    required this.financialYearStartMonth,
    required this.timezone,
    required this.createdAt,
    required this.createdByUserId,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyModel(
      id: id,
      companyLegalName: map['companyLegalName'] ?? '',
      tradeName: map['tradeName'] ?? '',
      companyLogoUrl: map['companyLogoUrl'],
      primaryBrandColor: map['primaryBrandColor'] ?? '0xFF0F172A',
      secondaryBrandColor: map['secondaryBrandColor'] ?? '0xFF3B82F6',
      country: map['country'] ?? '',
      baseCurrency: map['baseCurrency'] ?? 'USD',
      trnVatNumber: map['trnVatNumber'],
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      address: map['address'],
      financialYearStartMonth: map['financialYearStartMonth'] ?? 1,
      timezone: map['timezone'] ?? 'UTC',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdByUserId: map['createdByUserId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyLegalName': companyLegalName,
      'tradeName': tradeName,
      'companyLogoUrl': companyLogoUrl,
      'primaryBrandColor': primaryBrandColor,
      'secondaryBrandColor': secondaryBrandColor,
      'country': country,
      'baseCurrency': baseCurrency,
      'trnVatNumber': trnVatNumber,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'financialYearStartMonth': financialYearStartMonth,
      'timezone': timezone,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdByUserId': createdByUserId,
    };
  }

  CompanyModel copyWithId(String id) {
    return CompanyModel(
      id: id,
      companyLegalName: companyLegalName,
      tradeName: tradeName,
      companyLogoUrl: companyLogoUrl,
      primaryBrandColor: primaryBrandColor,
      secondaryBrandColor: secondaryBrandColor,
      country: country,
      baseCurrency: baseCurrency,
      trnVatNumber: trnVatNumber,
      phone: phone,
      email: email,
      website: website,
      address: address,
      financialYearStartMonth: financialYearStartMonth,
      timezone: timezone,
      createdAt: createdAt,
      createdByUserId: createdByUserId,
    );
  }

  CompanyModel copyWith({
    String? companyLegalName,
    String? tradeName,
    String? companyLogoUrl,
    String? primaryBrandColor,
    String? secondaryBrandColor,
    String? country,
    String? baseCurrency,
    String? trnVatNumber,
    String? phone,
    String? email,
    String? website,
    String? address,
    int? financialYearStartMonth,
    String? timezone,
  }) {
    return CompanyModel(
      id: id,
      companyLegalName: companyLegalName ?? this.companyLegalName,
      tradeName: tradeName ?? this.tradeName,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      primaryBrandColor: primaryBrandColor ?? this.primaryBrandColor,
      secondaryBrandColor: secondaryBrandColor ?? this.secondaryBrandColor,
      country: country ?? this.country,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      trnVatNumber: trnVatNumber ?? this.trnVatNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      financialYearStartMonth:
          financialYearStartMonth ?? this.financialYearStartMonth,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt,
      createdByUserId: createdByUserId,
    );
  }
}
