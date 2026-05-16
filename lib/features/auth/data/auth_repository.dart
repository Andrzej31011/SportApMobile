import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/network/api_client.dart';
import 'package:sport_ap_mobile/core/network/response_parser.dart';
import 'package:sport_ap_mobile/core/providers.dart';
import 'package:sport_ap_mobile/core/utils/json_utils.dart';
import 'package:sport_ap_mobile/features/auth/models/auth_response.dart';
import 'package:sport_ap_mobile/features/auth/models/user_model.dart';

class RegisterPayload {
  const RegisterPayload({
    required this.nick,
    required this.gender,
    required this.birthYear,
    required this.password,
    required this.passwordConfirmation,
    required this.marketingConsent,
    required this.gdprConsent,
    required this.regulationsConsent,
  });

  final String nick;
  final String gender;
  final int birthYear;
  final String password;
  final String passwordConfirmation;
  final bool marketingConsent;
  final bool gdprConsent;
  final bool regulationsConsent;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nick': nick,
      'gender': gender,
      'birth_year': birthYear,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'marketing_consent': marketingConsent,
      'gdpr_consent': gdprConsent,
      'regulations_consent': regulationsConsent,
    };
  }
}

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthResponse> login({
    required String nick,
    required String password,
    String deviceName = 'Flutter',
  }) async {
    final response = await _apiClient.post(
      '/login',
      data: <String, dynamic>{
        'nick': nick,
        'password': password,
        'device_name': deviceName,
      },
      skipAuthHandling: true,
    );

    return AuthResponse.fromJson(JsonUtils.asMap(response));
  }

  Future<AuthResponse> register(RegisterPayload payload) async {
    final response = await _apiClient.post(
      '/register',
      data: payload.toJson(),
      skipAuthHandling: true,
    );

    return AuthResponse.fromJson(JsonUtils.asMap(response));
  }

  Future<void> logout() async {
    await _apiClient.post('/logout');
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get('/user');
    final json = ResponseParser.dataMap(response);
    return UserModel.fromJson(json);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
