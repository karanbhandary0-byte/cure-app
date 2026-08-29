import 'package:dio/dio.dart';
import 'session_service.dart';

class ApiService {
  late final Dio _dio;
  final SessionService _sessionService;

  static const String _defaultBaseUrl = "http://localhost:8000";

  ApiService(this._sessionService, {String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: (baseUrl ?? const String.fromEnvironment('EXPO_PUBLIC_BACKEND_URL', defaultValue: _defaultBaseUrl)) + "/api",
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['auth'] != false) {
            final token = await _sessionService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          String detail = "Request failed";
          if (error.response?.data != null) {
            final data = error.response!.data;
            if (data is Map && data.containsKey('detail')) {
              detail = data['detail'].toString();
            } else if (data is String) {
              detail = data;
            }
          } else if (error.message != null && error.message!.isNotEmpty) {
            detail = error.message!;
          }
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: detail,
            ),
          );
        },
      ),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, bool auth = true}) async {
    final response = await _dio.get(
      path,
      queryParameters: queryParameters,
      options: Options(extra: {'auth': auth}),
    );
    return response.data;
  }

  Future<dynamic> post(String path, {dynamic body, bool auth = true}) async {
    final response = await _dio.post(
      path,
      data: body,
      options: Options(extra: {'auth': auth}),
    );
    return response.data;
  }

  Future<dynamic> put(String path, {dynamic body, bool auth = true}) async {
    final response = await _dio.put(
      path,
      data: body,
      options: Options(extra: {'auth': auth}),
    );
    return response.data;
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final response = await _dio.delete(
      path,
      options: Options(extra: {'auth': auth}),
    );
    return response.data;
  }
}
