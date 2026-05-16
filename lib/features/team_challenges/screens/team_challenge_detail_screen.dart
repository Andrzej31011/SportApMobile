import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sport_ap_mobile/core/widgets/app_error_view.dart';
import 'package:sport_ap_mobile/core/widgets/app_loading_view.dart';
import 'package:sport_ap_mobile/features/team_challenges/data/team_challenges_repository.dart';
import 'package:sport_ap_mobile/features/team_challenges/models/team_challenge_model.dart';
import 'package:sport_ap_mobile/features/team_challenges/state/team_challenges_list_controller.dart';

class TeamChallengeDetailScreen extends ConsumerStatefulWidget {
  const TeamChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  ConsumerState<TeamChallengeDetailScreen> createState() =>
      _TeamChallengeDetailScreenState();
}

class _TeamChallengeDetailScreenState
    extends ConsumerState<TeamChallengeDetailScreen> {
  bool _busy = false;

  Future<void> _runAction(
    Future<void> Function() callback,
    String successMsg,
  ) async {
    setState(() => _busy = true);

    try {
      await callback();
      ref.invalidate(teamChallengeDetailProvider(widget.challengeId));
      ref.invalidate(teamChallengesListControllerProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMsg)));
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
    final asyncChallenge = ref.watch(
      teamChallengeDetailProvider(widget.challengeId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Szczegoly wyzwania druzynowego')),
      body: asyncChallenge.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(teamChallengeDetailProvider(widget.challengeId)),
        ),
        data: (challenge) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(teamChallengeDetailProvider(widget.challengeId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _buildMainCard(context, challenge),
              const SizedBox(height: 12),
              _buildDatesCard(context, challenge),
              const SizedBox(height: 12),
              _buildCommentsCard(context, challenge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, TeamChallengeModel challenge) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${challenge.teamName ?? '-'} vs ${challenge.opponentName ?? '-'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _row('Status', challenge.status ?? '-'),
            _row('Lokalizacja', challenge.location ?? '-'),
            _row('Wiadomosc', challenge.message ?? '-'),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _runAction(
                            () => ref
                                .read(teamChallengesRepositoryProvider)
                                .accept(widget.challengeId),
                            'Wyzwanie zaakceptowane.',
                          ),
                    child: const Text('Akceptuj'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _runAction(
                            () => ref
                                .read(teamChallengesRepositoryProvider)
                                .reject(widget.challengeId),
                            'Wyzwanie odrzucone.',
                          ),
                    child: const Text('Odrzuc'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _runAction(
                            () => ref
                                .read(teamChallengesRepositoryProvider)
                                .respond(
                                  id: widget.challengeId,
                                  action: 'accept',
                                ),
                            'Odpowiedz wyslana.',
                          ),
                    child: const Text('Respond: accept'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _runAction(
                            () => ref
                                .read(teamChallengesRepositoryProvider)
                                .respond(
                                  id: widget.challengeId,
                                  action: 'reject',
                                ),
                            'Odpowiedz wyslana.',
                          ),
                    child: const Text('Respond: reject'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _showCommentDialog(context, challenge),
              child: const Text('Dodaj komentarz'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesCard(BuildContext context, TeamChallengeModel challenge) {
    final formatter = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Proponowane daty',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (challenge.proposedDates.isEmpty)
              const Text('Brak proponowanych dat.')
            else
              ...challenge.proposedDates.map(
                (date) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatter.format(date.toLocal())),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: challenge.proposedDates.isEmpty || _busy
                  ? null
                  : () => _showAvailabilityDialog(context, challenge),
              child: const Text('Glosuj dostepnosc'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsCard(
    BuildContext context,
    TeamChallengeModel challenge,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Komentarze', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (challenge.comments.isEmpty)
              const Text('Brak komentarzy.')
            else
              ...challenge.comments.map(
                (comment) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(comment.author ?? 'Uzytkownik'),
                  subtitle: Text(comment.body ?? ''),
                  trailing: Text(
                    comment.createdAt == null
                        ? ''
                        : DateFormat(
                            'dd.MM HH:mm',
                          ).format(comment.createdAt!.toLocal()),
                  ),
                ),
              ),
          ],
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
          SizedBox(width: 110, child: Text('$label:')),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _showCommentDialog(
    BuildContext context,
    TeamChallengeModel challenge,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    String? selectedTerm;

    final termValues = challenge.proposedDates
        .map((date) => date.toUtc().toIso8601String())
        .toList();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Komentarz do wyzwania'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (termValues.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: selectedTerm,
                    decoration: const InputDecoration(labelText: 'Termin'),
                    items: termValues
                        .map(
                          (term) => DropdownMenuItem<String>(
                            value: term,
                            child: Text(term),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      selectedTerm = value;
                    },
                  ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Komentarz'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Wpisz komentarz';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(context).pop();
                _runAction(
                  () => ref
                      .read(teamChallengesRepositoryProvider)
                      .addComment(
                        id: widget.challengeId,
                        body: controller.text.trim(),
                        termValue: selectedTerm,
                      ),
                  'Komentarz dodany.',
                );
              },
              child: const Text('Dodaj'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAvailabilityDialog(
    BuildContext context,
    TeamChallengeModel challenge,
  ) async {
    final availability = <String, String>{};
    final formatter = DateFormat('dd.MM.yyyy HH:mm');

    for (final date in challenge.proposedDates) {
      availability[date.toUtc().toIso8601String()] = 'available';
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Dostepnosc terminow'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    children: challenge.proposedDates.map((date) {
                      final key = date.toUtc().toIso8601String();
                      return DropdownButtonFormField<String>(
                        initialValue: availability[key],
                        decoration: InputDecoration(
                          labelText: formatter.format(date.toLocal()),
                        ),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(
                            value: 'available',
                            child: Text('available'),
                          ),
                          DropdownMenuItem(
                            value: 'unavailable',
                            child: Text('unavailable'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            availability[key] = value;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Anuluj'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _runAction(
                      () => ref
                          .read(teamChallengesRepositoryProvider)
                          .setAvailability(
                            id: widget.challengeId,
                            availability: availability,
                          ),
                      'Dostepnosc zapisana.',
                    );
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
