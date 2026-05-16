import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sport_ap_mobile/core/config/api_config.dart';
import 'package:sport_ap_mobile/core/network/api_exception.dart';
import 'package:sport_ap_mobile/core/network/paginated_response.dart';
import 'package:sport_ap_mobile/core/storage/token_storage.dart';
import 'package:sport_ap_mobile/core/utils/json_utils.dart';

typedef UnauthorizedHandler = Future<void> Function();

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    required UnauthorizedHandler onUnauthorized,
    Dio? dio,
  }) : _tokenStorage = tokenStorage,
       _onUnauthorized = onUnauthorized,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: ApiConfig.baseUrl,
               headers: <String, dynamic>{
                 'Accept': 'application/json',
                 'Content-Type': 'application/json',
               },
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 30),
               sendTimeout: const Duration(seconds: 15),
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final UnauthorizedHandler _onUnauthorized;

  bool _isHandlingUnauthorized = false;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readToken();
    if (token != null && token.trim().isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    options.path = _normalizePath(options.path);
    options.queryParameters =
        _withoutNullValues(options.queryParameters) ?? <String, dynamic>{};

    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final skipAuthHandling =
        err.requestOptions.extra['skipAuthHandling'] == true;

    if (statusCode == 401 && !skipAuthHandling) {
      await _handleUnauthorized();
    }

    _logApiError(err);

    handler.next(err);
  }

  Future<void> _handleUnauthorized() async {
    if (_isHandlingUnauthorized) {
      return;
    }

    _isHandlingUnauthorized = true;
    try {
      await _onUnauthorized();
    } finally {
      _isHandlingUnauthorized = false;
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool skipAuthHandling = false,
  }) async {
    return _request(
      () => _dio.get<dynamic>(
        _normalizePath(path),
        queryParameters: _withoutNullValues(queryParameters),
        options: Options(
          extra: <String, dynamic>{'skipAuthHandling': skipAuthHandling},
        ),
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool skipAuthHandling = false,
  }) async {
    return _request(
      () => _dio.post<dynamic>(
        _normalizePath(path),
        data: data,
        queryParameters: _withoutNullValues(queryParameters),
        options: Options(
          extra: <String, dynamic>{'skipAuthHandling': skipAuthHandling},
        ),
      ),
    );
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool skipAuthHandling = false,
  }) async {
    return _request(
      () => _dio.put<dynamic>(
        _normalizePath(path),
        data: data,
        queryParameters: _withoutNullValues(queryParameters),
        options: Options(
          extra: <String, dynamic>{'skipAuthHandling': skipAuthHandling},
        ),
      ),
    );
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool skipAuthHandling = false,
  }) async {
    return _request(
      () => _dio.patch<dynamic>(
        _normalizePath(path),
        data: data,
        queryParameters: _withoutNullValues(queryParameters),
        options: Options(
          extra: <String, dynamic>{'skipAuthHandling': skipAuthHandling},
        ),
      ),
    );
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool skipAuthHandling = false,
  }) async {
    return _request(
      () => _dio.delete<dynamic>(
        _normalizePath(path),
        data: data,
        queryParameters: _withoutNullValues(queryParameters),
        options: Options(
          extra: <String, dynamic>{'skipAuthHandling': skipAuthHandling},
        ),
      ),
    );
  }

  Future<PaginatedResponse<T>> getPaginated<T>(
    String path,
    T Function(Map<String, dynamic>) parser, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await get(path, queryParameters: queryParameters);
    return PaginatedResponse.fromJson(JsonUtils.asMap(response), parser);
  }

  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await get(path, queryParameters: queryParameters);
    return JsonUtils.asMap(response);
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await get(path, queryParameters: queryParameters);
    return JsonUtils.asList(response);
  }

  Future<dynamic> _request(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  String _normalizePath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    if (path.startsWith('/')) {
      return path.substring(1);
    }

    return path;
  }

  Map<String, dynamic>? _withoutNullValues(Map<String, dynamic>? map) {
    if (map == null) {
      return null;
    }

    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.value != null) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  void _logApiError(DioException error) {
    if (!kDebugMode) {
      return;
    }

    final request = error.requestOptions;
    final status = error.response?.statusCode;
    final responseData = error.response?.data;
    final responsePreview = _shorten(responseData);
    final requestData = _shorten(request.data);

    debugPrint(
      '[API ERROR] ${request.method} ${request.uri} '
      'status=$status type=${error.type}',
    );
    if (requestData.isNotEmpty) {
      debugPrint('[API ERROR] request: $requestData');
    }
    if (responsePreview.isNotEmpty) {
      debugPrint('[API ERROR] response: $responsePreview');
    }
  }

  String _shorten(dynamic value) {
    if (value == null) {
      return '';
    }

    final raw = value.toString().replaceAll('\n', ' ');
    if (raw.length <= 600) {
      return raw;
    }
    return '${raw.substring(0, 600)}...';
  }
}
