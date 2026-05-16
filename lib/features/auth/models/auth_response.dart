import 'package:sport_ap_mobile/core/utils/json_utils.dart';
import 'package:sport_ap_mobile/features/auth/models/user_model.dart';

class AuthResponse {
  const AuthResponse({required this.token, required this.user});

  final String token;
  final UserModel user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = JsonUtils.asMap(json['data']);
    final source = data.isNotEmpty ? data : json;

    final token =
        JsonUtils.asString(source['token']) ??
        JsonUtils.asString(source['access_token']) ??
        '';

    final userMap = JsonUtils.asMap(source['user']);

    return AuthResponse(token: token, user: UserModel.fromJson(userMap));
  }
}
