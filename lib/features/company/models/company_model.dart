import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String legalName;
  final String tradeName;
  final String country;
  final String currency;
  final String? trn;
  final int financialYearStartMonth;
  final String ownerId;
  final DateTime createdAt;

  CompanyModel({
    required this.id,
    required this.legalName,
    required this.tradeName,
    required this.country,
    required this.currency,
    this.trn,
    required this.financialYearStartMonth,
    required this.ownerId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'legalName': legalName,
      'tradeName': tradeName,
      'country': country,
      'currency': currency,
      'trn': trn,
      'financialYearStartMonth': financialYearStartMonth,
      'ownerId': ownerId,
      'createdAt': createdAt,
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyModel(
      id: id,
      legalName: map['legalName'] ?? '',
      tradeName: map['tradeName'] ?? '',
      country: map['country'] ?? '',
      currency: map['currency'] ?? '',
      trn: map['trn'],
      financialYearStartMonth: map['financialYearStartMonth'] ?? 1,
      ownerId: map['ownerId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
