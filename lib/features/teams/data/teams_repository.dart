import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/network/api_client.dart';
import 'package:sport_ap_mobile/core/network/paginated_response.dart';
import 'package:sport_ap_mobile/core/network/response_parser.dart';
import 'package:sport_ap_mobile/core/providers.dart';
import 'package:sport_ap_mobile/features/teams/models/team_model.dart';

class TeamFilters {
  const TeamFilters({
    this.search,
    this.discipline,
    this.level,
    this.style,
    this.perPage = 15,
  });

  final String? search;
  final String? discipline;
  final String? level;
  final String? style;
  final int perPage;

  Map<String, dynamic> toQueryMap({required int page}) {
    return <String, dynamic>{
      'search': search,
      'discipline': discipline,
      'level': level,
      'style': style,
      'per_page': perPage,
      'page': page,
    };
  }

  TeamFilters copyWith({String? search}) {
    return TeamFilters(
      search: search ?? this.search,
      discipline: discipline,
      level: level,
      style: style,
      perPage: perPage,
    );
  }
}

class TeamsRepository {
  TeamsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResponse<TeamModel>> getTeams({
    TeamFilters filters = const TeamFilters(),
    int page = 1,
  }) {
    return _apiClient.getPaginated<TeamModel>(
      '/teams',
      TeamModel.fromJson,
      queryParameters: filters.toQueryMap(page: page),
    );
  }

  Future<TeamModel> getTeam(String id) async {
    final response = await _apiClient.get('/teams/$id');
    final json = ResponseParser.dataMap(response);
    return TeamModel.fromJson(json);
  }

  Future<void> joinTeam(String id) async {
    await _apiClient.post('/teams/$id/join');
  }

  Future<void> leaveTeam(String id) async {
    await _apiClient.delete('/teams/$id/leave');
  }

  Future<TeamModel> createTeam(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('/teams', data: payload);
    final json = ResponseParser.dataMap(response);
    return TeamModel.fromJson(json);
  }
}

final teamsRepositoryProvider = Provider<TeamsRepository>((ref) {
  return TeamsRepository(ref.watch(apiClientProvider));
});

final teamDetailProvider = FutureProvider.family<TeamModel, String>((ref, id) {
  return ref.watch(teamsRepositoryProvider).getTeam(id);
});
