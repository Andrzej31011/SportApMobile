import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/models/paginated_list_state.dart';
import 'package:sport_ap_mobile/core/network/api_exception.dart';
import 'package:sport_ap_mobile/features/auth/models/user_model.dart';
import 'package:sport_ap_mobile/features/users/data/users_repository.dart';

class UsersListController extends StateNotifier<PaginatedListState<UserModel>> {
  UsersListController(this._repository)
    : super(PaginatedListState<UserModel>.initial()) {
    loadInitial();
  }

  final UsersRepository _repository;

  String? _search;

  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      items: <UserModel>[],
      currentPage: 1,
      hasMore: true,
    );

    try {
      final response = await _repository.getUsers(search: _search);
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
        errorMessage: 'Nie udalo sie pobrac uzytkownikow.',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      final response = await _repository.getUsers(search: _search);
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
      final response = await _repository.getUsers(
        search: _search,
        page: nextPage,
      );
      state = state.copyWith(
        isLoadingMore: false,
        items: <UserModel>[...state.items, ...response.data],
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

  Future<void> setSearch(String? value) async {
    _search = (value == null || value.trim().isEmpty) ? null : value.trim();
    await loadInitial();
  }
}

final usersListControllerProvider =
    StateNotifierProvider<UsersListController, PaginatedListState<UserModel>>((
      ref,
    ) {
      return UsersListController(ref.watch(usersRepositoryProvider));
    });
