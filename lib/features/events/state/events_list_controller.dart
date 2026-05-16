import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/models/paginated_list_state.dart';
import 'package:sport_ap_mobile/core/network/api_exception.dart';
import 'package:sport_ap_mobile/features/events/data/events_repository.dart';
import 'package:sport_ap_mobile/features/events/models/event_model.dart';

class EventsListController
    extends StateNotifier<PaginatedListState<EventModel>> {
  EventsListController(this._repository)
    : super(PaginatedListState<EventModel>.initial()) {
    loadInitial();
  }

  final EventsRepository _repository;

  EventFilters _filters = const EventFilters();

  EventFilters get filters => _filters;

  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentPage: 1,
      hasMore: true,
      items: <EventModel>[],
    );

    try {
      final response = await _repository.getEvents(filters: _filters, page: 1);
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
        errorMessage: 'Nie udalo sie pobrac wydarzen.',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      final response = await _repository.getEvents(filters: _filters, page: 1);
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
    if (state.isLoadingMore || !state.hasMore || state.isLoading) {
      return;
    }

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final response = await _repository.getEvents(
        filters: _filters,
        page: nextPage,
      );
      state = state.copyWith(
        isLoadingMore: false,
        items: <EventModel>[...state.items, ...response.data],
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

  Future<void> join(EventModel event) async {
    await _repository.joinEvent(event.id);
    _replaceEvent(event.copyWith(joined: true));
  }

  Future<void> leave(EventModel event) async {
    await _repository.leaveEvent(event.id);
    _replaceEvent(event.copyWith(joined: false));
  }

  void _replaceEvent(EventModel updatedEvent) {
    final updated = state.items
        .map((item) => item.id == updatedEvent.id ? updatedEvent : item)
        .toList();
    state = state.copyWith(items: updated);
  }
}

final eventsListControllerProvider =
    StateNotifierProvider<EventsListController, PaginatedListState<EventModel>>(
      (ref) {
        return EventsListController(ref.watch(eventsRepositoryProvider));
      },
    );
