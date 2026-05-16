import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/network/api_client.dart';
import 'package:sport_ap_mobile/core/network/paginated_response.dart';
import 'package:sport_ap_mobile/core/network/response_parser.dart';
import 'package:sport_ap_mobile/core/providers.dart';
import 'package:sport_ap_mobile/features/user_challenges/models/user_challenge_model.dart';

class UserChallengesRepository {
  UserChallengesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResponse<UserChallengeModel>> getChallenges({
    int page = 1,
    int perPage = 15,
  }) {
    return _apiClient.getPaginated<UserChallengeModel>(
      '/user-challenges',
      UserChallengeModel.fromJson,
      queryParameters: <String, dynamic>{'page': page, 'per_page': perPage},
    );
  }

  Future<UserChallengeModel> getChallenge(String id) async {
    final response = await _apiClient.get('/user-challenges/$id');
    final json = ResponseParser.dataMap(response);
    return UserChallengeModel.fromJson(json);
  }

  Future<void> accept(String id) async {
    await _apiClient.patch('/user-challenges/$id/accept');
  }

  Future<void> reject(String id) async {
    await _apiClient.patch('/user-challenges/$id/reject');
  }

  Future<void> addComment({
    required String id,
    required String body,
    String? termId,
  }) async {
    await _apiClient.post(
      '/user-challenges/$id/comments',
      data: <String, dynamic>{'body': body, 'term_id': termId},
    );
  }

  Future<void> selectTerm({required String id, required String termId}) async {
    await _apiClient.patch(
      '/user-challenges/$id/proposed-terms/$termId/select',
    );
  }

  Future<void> addTerms({
    required String id,
    required List<Map<String, dynamic>> terms,
  }) async {
    await _apiClient.post(
      '/user-challenges/$id/proposed-terms',
      data: <String, dynamic>{'terms': terms},
    );
  }

  Future<UserChallengeModel> createChallenge(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.post('/user-challenges', data: payload);
    final json = ResponseParser.dataMap(response);
    return UserChallengeModel.fromJson(json);
  }
}

final userChallengesRepositoryProvider = Provider<UserChallengesRepository>((
  ref,
) {
  return UserChallengesRepository(ref.watch(apiClientProvider));
});

final userChallengeDetailProvider =
    FutureProvider.family<UserChallengeModel, String>((ref, id) {
      return ref.watch(userChallengesRepositoryProvider).getChallenge(id);
    });
