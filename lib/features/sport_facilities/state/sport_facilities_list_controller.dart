import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/models/paginated_list_state.dart';
import 'package:sport_ap_mobile/core/network/api_exception.dart';
import 'package:sport_ap_mobile/features/sport_facilities/data/sport_facilities_repository.dart';
import 'package:sport_ap_mobile/features/sport_facilities/models/sport_facility_model.dart';

class SportFacilitiesListController
    extends StateNotifier<PaginatedListState<SportFacilityModel>> {
  SportFacilitiesListController(this._repository)
    : super(PaginatedListState<SportFacilityModel>.initial()) {
    loadInitial();
  }

  final SportFacilitiesRepository _repository;

  SportFacilityFilters _filters = const SportFacilityFilters();

  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      items: <SportFacilityModel>[],
      currentPage: 1,
      hasMore: true,
    );

    try {
      final response = await _repository.getFacilities(filters: _filters);
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
        errorMessage: 'Nie udalo sie pobrac obiektow.',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      final response = await _repository.getFacilities(filters: _filters);
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
      final response = await _repository.getFacilities(
        filters: _filters,
        page: nextPage,
      );

      state = state.copyWith(
        isLoadingMore: false,
        items: <SportFacilityModel>[...state.items, ...response.data],
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
}

final sportFacilitiesListControllerProvider =
    StateNotifierProvider<
      SportFacilitiesListController,
      PaginatedListState<SportFacilityModel>
    >((ref) {
      return SportFacilitiesListController(
        ref.watch(sportFacilitiesRepositoryProvider),
      );
    });
