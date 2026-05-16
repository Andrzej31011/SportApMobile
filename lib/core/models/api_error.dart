import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class ApiError {
  const ApiError({
    this.message,
    this.code,
    this.status,
    this.errors = const <String, List<String>>{},
  });

  final String? message;
  final String? code;
  final int? status;
  final Map<String, List<String>> errors;

  factory ApiError.fromJson(Map<String, dynamic> json, {int? status}) {
    final validationErrors = <String, List<String>>{};
    final errorsRaw = JsonUtils.asMap(json['errors']);

    for (final entry in errorsRaw.entries) {
      validationErrors[entry.key] = JsonUtils.asStringList(entry.value);
    }

    return ApiError(
      message: JsonUtils.asString(json['message']),
      code: JsonUtils.asString(json['code']),
      status: status ?? JsonUtils.asInt(json['status']),
      errors: validationErrors,
    );
  }

  String prettyMessage() {
    if (errors.isEmpty) {
      return message ?? 'Wystapil blad API';
    }

    final lines = <String>[];
    for (final entry in errors.entries) {
      final joined = entry.value.join(', ');
      lines.add('${entry.key}: $joined');
    }
    return lines.join('\n');
  }
}
