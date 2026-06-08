class ErpException implements Exception {
  final String message;
  final String title;
  final String? technicalDetails;
  final dynamic originalError;

  ErpException({
    required this.message,
    this.title = 'Error',
    this.technicalDetails,
    this.originalError,
  });

  @override
  String toString() => message;
}
