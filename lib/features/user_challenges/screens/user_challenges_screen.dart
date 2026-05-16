import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_ap_mobile/core/models/paginated_list_state.dart';
import 'package:sport_ap_mobile/core/widgets/app_error_view.dart';
import 'package:sport_ap_mobile/core/widgets/app_loading_view.dart';
import 'package:sport_ap_mobile/core/widgets/empty_state.dart';
import 'package:sport_ap_mobile/features/user_challenges/models/user_challenge_model.dart';
import 'package:sport_ap_mobile/features/user_challenges/state/user_challenges_list_controller.dart';

class UserChallengesScreen extends ConsumerStatefulWidget {
  const UserChallengesScreen({super.key});

  @override
  ConsumerState<UserChallengesScreen> createState() =>
      _UserChallengesScreenState();
}

class _UserChallengesScreenState extends ConsumerState<UserChallengesScreen> {
  final _scrollController = ScrollController();

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
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(userChallengesListControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userChallengesListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wyzwania uzytkownikow'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push('/challenges/create'),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Utworz wyzwanie',
          ),
          IconButton(
            onPressed: () => context.push('/team-challenges'),
            icon: const Icon(Icons.groups_3_outlined),
            tooltip: 'Wyzwania druzynowe',
          ),
        ],
      ),
      body: _buildContent(state),
    );
  }

  Widget _buildContent(PaginatedListState<UserChallengeModel> state) {
    if (state.isLoading && state.items.isEmpty) {
      return const AppLoadingView();
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return AppErrorView(
        message: state.errorMessage!,
        onRetry: () => ref
            .read(userChallengesListControllerProvider.notifier)
            .loadInitial(),
      );
    }

    if (state.items.isEmpty) {
      return const EmptyState(message: 'Brak wyzwan uzytkownikow.');
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(userChallengesListControllerProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final challenge = state.items[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(challenge.discipline ?? 'Wyzwanie ${challenge.id}'),
              subtitle: Text(
                [
                      challenge.status,
                      challenge.challengerNick,
                      challenge.challengedNick,
                    ]
                    .whereType<String>()
                    .where((item) => item.isNotEmpty)
                    .join(' • '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/challenges/${challenge.id}'),
            ),
          );
        },
      ),
    );
  }
}
