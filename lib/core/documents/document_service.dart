import 'package:ledgixerp/core/documents/document_header.dart';
import 'package:ledgixerp/core/documents/document_status.dart';

abstract class DocumentService {
  Future<String> getNextDocumentNumber(String companyId, DocumentType type);
  
  Future<void> createDocument(DocumentHeader header);
  
  Future<void> updateDocument(DocumentHeader header);
  
  Future<void> updateStatus(String documentId, DocumentStatus status, String userId);
  
  Future<DocumentHeader?> getDocument(String documentId);
  
  Future<List<DocumentHeader>> getDocuments({
    required String companyId,
    DocumentType? type,
    DocumentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<void> deleteDocument(String documentId);

  // PDF Generation interface
  Future<void> generatePdf(DocumentHeader header);

  // Approval Integration
  Future<void> submitForApproval(String documentId, String userId);
}
