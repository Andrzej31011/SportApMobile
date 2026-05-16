import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_ap_mobile/core/widgets/app_error_view.dart';
import 'package:sport_ap_mobile/core/widgets/app_loading_view.dart';
import 'package:sport_ap_mobile/features/users/data/users_repository.dart';

class UserDetailScreen extends ConsumerWidget {
  const UserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(userDetailProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Szczegoly uzytkownika')),
      body: asyncUser.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(userDetailProvider(userId)),
        ),
        data: (user) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(userDetailProvider(userId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user.nick,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      _row('ID', user.id),
                      _row('Plec', user.gender ?? '-'),
                      _row('Rok urodzenia', user.birthYear?.toString() ?? '-'),
                      _row('Lokalizacja', user.locationName ?? '-'),
                      _row('Avatar', user.avatarUrl ?? '-'),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: () => context.push(
                          '/challenges/create?userId=${user.id}',
                        ),
                        child: const Text('Wyzwij uzytkownika'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 120, child: Text('$label:')),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
