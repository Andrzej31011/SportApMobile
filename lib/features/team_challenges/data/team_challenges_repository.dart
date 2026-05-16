import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/network/api_client.dart';
import 'package:sport_ap_mobile/core/network/paginated_response.dart';
import 'package:sport_ap_mobile/core/network/response_parser.dart';
import 'package:sport_ap_mobile/core/providers.dart';
import 'package:sport_ap_mobile/features/team_challenges/models/team_challenge_model.dart';

class TeamChallengesRepository {
  TeamChallengesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResponse<TeamChallengeModel>> getChallenges({
    int page = 1,
    int perPage = 15,
  }) {
    return _apiClient.getPaginated<TeamChallengeModel>(
      '/team-challenges',
      TeamChallengeModel.fromJson,
      queryParameters: <String, dynamic>{'page': page, 'per_page': perPage},
    );
  }

  Future<TeamChallengeModel> getChallenge(String id) async {
    final response = await _apiClient.get('/team-challenges/$id');
    final json = ResponseParser.dataMap(response);
    return TeamChallengeModel.fromJson(json);
  }

  Future<void> accept(String id) async {
    await _apiClient.patch('/team-challenges/$id/accept');
  }

  Future<void> reject(String id) async {
    await _apiClient.patch('/team-challenges/$id/reject');
  }

  Future<void> respond({required String id, required String action}) async {
    await _apiClient.patch(
      '/team-challenges/$id/respond',
      data: <String, dynamic>{'action': action},
    );
  }

  Future<void> addComment({
    required String id,
    required String body,
    String? termValue,
  }) async {
    await _apiClient.post(
      '/team-challenges/$id/comments',
      data: <String, dynamic>{'body': body, 'term_value': termValue},
    );
  }

  Future<void> setAvailability({
    required String id,
    required Map<String, String> availability,
  }) async {
    await _apiClient.patch(
      '/team-challenges/$id/availability',
      data: <String, dynamic>{'availability': availability},
    );
  }

  Future<TeamChallengeModel> createChallenge(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.post('/team-challenges', data: payload);
    final json = ResponseParser.dataMap(response);
    return TeamChallengeModel.fromJson(json);
  }
}

final teamChallengesRepositoryProvider = Provider<TeamChallengesRepository>((
  ref,
) {
  return TeamChallengesRepository(ref.watch(apiClientProvider));
});

final teamChallengeDetailProvider =
    FutureProvider.family<TeamChallengeModel, String>((ref, id) {
      return ref.watch(teamChallengesRepositoryProvider).getChallenge(id);
    });
