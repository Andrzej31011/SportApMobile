import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_ap_mobile/core/models/paginated_list_state.dart';
import 'package:sport_ap_mobile/core/widgets/app_error_view.dart';
import 'package:sport_ap_mobile/core/widgets/app_loading_view.dart';
import 'package:sport_ap_mobile/core/widgets/empty_state.dart';
import 'package:sport_ap_mobile/features/teams/models/team_model.dart';
import 'package:sport_ap_mobile/features/teams/state/teams_list_controller.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
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
      ref.read(teamsListControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _toggleJoin(TeamModel team) async {
    setState(() => _busyIds.add(team.id));

    try {
      final notifier = ref.read(teamsListControllerProvider.notifier);
      if (team.joined == true) {
        await notifier.leave(team);
      } else {
        await notifier.join(team);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              team.joined == true
                  ? 'Opuszczono druzyne.'
                  : 'Dolaczono do druzyny.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(team.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamsListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Druzyny'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push('/teams/create'),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Utworz druzyne',
          ),
          IconButton(
            onPressed: () => context.push('/team-challenges/create'),
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Wyzwij druzyne',
          ),
          IconButton(
            onPressed: () => context.push('/users'),
            icon: const Icon(Icons.people_outline),
            tooltip: 'Uzytkownicy',
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
                hintText: 'Szukaj druzyn...',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                ref
                    .read(teamsListControllerProvider.notifier)
                    .updateSearch(value.trim());
              },
            ),
          ),
          Expanded(child: _buildContent(state)),
        ],
      ),
    );
  }

  Widget _buildContent(PaginatedListState<TeamModel> state) {
    if (state.isLoading && state.items.isEmpty) {
      return const AppLoadingView();
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return AppErrorView(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(teamsListControllerProvider.notifier).loadInitial(),
      );
    }

    if (state.items.isEmpty) {
      return const EmptyState(message: 'Brak druzyn do wyswietlenia.');
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(teamsListControllerProvider.notifier).refresh(),
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

          final team = state.items[index];
          final isBusy = _busyIds.contains(team.id);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  InkWell(
                    onTap: () => context.push('/teams/${team.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          team.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          team.disciplines.isEmpty
                              ? 'Brak dyscyplin'
                              : team.disciplines.join(', '),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      OutlinedButton(
                        onPressed: () => context.push(
                          '/team-challenges/create?opponentId=${team.id}',
                        ),
                        child: const Text('Wyzwij'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: isBusy ? null : () => _toggleJoin(team),
                        child: isBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(team.joined == true ? 'Opusc' : 'Dolacz'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
