import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/attachment_model.dart';

class AttachmentService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<List<AttachmentModel>> pickAndUploadFiles({
    required String companyId,
    required String folder, // e.g., 'bills', 'invoices'
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      List<AttachmentModel> attachments = [];
      for (var file in result.files) {
        final attachment = await uploadFile(
          companyId: companyId,
          folder: folder,
          file: file,
        );
        if (attachment != null) {
          attachments.add(attachment);
        }
      }
      return attachments;
    }
    return [];
  }

  Future<AttachmentModel?> uploadFile({
    required String companyId,
    required String folder,
    required PlatformFile file,
    Function(double)? onProgress,
  }) async {
    try {
      final id = _uuid.v4();
      final extension = file.extension ?? 'bin';
      final fileName = '$id.$extension';
      final filePath = 'companies/$companyId/$folder/$fileName';
      final ref = _storage.ref().child(filePath);

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(file.bytes!);
      } else {
        uploadTask = ref.putFile(File(file.path!));
      }

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (onProgress != null) onProgress(progress);
      });

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      // Perform OCR if it's an image or PDF
      Map<String, dynamic>? ocrData;
      if (['jpg', 'jpeg', 'png', 'pdf'].contains(extension.toLowerCase())) {
        ocrData = await performOCR(url);
      }

      return AttachmentModel(
        id: id,
        name: file.name,
        url: url,
        type: extension,
        uploadedAt: DateTime.now(),
        ocrData: ocrData,
      );
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> performOCR(String url) async {
    try {
      // Mock OCR API call
      await Future.delayed(const Duration(seconds: 2));
      return {
        'extractedText': 'Sample extracted text from OCR',
        'confidence': 0.95,
        'detectedDate': DateTime.now().toIso8601String(),
        'amount': 1250.50,
      };
    } catch (e) {
      debugPrint('OCR Error: $e');
      return null;
    }
  }

  Future<void> deleteAttachment(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting attachment: $e');
    }
  }
}
