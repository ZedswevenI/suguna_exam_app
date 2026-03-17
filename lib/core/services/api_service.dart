import 'package:dio/dio.dart';
import 'package:suguna_exam_app/core/constants/app_constants.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.timeout,
        receiveTimeout: AppConstants.timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: body,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<int>> downloadImageBytes(String url) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      if (response.data == null || response.data.toString().isEmpty) {
        return {'success': true};
      }
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true, 'data': response.data};
    } else {
      throw ApiException(
        message: 'An error occurred',
        statusCode: response.statusCode ?? 0,
      );
    }
  }

  ApiException _handleDioError(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final message = error.response?.data?['message'] ?? 'An error occurred';
    return ApiException(message: message, statusCode: statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => message;
}
