import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sport_ap_mobile/core/network/api_exception.dart';
import 'package:sport_ap_mobile/features/common/state/lookup_providers.dart';
import 'package:sport_ap_mobile/features/sport_facilities/models/sport_facility_model.dart';
import 'package:sport_ap_mobile/features/team_challenges/data/team_challenges_repository.dart';
import 'package:sport_ap_mobile/features/team_challenges/state/team_challenges_list_controller.dart';
import 'package:sport_ap_mobile/features/teams/models/team_model.dart';

class CreateTeamChallengeScreen extends ConsumerStatefulWidget {
  const CreateTeamChallengeScreen({super.key, this.initialOpponentId});

  final String? initialOpponentId;

  @override
  ConsumerState<CreateTeamChallengeScreen> createState() =>
      _CreateTeamChallengeScreenState();
}

class _CreateTeamChallengeScreenState
    extends ConsumerState<CreateTeamChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedTeamId;
  String? _selectedOpponentId;
  String? _selectedFacilityId;
  final List<DateTime> _proposedDates = <DateTime>[];

  bool _isSaving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _selectedOpponentId = widget.initialOpponentId;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(teamsLookupProvider).value ?? const <TeamModel>[];
    final facilities =
        ref.watch(sportFacilitiesLookupProvider).value ??
        const <SportFacilityModel>[];

    final myTeams = teams.where((team) => team.joined == true).toList();
    final teamOptions = myTeams.isNotEmpty ? myTeams : teams;

    if (_selectedTeamId == null && teamOptions.isNotEmpty) {
      _selectedTeamId = teamOptions.first.id;
    }

    final opponentOptions = teams
        .where((team) => team.id != _selectedTeamId)
        .toList();

    if (_selectedOpponentId != null &&
        !opponentOptions.any((team) => team.id == _selectedOpponentId)) {
      _selectedOpponentId = null;
    }

    if (_selectedOpponentId == null && opponentOptions.isNotEmpty) {
      _selectedOpponentId = opponentOptions.first.id;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Wyzwij druzyne')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          initialValue: _selectedTeamId,
                          decoration: const InputDecoration(
                            labelText: 'Moja druzyna',
                          ),
                          items: teamOptions
                              .map(
                                (team) => DropdownMenuItem<String>(
                                  value: team.id,
                                  child: Text(team.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTeamId = value;
                            });
                          },
                          validator: (_) {
                            if (_selectedTeamId == null) {
                              return 'Wybierz druzyne';
                            }
                            return null;
                          },
                        ),
                        if (myTeams.isEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          const Text(
                            'Brak jednoznacznie wykrytych "moich" druzyn. Pokazano wszystkie druzyny.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedOpponentId,
                          decoration: const InputDecoration(
                            labelText: 'Druzyna przeciwna',
                          ),
                          items: opponentOptions
                              .map(
                                (team) => DropdownMenuItem<String>(
                                  value: team.id,
                                  child: Text(team.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedOpponentId = value;
                            });
                          },
                          validator: (_) {
                            if (_selectedOpponentId == null) {
                              return 'Wybierz druzyne przeciwna';
                            }
                            if (_selectedOpponentId == _selectedTeamId) {
                              return 'Druzyny musza byc rozne';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedFacilityId,
                          decoration: const InputDecoration(
                            labelText: 'Obiekt sportowy (opcjonalnie)',
                          ),
                          items: facilities
                              .map(
                                (facility) => DropdownMenuItem<String>(
                                  value: facility.id,
                                  child: Text(facility.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedFacilityId = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Lokalizacja (gdy brak obiektu)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Wiadomosc',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Podaj wiadomosc';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              'Proponowane daty',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () async {
                                final picked = await _pickDateTime();
                                if (picked != null) {
                                  setState(() => _proposedDates.add(picked));
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Dodaj date'),
                            ),
                          ],
                        ),
                        if (_proposedDates.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text('Dodaj co najmniej jeden termin.'),
                          )
                        else
                          ..._proposedDates.asMap().entries.map(
                            (entry) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                DateFormat(
                                  'dd.MM.yyyy HH:mm',
                                ).format(entry.value.toLocal()),
                              ),
                              trailing: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _proposedDates.removeAt(entry.key);
                                  });
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_submitError != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _submitError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Utworz wyzwanie druzynowe'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTeamId == null || _selectedOpponentId == null) {
      setState(() => _submitError = 'Wybierz druzyne i przeciwnika.');
      return;
    }

    if (_selectedTeamId == _selectedOpponentId) {
      setState(() => _submitError = 'Druzyny musza byc rozne.');
      return;
    }

    if (_selectedFacilityId == null &&
        _locationController.text.trim().isEmpty) {
      setState(() {
        _submitError = 'Podaj obiekt sportowy albo wpisz nazwe lokalizacji.';
      });
      return;
    }

    if (_proposedDates.isEmpty) {
      setState(
        () => _submitError = 'Dodaj co najmniej jedna proponowana date.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      SportFacilityModel? selectedFacility;
      final facilities = ref.read(sportFacilitiesLookupProvider).value;
      if (facilities != null) {
        for (final facility in facilities) {
          if (facility.id == _selectedFacilityId) {
            selectedFacility = facility;
            break;
          }
        }
      }
      final locationName = _locationController.text.trim().isEmpty
          ? selectedFacility?.name
          : _locationController.text.trim();

      final created = await ref
          .read(teamChallengesRepositoryProvider)
          .createChallenge(<String, dynamic>{
            'team_id': _selectedTeamId,
            'opponent_id': _selectedOpponentId,
            'message': _messageController.text.trim(),
            'sport_facility_id': _selectedFacilityId,
            'location': locationName,
            'proposed_dates': _proposedDates
                .map((date) => date.toUtc().toIso8601String())
                .toList(),
          });

      ref.invalidate(teamChallengesListControllerProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wyzwanie druzynowe utworzone.')),
      );
      context.go('/team-challenges/${created.id}');
    } on ApiException catch (error) {
      setState(() => _submitError = _businessMessage(error));
    } catch (error) {
      setState(
        () => _submitError =
            'Nie udalo sie utworzyc wyzwania druzynowego: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _businessMessage(ApiException error) {
    if (error.statusCode == 409) {
      return error.message.isEmpty
          ? 'Nie mozna wykonac tej akcji.'
          : error.message;
    }
    return error.message;
  }

  Future<DateTime?> _pickDateTime() async {
    final now = DateTime.now();
    final initialDate = now.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );

    if (date == null || !mounted) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
