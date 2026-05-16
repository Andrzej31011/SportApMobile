import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_ap_mobile/core/models/paginated_list_state.dart';
import 'package:sport_ap_mobile/core/widgets/app_error_view.dart';
import 'package:sport_ap_mobile/core/widgets/app_loading_view.dart';
import 'package:sport_ap_mobile/core/widgets/empty_state.dart';
import 'package:sport_ap_mobile/features/sport_facilities/models/sport_facility_model.dart';
import 'package:sport_ap_mobile/features/sport_facilities/state/sport_facilities_list_controller.dart';

class SportFacilitiesScreen extends ConsumerStatefulWidget {
  const SportFacilitiesScreen({super.key});

  @override
  ConsumerState<SportFacilitiesScreen> createState() =>
      _SportFacilitiesScreenState();
}

class _SportFacilitiesScreenState extends ConsumerState<SportFacilitiesScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(sportFacilitiesListControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sportFacilitiesListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obiekty sportowe'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push('/facilities/create'),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Dodaj obiekt',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Szukaj obiektow...',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                ref
                    .read(sportFacilitiesListControllerProvider.notifier)
                    .updateSearch(value.trim());
              },
            ),
          ),
          Expanded(child: _buildContent(state)),
        ],
      ),
    );
  }

  Widget _buildContent(PaginatedListState<SportFacilityModel> state) {
    if (state.isLoading && state.items.isEmpty) {
      return const AppLoadingView();
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return AppErrorView(
        message: state.errorMessage!,
        onRetry: () => ref
            .read(sportFacilitiesListControllerProvider.notifier)
            .loadInitial(),
      );
    }

    if (state.items.isEmpty) {
      return const EmptyState(message: 'Brak obiektow sportowych.');
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(sportFacilitiesListControllerProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final facility = state.items[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () => context.push('/facilities/${facility.id}'),
              title: Text(facility.name),
              subtitle: Text(
                [
                  if ((facility.city ?? '').isNotEmpty) facility.city!,
                  if ((facility.address ?? '').isNotEmpty) facility.address!,
                ].join(' • '),
              ),
            ),
          );
        },
      ),
    );
  }
}
