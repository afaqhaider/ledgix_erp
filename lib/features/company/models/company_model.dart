import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String companyLegalName;
  final String tradeName;
  final String country;
  final String currency;
  final String? trnVatNumber;
  final int financialYearStartMonth;
  final String? companyLogoUrl;
  final String? primaryBrandColor;
  final DateTime createdAt;
  final String createdByUserId;

  CompanyModel({
    required this.id,
    required this.companyLegalName,
    required this.tradeName,
    required this.country,
    required this.currency,
    this.trnVatNumber,
    required this.financialYearStartMonth,
    this.companyLogoUrl,
    this.primaryBrandColor,
    required this.createdAt,
    required this.createdByUserId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyLegalName': companyLegalName,
      'tradeName': tradeName,
      'country': country,
      'currency': currency,
      'trnVatNumber': trnVatNumber,
      'financialYearStartMonth': financialYearStartMonth,
      'companyLogoUrl': companyLogoUrl,
      'primaryBrandColor': primaryBrandColor,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdByUserId': createdByUserId,
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyModel(
      id: id,
      companyLegalName: map['companyLegalName'] ?? '',
      tradeName: map['tradeName'] ?? '',
      country: map['country'] ?? '',
      currency: map['currency'] ?? '',
      trnVatNumber: map['trnVatNumber'],
      financialYearStartMonth: map['financialYearStartMonth'] ?? 1,
      companyLogoUrl: map['companyLogoUrl'],
      primaryBrandColor: map['primaryBrandColor'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdByUserId: map['createdByUserId'] ?? '',
    );
  }
}
