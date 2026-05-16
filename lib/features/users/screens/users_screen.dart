import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_ap_mobile/core/models/paginated_list_state.dart';
import 'package:sport_ap_mobile/core/widgets/app_error_view.dart';
import 'package:sport_ap_mobile/core/widgets/app_loading_view.dart';
import 'package:sport_ap_mobile/core/widgets/empty_state.dart';
import 'package:sport_ap_mobile/features/auth/models/user_model.dart';
import 'package:sport_ap_mobile/features/users/state/users_list_controller.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
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
      ref.read(usersListControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uzytkownicy'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push('/challenges/create'),
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Wyzwij uzytkownika',
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
                hintText: 'Szukaj uzytkownikow...',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                ref.read(usersListControllerProvider.notifier).setSearch(value);
              },
            ),
          ),
          Expanded(child: _buildContent(state)),
        ],
      ),
    );
  }

  Widget _buildContent(PaginatedListState<UserModel> state) {
    if (state.isLoading && state.items.isEmpty) {
      return const AppLoadingView();
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return AppErrorView(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(usersListControllerProvider.notifier).loadInitial(),
      );
    }

    if (state.items.isEmpty) {
      return const EmptyState(message: 'Brak uzytkownikow.');
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(usersListControllerProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final user = state.items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(user.nick),
              subtitle: Text(
                [user.gender, user.birthYear?.toString()]
                    .whereType<String>()
                    .where((item) => item.isNotEmpty)
                    .join(' • '),
              ),
              trailing: IconButton(
                onPressed: () =>
                    context.push('/challenges/create?userId=${user.id}'),
                icon: const Icon(Icons.emoji_events_outlined),
                tooltip: 'Wyzwij',
              ),
              onTap: () => context.push('/users/${user.id}'),
            ),
          );
        },
      ),
    );
  }
}
