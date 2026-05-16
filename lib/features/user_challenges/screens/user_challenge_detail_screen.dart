import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sport_ap_mobile/core/widgets/app_error_view.dart';
import 'package:sport_ap_mobile/core/widgets/app_loading_view.dart';
import 'package:sport_ap_mobile/features/user_challenges/data/user_challenges_repository.dart';
import 'package:sport_ap_mobile/features/user_challenges/models/user_challenge_model.dart';
import 'package:sport_ap_mobile/features/user_challenges/state/user_challenges_list_controller.dart';

class UserChallengeDetailScreen extends ConsumerStatefulWidget {
  const UserChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  ConsumerState<UserChallengeDetailScreen> createState() =>
      _UserChallengeDetailScreenState();
}

class _UserChallengeDetailScreenState
    extends ConsumerState<UserChallengeDetailScreen> {
  bool _busy = false;

  Future<void> _runAction(
    Future<void> Function() callback,
    String successMsg,
  ) async {
    setState(() => _busy = true);

    try {
      await callback();
      ref.invalidate(userChallengeDetailProvider(widget.challengeId));
      ref.invalidate(userChallengesListControllerProvider);

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
      userChallengeDetailProvider(widget.challengeId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Szczegoly wyzwania')),
      body: asyncChallenge.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(userChallengeDetailProvider(widget.challengeId)),
        ),
        data: (challenge) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(userChallengeDetailProvider(widget.challengeId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _buildMainCard(context, challenge),
              const SizedBox(height: 12),
              _buildTermsCard(context, challenge),
              const SizedBox(height: 12),
              _buildCommentsCard(context, challenge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, UserChallengeModel challenge) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              challenge.discipline ?? 'Wyzwanie',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _row('Status', challenge.status ?? '-'),
            _row('Wzywajacy', challenge.challengerNick ?? '-'),
            _row('Wzywany', challenge.challengedNick ?? '-'),
            _row('Lokalizacja', challenge.locationName ?? '-'),
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
                                .read(userChallengesRepositoryProvider)
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
                                .read(userChallengesRepositoryProvider)
                                .reject(widget.challengeId),
                            'Wyzwanie odrzucone.',
                          ),
                    child: const Text('Odrzuc'),
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

  Widget _buildTermsCard(BuildContext context, UserChallengeModel challenge) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Terminy', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (challenge.terms.isEmpty)
              const Text('Brak propozycji terminow.')
            else
              ...challenge.terms.map(
                (term) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_formatTerm(term)),
                  subtitle: Text(term.note ?? ''),
                  trailing: FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _runAction(
                            () => ref
                                .read(userChallengesRepositoryProvider)
                                .selectTerm(
                                  id: widget.challengeId,
                                  termId: term.id,
                                ),
                            'Termin wybrany.',
                          ),
                    child: Text(term.selected == true ? 'Wybrany' : 'Wybierz'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsCard(
    BuildContext context,
    UserChallengeModel challenge,
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

  String _formatTerm(UserChallengeTerm term) {
    final format = DateFormat('dd.MM.yyyy HH:mm');
    final start = term.startsAt == null
        ? '-'
        : format.format(term.startsAt!.toLocal());
    final end = term.endsAt == null
        ? '-'
        : format.format(term.endsAt!.toLocal());
    return '$start - $end';
  }

  Future<void> _showCommentDialog(
    BuildContext context,
    UserChallengeModel challenge,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    String? selectedTermId;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dodaj komentarz'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (challenge.terms.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    initialValue: selectedTermId,
                    decoration: const InputDecoration(
                      labelText: 'Termin (opcjonalnie)',
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Brak'),
                      ),
                      ...challenge.terms.map(
                        (term) => DropdownMenuItem<String?>(
                          value: term.id,
                          child: Text(_formatTerm(term)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      selectedTermId = value;
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
                      .read(userChallengesRepositoryProvider)
                      .addComment(
                        id: widget.challengeId,
                        body: controller.text.trim(),
                        termId: selectedTermId,
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
}
