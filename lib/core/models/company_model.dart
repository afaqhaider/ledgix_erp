import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String name;
  final String currencyCode;
  final String currencySymbol;
  final String dateFormat;
  final String? logoUrl;
  final String? taxNumber;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompanyModel({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.currencySymbol,
    required this.dateFormat,
    this.logoUrl,
    this.taxNumber,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CompanyModel(
      id: doc.id,
      name: data['name'] ?? '',
      currencyCode: data['currencyCode'] ?? 'USD',
      currencySymbol: data['currencySymbol'] ?? '\$',
      dateFormat: data['dateFormat'] ?? 'dd-MMM-yyyy',
      logoUrl: data['logoUrl'],
      taxNumber: data['taxNumber'],
      settings: data['settings'] ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'dateFormat': dateFormat,
      'logoUrl': logoUrl,
      'taxNumber': taxNumber,
      'settings': settings,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
