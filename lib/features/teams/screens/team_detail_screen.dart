import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sport_ap_mobile/core/widgets/app_error_view.dart';
import 'package:sport_ap_mobile/core/widgets/app_loading_view.dart';
import 'package:sport_ap_mobile/features/teams/data/teams_repository.dart';
import 'package:sport_ap_mobile/features/teams/state/teams_list_controller.dart';

class TeamDetailScreen extends ConsumerStatefulWidget {
  const TeamDetailScreen({super.key, required this.teamId});

  final String teamId;

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen> {
  bool _busy = false;

  Future<void> _toggleJoin(bool isJoined) async {
    setState(() => _busy = true);

    try {
      final repository = ref.read(teamsRepositoryProvider);
      if (isJoined) {
        await repository.leaveTeam(widget.teamId);
      } else {
        await repository.joinTeam(widget.teamId);
      }

      ref.invalidate(teamDetailProvider(widget.teamId));
      ref.invalidate(teamsListControllerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isJoined ? 'Opuszczono druzyne.' : 'Dolaczono do druzyny.',
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
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncTeam = ref.watch(teamDetailProvider(widget.teamId));

    return Scaffold(
      appBar: AppBar(title: const Text('Szczegoly druzyny')),
      body: asyncTeam.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(teamDetailProvider(widget.teamId)),
        ),
        data: (team) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(teamDetailProvider(widget.teamId)),
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
                        team.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      _row('Opis', team.description ?? '-'),
                      _row(
                        'Data zalozenia',
                        team.establishmentDate == null
                            ? '-'
                            : DateFormat(
                                'dd.MM.yyyy',
                              ).format(team.establishmentDate!.toLocal()),
                      ),
                      _row('Poziom', team.level ?? '-'),
                      _row('Styl', team.style ?? '-'),
                      _row(
                        'Dyscypliny',
                        team.disciplines.isEmpty
                            ? '-'
                            : team.disciplines.join(', '),
                      ),
                      _row('Liczba czlonkow', '${team.membersCount ?? '-'}'),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _toggleJoin(team.joined == true),
                          child: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  team.joined == true
                                      ? 'Opusc druzyne'
                                      : 'Dolacz do druzyny',
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: () => context.push(
                            '/team-challenges/create?opponentId=${team.id}',
                          ),
                          child: const Text('Wyzwij te druzyne'),
                        ),
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
          SizedBox(width: 130, child: Text('$label:')),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
