import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/models/paginated_list_state.dart';
import 'package:sport_ap_mobile/core/network/api_exception.dart';
import 'package:sport_ap_mobile/features/team_challenges/data/team_challenges_repository.dart';
import 'package:sport_ap_mobile/features/team_challenges/models/team_challenge_model.dart';

class TeamChallengesListController
    extends StateNotifier<PaginatedListState<TeamChallengeModel>> {
  TeamChallengesListController(this._repository)
    : super(PaginatedListState<TeamChallengeModel>.initial()) {
    loadInitial();
  }

  final TeamChallengesRepository _repository;

  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      items: <TeamChallengeModel>[],
      currentPage: 1,
      hasMore: true,
    );

    try {
      final response = await _repository.getChallenges();
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
        errorMessage: 'Nie udalo sie pobrac wyzwan druzynowych.',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      final response = await _repository.getChallenges();
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
        errorMessage: 'Nie udalo sie odswiezyc listy.',
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
      final response = await _repository.getChallenges(page: nextPage);
      state = state.copyWith(
        isLoadingMore: false,
        items: <TeamChallengeModel>[...state.items, ...response.data],
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
}

final teamChallengesListControllerProvider =
    StateNotifierProvider<
      TeamChallengesListController,
      PaginatedListState<TeamChallengeModel>
    >((ref) {
      return TeamChallengesListController(
        ref.watch(teamChallengesRepositoryProvider),
      );
    });
