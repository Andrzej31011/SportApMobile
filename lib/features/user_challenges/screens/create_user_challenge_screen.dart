import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sport_ap_mobile/core/network/api_exception.dart';
import 'package:sport_ap_mobile/features/auth/models/user_model.dart';
import 'package:sport_ap_mobile/features/auth/state/auth_controller.dart';
import 'package:sport_ap_mobile/features/common/state/lookup_providers.dart';
import 'package:sport_ap_mobile/features/dictionaries/models/discipline_model.dart';
import 'package:sport_ap_mobile/features/dictionaries/state/dictionaries_provider.dart';
import 'package:sport_ap_mobile/features/sport_facilities/models/sport_facility_model.dart';
import 'package:sport_ap_mobile/features/user_challenges/data/user_challenges_repository.dart';
import 'package:sport_ap_mobile/features/user_challenges/state/user_challenges_list_controller.dart';

class CreateUserChallengeScreen extends ConsumerStatefulWidget {
  const CreateUserChallengeScreen({super.key, this.initialChallengedUserId});

  final String? initialChallengedUserId;

  @override
  ConsumerState<CreateUserChallengeScreen> createState() =>
      _CreateUserChallengeScreenState();
}

class _CreateUserChallengeScreenState
    extends ConsumerState<CreateUserChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _messageController = TextEditingController();

  String? _selectedUserId;
  int? _selectedDisciplineId;
  String? _selectedFacilityId;
  final List<_TermFormEntry> _terms = <_TermFormEntry>[_TermFormEntry()];

  bool _isSaving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.initialChallengedUserId;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _messageController.dispose();
    for (final term in _terms) {
      term.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUserId = ref.watch(authControllerProvider).user?.id;
    final allUsers =
        ref.watch(usersLookupProvider).value ?? const <UserModel>[];
    final users = allUsers.where((user) => user.id != authUserId).toList();
    final disciplines =
        ref.watch(disciplinesProvider).value ?? const <DisciplineModel>[];
    final facilities =
        ref.watch(sportFacilitiesLookupProvider).value ??
        const <SportFacilityModel>[];

    final hasSelectedUser =
        users.any((user) => user.id == _selectedUserId) ||
        _selectedUserId == null;
    if (!hasSelectedUser) {
      _selectedUserId = null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Wyzwij uzytkownika')),
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
                          initialValue: _selectedUserId,
                          decoration: const InputDecoration(
                            labelText: 'Wyzywany uzytkownik',
                          ),
                          items: users
                              .map(
                                (user) => DropdownMenuItem<String>(
                                  value: user.id,
                                  child: Text(user.nick),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedUserId = value);
                          },
                          validator: (_) {
                            if (_selectedUserId == null) {
                              return 'Wybierz uzytkownika';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedDisciplineId,
                          decoration: const InputDecoration(
                            labelText: 'Dyscyplina',
                          ),
                          items: disciplines
                              .map(
                                (discipline) => DropdownMenuItem<int>(
                                  value: discipline.id,
                                  child: Text(discipline.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedDisciplineId = value);
                          },
                          validator: (_) {
                            if (_selectedDisciplineId == null) {
                              return 'Wybierz dyscypline';
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Proponowane terminy',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _terms.add(_TermFormEntry());
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Dodaj termin'),
                            ),
                          ],
                        ),
                        ..._terms.asMap().entries.map((entry) {
                          final index = entry.key;
                          final term = entry.value;
                          return _buildTermCard(index, term);
                        }),
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
                      : const Text('Utworz wyzwanie'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermCard(int index, _TermFormEntry term) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('Termin ${index + 1}'),
                const Spacer(),
                if (_terms.length > 1)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        final removed = _terms.removeAt(index);
                        removed.dispose();
                      });
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await _pickDateTime(term.startsAt);
                if (picked != null) {
                  setState(() => term.startsAt = picked);
                }
              },
              icon: const Icon(Icons.schedule),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Start: ${term.startsAt == null ? 'Wybierz' : DateFormat('dd.MM.yyyy HH:mm').format(term.startsAt!.toLocal())}',
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await _pickDateTime(term.endsAt);
                if (picked != null) {
                  setState(() => term.endsAt = picked);
                }
              },
              icon: const Icon(Icons.schedule_send),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Koniec: ${term.endsAt == null ? 'Wybierz' : DateFormat('dd.MM.yyyy HH:mm').format(term.endsAt!.toLocal())}',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: term.noteController,
              decoration: const InputDecoration(
                labelText: 'Notatka (opcjonalnie)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUserId == null || _selectedDisciplineId == null) {
      setState(() => _submitError = 'Wybierz uzytkownika i dyscypline.');
      return;
    }

    if (_selectedFacilityId == null &&
        _locationController.text.trim().isEmpty) {
      setState(() {
        _submitError = 'Podaj obiekt sportowy albo wpisz nazwe lokalizacji.';
      });
      return;
    }

    final termErrors = _validateTerms();
    if (termErrors != null) {
      setState(() => _submitError = termErrors);
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
          .read(userChallengesRepositoryProvider)
          .createChallenge(<String, dynamic>{
            'challenged_user_id': _selectedUserId,
            'discipline_id': _selectedDisciplineId,
            'sport_facility_id': _selectedFacilityId,
            'location_name': locationName,
            'message': _messageController.text.trim(),
            'terms': _terms
                .map(
                  (term) => <String, dynamic>{
                    'starts_at': term.startsAt!.toUtc().toIso8601String(),
                    'ends_at': term.endsAt!.toUtc().toIso8601String(),
                    'note': term.noteController.text.trim().isEmpty
                        ? null
                        : term.noteController.text.trim(),
                  },
                )
                .toList(),
          });

      ref.invalidate(userChallengesListControllerProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wyzwanie utworzone.')));
      context.go('/challenges/${created.id}');
    } on ApiException catch (error) {
      setState(() => _submitError = _businessMessage(error));
    } catch (error) {
      setState(() => _submitError = 'Nie udalo sie utworzyc wyzwania: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _validateTerms() {
    if (_terms.isEmpty) {
      return 'Dodaj co najmniej jeden termin.';
    }

    for (var i = 0; i < _terms.length; i++) {
      final term = _terms[i];
      if (term.startsAt == null || term.endsAt == null) {
        return 'Termin ${i + 1}: wybierz start i koniec.';
      }
      if (!term.endsAt!.isAfter(term.startsAt!)) {
        return 'Termin ${i + 1}: koniec musi byc po starcie.';
      }
    }

    return null;
  }

  String _businessMessage(ApiException error) {
    if (error.statusCode == 409) {
      return error.message.isEmpty
          ? 'Nie mozna wykonac tej akcji.'
          : error.message;
    }
    return error.message;
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final initialDate = initial ?? now.add(const Duration(hours: 1));

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

class _TermFormEntry {
  DateTime? startsAt;
  DateTime? endsAt;
  final TextEditingController noteController = TextEditingController();

  void dispose() {
    noteController.dispose();
  }
}
