import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sport_ap_mobile/core/models/paginated_list_state.dart';
import 'package:sport_ap_mobile/core/widgets/app_error_view.dart';
import 'package:sport_ap_mobile/core/widgets/app_loading_view.dart';
import 'package:sport_ap_mobile/core/widgets/empty_state.dart';
import 'package:sport_ap_mobile/features/events/models/event_model.dart';
import 'package:sport_ap_mobile/features/events/state/events_list_controller.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _busyIds = <String>{};

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
      ref.read(eventsListControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _toggleJoin(EventModel event) async {
    setState(() => _busyIds.add(event.id));
    try {
      final notifier = ref.read(eventsListControllerProvider.notifier);
      if (event.joined == true) {
        await notifier.leave(event);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opuszczono wydarzenie.')),
          );
        }
      } else {
        await notifier.join(event);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dolaczono do wydarzenia.')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(event.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wydarzenia'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push('/events/create'),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Utworz wydarzenie',
          ),
          IconButton(
            onPressed: () => context.push('/facilities'),
            icon: const Icon(Icons.sports_soccer_outlined),
            tooltip: 'Obiekty sportowe',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Szukaj wydarzen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          ref
                              .read(eventsListControllerProvider.notifier)
                              .updateSearch('');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: (value) {
                ref
                    .read(eventsListControllerProvider.notifier)
                    .updateSearch(value.trim());
              },
            ),
          ),
          Expanded(child: _buildContent(state)),
        ],
      ),
    );
  }

  Widget _buildContent(PaginatedListState<EventModel> state) {
    if (state.isLoading && state.items.isEmpty) {
      return const AppLoadingView();
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return AppErrorView(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(eventsListControllerProvider.notifier).loadInitial(),
      );
    }

    if (state.items.isEmpty) {
      return const EmptyState(message: 'Brak wydarzen do wyswietlenia.');
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(eventsListControllerProvider.notifier).refresh(),
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

          final event = state.items[index];
          final isBusy = _busyIds.contains(event.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/events/${event.id}'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      event.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subtitle(event),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonal(
                        onPressed: isBusy ? null : () => _toggleJoin(event),
                        child: isBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(event.joined == true ? 'Opusc' : 'Dolacz'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _subtitle(EventModel event) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final parts = <String>[];

    if (event.disciplineName != null && event.disciplineName!.isNotEmpty) {
      parts.add(event.disciplineName!);
    }
    if (event.city != null && event.city!.isNotEmpty) {
      parts.add(event.city!);
    }
    if (event.startTime != null) {
      parts.add(dateFormat.format(event.startTime!.toLocal()));
    }

    return parts.isEmpty ? 'Brak szczegolow' : parts.join(' • ');
  }
}
