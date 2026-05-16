import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/network/api_client.dart';
import 'package:sport_ap_mobile/core/network/response_parser.dart';
import 'package:sport_ap_mobile/core/providers.dart';
import 'package:sport_ap_mobile/features/auth/models/user_model.dart';

class ProfileRepository {
  ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get('/profile');
    final json = ResponseParser.dataMap(response);
    return UserModel.fromJson(json);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> payload) async {
    final response = await _apiClient.put('/profile', data: payload);
    final json = ResponseParser.dataMap(response);
    return UserModel.fromJson(json);
  }

  Future<UserModel> patchUser(Map<String, dynamic> payload) async {
    final response = await _apiClient.patch('/user', data: payload);
    final json = ResponseParser.dataMap(response);
    return UserModel.fromJson(json);
  }

  Future<UserModel> updateLocation({
    required double latitude,
    required double longitude,
    required int radiusKm,
    required String locationName,
  }) async {
    final response = await _apiClient.patch(
      '/profile/location',
      data: <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
        'location_name': locationName,
      },
    );

    final json = ResponseParser.dataMap(response);
    return UserModel.fromJson(json);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});
