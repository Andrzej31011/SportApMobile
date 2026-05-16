import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/models/paginated_list_state.dart';
import 'package:sport_ap_mobile/core/network/api_exception.dart';
import 'package:sport_ap_mobile/features/teams/data/teams_repository.dart';
import 'package:sport_ap_mobile/features/teams/models/team_model.dart';

class TeamsListController extends StateNotifier<PaginatedListState<TeamModel>> {
  TeamsListController(this._repository)
    : super(PaginatedListState<TeamModel>.initial()) {
    loadInitial();
  }

  final TeamsRepository _repository;

  TeamFilters _filters = const TeamFilters();

  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      items: <TeamModel>[],
      currentPage: 1,
      hasMore: true,
    );

    try {
      final response = await _repository.getTeams(filters: _filters, page: 1);
      state = state.copyWith(
        isLoading: false,
        items: response.data,
        currentPage: response.meta.currentPage,
        hasMore: response.meta.hasMore,
      );
    } on ApiException catch (exception) {
      state = state.copyWith(isLoading: false, errorMessage: exception.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Nie udalo sie pobrac druzyn.',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      final response = await _repository.getTeams(filters: _filters, page: 1);
      state = state.copyWith(
        isRefreshing: false,
        items: response.data,
        currentPage: response.meta.currentPage,
        hasMore: response.meta.hasMore,
      );
    } on ApiException catch (exception) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: exception.message,
      );
    } catch (_) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: 'Nie udalo sie odswiezyc druzyn.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final response = await _repository.getTeams(
        filters: _filters,
        page: nextPage,
      );

      state = state.copyWith(
        isLoadingMore: false,
        items: <TeamModel>[...state.items, ...response.data],
        currentPage: response.meta.currentPage,
        hasMore: response.meta.hasMore,
      );
    } on ApiException catch (exception) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: exception.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Nie udalo sie pobrac kolejnej strony.',
      );
    }
  }

  Future<void> updateSearch(String search) async {
    _filters = _filters.copyWith(search: search.isEmpty ? null : search);
    await loadInitial();
  }

  Future<void> join(TeamModel team) async {
    await _repository.joinTeam(team.id);
    _replaceTeam(team.copyWith(joined: true));
  }

  Future<void> leave(TeamModel team) async {
    await _repository.leaveTeam(team.id);
    _replaceTeam(team.copyWith(joined: false));
  }

  void _replaceTeam(TeamModel updated) {
    state = state.copyWith(
      items: state.items
          .map((item) => item.id == updated.id ? updated : item)
          .toList(),
    );
  }
}

final teamsListControllerProvider =
    StateNotifierProvider<TeamsListController, PaginatedListState<TeamModel>>((
      ref,
    ) {
      return TeamsListController(ref.watch(teamsRepositoryProvider));
    });
