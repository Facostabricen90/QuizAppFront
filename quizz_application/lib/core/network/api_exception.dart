import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.hasResponseDetails = false,
  });

  final String message;
  final int? statusCode;
  final bool hasResponseDetails;

  factory ApiException.fromResponse(http.Response response) {
    final messages = <String>[];

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];

        if (errors is List) {
          messages.addAll(errors.map((error) => error.toString()));
        } else if (errors is Map) {
          for (final value in errors.values) {
            if (value is List) {
              messages.addAll(value.map((error) => error.toString()));
            } else {
              messages.add(value.toString());
            }
          }
        }

        final message = decoded['message'] ?? decoded['title'];
        if (message is String && message.isNotEmpty) {
          messages.add(message);
        }
      }
    } on FormatException {
      // La API puede responder sin JSON en errores de red/proxy.
    }

    return ApiException(
      statusCode: response.statusCode,
      hasResponseDetails: messages.isNotEmpty,
      message: messages.isEmpty
          ? _fallbackMessage(response.statusCode)
          : messages.toSet().join('\n'),
    );
  }

  static String _fallbackMessage(int statusCode) {
    if (statusCode >= 500) {
      return 'El servidor no pudo procesar la solicitud ($statusCode) y no '
          'devolvió detalles del error.';
    }

    return 'La API rechazó la solicitud ($statusCode) sin indicar la causa.';
  }

  @override
  String toString() => message;
}
