/// PDF generation resource.
library;

import '../errors.dart';
import '../http_client.dart';
import '../types.dart';

/// Provides access to the PDF generation API.
class PdfResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates a [PdfResource].
  PdfResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Generates a PDF document.
  ///
  /// [data] contains the PDF generation parameters (content, template,
  /// options, etc.).
  Future<PdfGenerationResult> generate(Map<String, dynamic> data) async {
    if (data.isEmpty) {
      throw const CortexValidationException(
        message: 'Data must not be empty.',
        parameter: 'data',
      );
    }

    final json = await _client.post(
      '$_baseUrl/api/pdf/generate',
      body: data,
      timeout: const Duration(seconds: 120),
    );
    return PdfGenerationResult.fromJson(json);
  }
}
