// lib/core/network/api_exception.dart

import 'package:dio/dio.dart';

/// Structured API Exception wrapper providing human-readable error messages
/// across all network requests.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({required this.message, this.statusCode, this.data});

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message:
              'Connection timed out. Please check your internet connection.',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final resData = error.response?.data;
        String message = 'Server error occurred ($status).';

        if (resData is Map) {
          if (resData['detail'] != null) {
            message = resData['detail'].toString();
          } else if (resData['error'] != null) {
            message = resData['error'].toString();
          } else if (resData['message'] != null) {
            message = resData['message'].toString();
          } else {
            // First entry in errors map
            final firstVal = resData.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              message = firstVal.first.toString();
            } else if (firstVal is String) {
              message = firstVal;
            }
          }
        }
        return ApiException(
          message: message,
          statusCode: status,
          data: resData,
        );
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled.');
      case DioExceptionType.connectionError:
        return const ApiException(
          message:
              'Unable to connect to the server. Please check your internet connection.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Security certificate verification failed.',
        );
      case DioExceptionType.unknown:
        return ApiException(
          message: error.message ?? 'An unexpected error occurred.',
        );
    }
  }

  @override
  String toString() => message;
}
