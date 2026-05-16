import 'package:dio/dio.dart';
import 'package:sport_ap_mobile/core/models/api_error.dart';
import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.error,
    this.dioException,
  });

  final String message;
  final int? statusCode;
  final ApiError? error;
  final DioException? dioException;

  factory ApiException.fromDio(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final responseMap = JsonUtils.asMap(exception.response?.data);
    final error = responseMap.isEmpty
        ? null
        : ApiError.fromJson(responseMap, status: statusCode);

    final message = _resolveMessage(statusCode, error, exception);

    return ApiException(
      message: message,
      statusCode: statusCode,
      error: error,
      dioException: exception,
    );
  }

  static String _resolveMessage(
    int? statusCode,
    ApiError? error,
    DioException exception,
  ) {
    final backendMessage = error?.message;

    if (backendMessage != null && backendMessage.trim().isNotEmpty) {
      return backendMessage;
    }

    switch (statusCode) {
      case 401:
        return 'Sesja wygasla. Zaloguj sie ponownie.';
      case 403:
        return 'Brak uprawnien do wykonania tej akcji.';
      case 404:
        return 'Nie znaleziono zasobu.';
      case 422:
        return error?.prettyMessage() ?? 'Dane formularza sa nieprawidlowe.';
      case 500:
        return 'Blad serwera. Sprobuj ponownie pozniej.';
      default:
        break;
    }

    if (exception.type == DioExceptionType.connectionError ||
        exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.receiveTimeout) {
      return 'Brak polaczenia z serwerem.';
    }

    return 'Wystapil nieoczekiwany blad.';
  }

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, message: $message)';
  }
}
