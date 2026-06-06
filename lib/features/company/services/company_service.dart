import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../accounting/chart_of_accounts/account_service.dart';
import '../../settings/services/financial_settings_service.dart';
import '../models/company_model.dart';

class CompanyService {
  static final CompanyService _instance = CompanyService._internal();
  factory CompanyService() => _instance;
  CompanyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Map<String, String> _resolvedLogoUrlCache = {};

  Future<String> setupCompany(CompanyModel company) async {
    final companyRef = _firestore.collection('companies').doc();
    final companyId = companyRef.id;

    debugPrint('CompanyService: [1/4] Creating company doc: $companyId');
    try {
      await companyRef.set(company.toMap());
    } catch (e) {
      debugPrint('CompanyService: FAILED at step 1: $e');
      rethrow;
    }

    debugPrint('CompanyService: [2/4] Initializing financial settings...');
    try {
      await FinancialSettingsService().getSettings(companyId);
    } catch (e) {
      debugPrint('CompanyService: Warning at step 2 (Settings): $e');
      // We don't rethrow here so the user isn't blocked if just settings fail
    }

    debugPrint('CompanyService: [3/4] Seeding default accounts...');
    try {
      await AccountService().seedDefaultAccounts(companyId);
    } catch (e) {
      debugPrint('CompanyService: Warning at step 3 (COA): $e');
    }

    debugPrint(
      'CompanyService: [4/4] Updating user profile: ${company.createdByUserId}',
    );
    try {
      final userRef = _firestore
          .collection('users')
          .doc(company.createdByUserId);
      await userRef.set({
        'companyId': companyId,
        'companyName': company.tradeName,
        'role': 'owner',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('CompanyService: FAILED at step 4 (User Update): $e');
      rethrow;
    }

    debugPrint('CompanyService: SETUP SUCCESSFUL');
    return companyId;
  }

  Future<void> updateCompany(CompanyModel company) async {
    debugPrint(
      'CompanyService: Updating company ${company.id}; logo=${company.companyLogoUrl ?? '(none)'}',
    );
    await _firestore
        .collection('companies')
        .doc(company.id)
        .update(company.toMap());
  }

  Future<String?> resolveLogoUrl(String? logoUrl) async {
    if (logoUrl == null) return null;
    
    // 1. Clean the input URL: trim and remove newlines/carriage returns
    final cleanedInput = logoUrl.trim().replaceAll(RegExp(r'[\n\r]'), '');
    if (cleanedInput.isEmpty) return null;

    if (kDebugMode) {
      debugPrint('CompanyService.resolveLogoUrl: Input length: ${logoUrl.length}');
      debugPrint('CompanyService.resolveLogoUrl: Cleaned input length: ${cleanedInput.length}');
    }

    final cachedUrl = _resolvedLogoUrlCache[cleanedInput];
    if (cachedUrl != null) {
      return cachedUrl;
    }

    // 2. If it is already a full Firebase Storage download URL, return it directly
    if (cleanedInput.startsWith('https://firebasestorage.googleapis.com')) {
      if (kDebugMode) {
        debugPrint('CompanyService: Using direct Firebase Storage URL.');
        debugPrint('CompanyService: Final URL length: ${cleanedInput.length}');
      }
      _resolvedLogoUrlCache[cleanedInput] = cleanedInput;
      return cleanedInput;
    }

    // 3. If it starts with http/https but NOT Firebase Storage, just return it after cleaning
    if (cleanedInput.startsWith('http://') || cleanedInput.startsWith('https://')) {
      _resolvedLogoUrlCache[cleanedInput] = cleanedInput;
      return cleanedInput;
    }

    try {
      debugPrint('CompanyService: Resolving storage path: $cleanedInput');
      late final String resolvedUrl;
      if (cleanedInput.startsWith('gs://')) {
        resolvedUrl = await _storage.refFromURL(cleanedInput).getDownloadURL();
      } else {
        resolvedUrl = await _storage.ref().child(cleanedInput).getDownloadURL();
      }

      // Clean the resulting download URL as well
      final finalUrl = resolvedUrl.trim().replaceAll(RegExp(r'[\n\r]'), '');
      
      if (kDebugMode) {
        debugPrint('CompanyService: Resolved URL length: ${resolvedUrl.length}');
        debugPrint('CompanyService: Final cleaned URL length: ${finalUrl.length}');
      }

      _resolvedLogoUrlCache[cleanedInput] = finalUrl;
      return finalUrl;
    } catch (e) {
      debugPrint('Error resolving logo URL: $e');
      return null;
    }
  }

  Future<String> uploadLogo(
    String companyId,
    Object? file, {
    String? fileName,
    String? contentType,
  }) async {
    try {
      if (file == null) {
        throw ArgumentError('No logo file was selected.');
      }

      final extension = _logoExtension(fileName, contentType);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = _storage.ref().child(
        'companies/$companyId/branding/logo_$timestamp.$extension',
      );
      final metadata = SettableMetadata(
        contentType: contentType ?? _contentTypeForExtension(extension),
        cacheControl: 'public,max-age=60',
      );

      late final UploadTask uploadTask;
      if (kIsWeb) {
        if (file is! Uint8List) {
          throw ArgumentError('Logo upload data is not available.');
        }
        uploadTask = storageRef.putData(file, metadata);
      } else {
        if (file is! File) {
          throw ArgumentError('Logo file is not available.');
        }
        uploadTask = storageRef.putFile(file, metadata);
      }
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Clean the URL: remove any potential whitespaces or newlines
      final cleanUrl = downloadUrl.trim().replaceAll(RegExp(r'[\n\r]'), '');
      
      if (kDebugMode) {
        debugPrint('CompanyService: Original URL length: ${downloadUrl.length}');
        debugPrint('CompanyService: Cleaned URL length: ${cleanUrl.length}');
        debugPrint('CompanyService: Cleaned URL: $cleanUrl');
      }

      _resolvedLogoUrlCache[snapshot.ref.fullPath] = cleanUrl;
      _resolvedLogoUrlCache[cleanUrl] = cleanUrl;
      
      debugPrint(
        'CompanyService: Logo uploaded successfully: ${snapshot.ref.fullPath}',
      );
      return cleanUrl;
    } catch (e) {
      debugPrint('Error uploading logo: $e');
      throw Exception('Could not upload the company logo. Please try again.');
    }
  }

  String _logoExtension(String? fileName, String? contentType) {
    final lowerName = fileName?.toLowerCase() ?? '';
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      return 'jpg';
    }
    if (lowerName.endsWith('.webp')) return 'webp';
    if (lowerName.endsWith('.gif')) return 'gif';
    if (contentType == 'image/jpeg') return 'jpg';
    if (contentType == 'image/webp') return 'webp';
    if (contentType == 'image/gif') return 'gif';
    return 'png';
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'jpg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/png';
    }
  }

  Stream<CompanyModel?> getCompany(String companyId) {
    return _firestore.collection('companies').doc(companyId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return CompanyModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }
}
