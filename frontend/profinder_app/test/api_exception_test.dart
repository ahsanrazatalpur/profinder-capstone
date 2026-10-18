// test/api_exception_test.dart

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/core/network/api_exception.dart';

void main() {
  group('ApiException', () {
    test('formats connection timeout appropriately', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/test/'),
        type: DioExceptionType.connectionTimeout,
      );

      final exception = ApiException.fromDioException(dioError);
      expect(exception.message, contains('Connection timed out'));
      expect(exception.statusCode, 408);
    });

    test('extracts error message from response string', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/test/'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/test/'),
          statusCode: 400,
          data: {'error': 'Invalid credentials provided'},
        ),
        type: DioExceptionType.badResponse,
      );

      final exception = ApiException.fromDioException(dioError);
      expect(exception.message, 'Invalid credentials provided');
      expect(exception.statusCode, 400);
    });

    test('extracts detail field from DRF error format', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/test/'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/test/'),
          statusCode: 404,
          data: {'detail': 'Professional not found'},
        ),
        type: DioExceptionType.badResponse,
      );

      final exception = ApiException.fromDioException(dioError);
      expect(exception.message, 'Professional not found');
      expect(exception.statusCode, 404);
    });

    test('extracts message field if present', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/test/'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/test/'),
          statusCode: 403,
          data: {'message': 'Permission denied'},
        ),
        type: DioExceptionType.badResponse,
      );

      final exception = ApiException.fromDioException(dioError);
      expect(exception.message, 'Permission denied');
      expect(exception.statusCode, 403);
    });

    test('handles fallback when data is null or empty', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/test/'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/test/'),
          statusCode: 500,
          data: null,
        ),
        type: DioExceptionType.badResponse,
      );

      final exception = ApiException.fromDioException(dioError);
      expect(exception.message, contains('Server error occurred (500)'));
      expect(exception.statusCode, 500);
    });

    test('toString returns message', () {
      const ex = ApiException(message: 'Failed to fetch data', statusCode: 401);
      expect(ex.toString(), 'Failed to fetch data');
    });
  });
}
