import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sport_ap_mobile/core/network/api_exception.dart';
import 'package:sport_ap_mobile/features/common/state/lookup_providers.dart';
import 'package:sport_ap_mobile/features/dictionaries/models/dictionary_item_model.dart';
import 'package:sport_ap_mobile/features/dictionaries/models/discipline_model.dart';
import 'package:sport_ap_mobile/features/dictionaries/state/dictionaries_provider.dart';
import 'package:sport_ap_mobile/features/events/data/events_repository.dart';
import 'package:sport_ap_mobile/features/events/state/events_list_controller.dart';
import 'package:sport_ap_mobile/features/sport_facilities/models/discipline_sport_facility_model.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _participantLimitController = TextEditingController(text: '10');

  bool _isPublic = true;
  bool _isPaid = false;
  String? _selectedLevel;
  String? _selectedGender;
  String? _selectedDisciplineId;
  String? _selectedDisciplineSportFacilityId;
  DateTime? _startTime;
  DateTime? _endTime;

  bool _isSaving = false;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _participantLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dictionaries = ref.watch(dictionariesProvider);
    final fallbackLevels = ref.watch(levelsProvider).value;
    final fallbackGenders = ref.watch(gendersProvider).value;
    final disciplinesAsync = ref.watch(disciplinesProvider);

    final levelOptions = _eventLevelOptions(dictionaries, fallbackLevels);
    final genderOptions = _eventGenderOptions(dictionaries, fallbackGenders);

    if (_selectedLevel == null && levelOptions.isNotEmpty) {
      _selectedLevel = levelOptions.first.value;
    }
    if (_selectedGender == null && genderOptions.isNotEmpty) {
      _selectedGender = genderOptions.first.value;
    }

    final disciplines = disciplinesAsync.value ?? const <DisciplineModel>[];

    if (_selectedDisciplineId != null &&
        !disciplines.any(
          (item) => item.id.toString() == _selectedDisciplineId,
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedDisciplineId = null;
          _selectedDisciplineSportFacilityId = null;
        });
      });
    }

    final disciplineFacilitiesAsync = _selectedDisciplineId == null
        ? null
        : ref.watch(disciplineSportFacilitiesProvider(_selectedDisciplineId!));

    return Scaffold(
      appBar: AppBar(title: const Text('Utworz wydarzenie')),
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
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Nazwa'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Podaj nazwe wydarzenia';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Opis'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: const ValueKey('discipline-select'),
                          initialValue: _selectedDisciplineId,
                          decoration: const InputDecoration(
                            labelText: 'Dyscyplina',
                          ),
                          items: disciplines
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item.id.toString(),
                                  child: Text(item.name),
                                ),
                              )
                              .toList(),
                          onChanged: disciplinesAsync.isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    if (_selectedDisciplineId != value) {
                                      _selectedDisciplineId = value;
                                      _selectedDisciplineSportFacilityId = null;
                                    }
                                  });
                                },
                          validator: (_) {
                            if (_selectedDisciplineId == null) {
                              return 'Wybierz dyscypline';
                            }
                            return null;
                          },
                        ),
                        if (disciplinesAsync.isLoading) ...<Widget>[
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(minHeight: 2),
                        ],
                        if (disciplinesAsync.hasError) ...<Widget>[
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Nie udalo sie pobrac dyscyplin.',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref.invalidate(disciplinesProvider);
                                },
                                child: const Text('Ponow'),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        _DisciplineSportFacilityField(
                          asyncValue: disciplineFacilitiesAsync,
                          selectedValue: _selectedDisciplineSportFacilityId,
                          onChanged: (value) {
                            setState(
                              () => _selectedDisciplineSportFacilityId = value,
                            );
                          },
                          onRetry: _selectedDisciplineId == null
                              ? null
                              : () {
                                  ref.invalidate(
                                    disciplineSportFacilitiesProvider(
                                      _selectedDisciplineId!,
                                    ),
                                  );
                                },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLevel,
                          decoration: const InputDecoration(
                            labelText: 'Poziom',
                          ),
                          items: levelOptions
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item.value,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedLevel = value);
                          },
                          validator: (_) {
                            if (_selectedLevel == null) {
                              return 'Wybierz poziom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          decoration: const InputDecoration(labelText: 'Plec'),
                          items: genderOptions
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item.value,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedGender = value);
                          },
                          validator: (_) {
                            if (_selectedGender == null) {
                              return 'Wybierz plec';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _isPublic,
                          onChanged: (value) {
                            setState(() => _isPublic = value);
                          },
                          title: const Text('Publiczne'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _isPaid,
                          onChanged: (value) {
                            setState(() => _isPaid = value);
                          },
                          title: const Text('Platne'),
                        ),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'Cena'),
                          validator: (value) {
                            final parsed = double.tryParse(value ?? '');
                            if (parsed == null) {
                              return 'Podaj poprawna cene';
                            }
                            if (_isPaid && parsed <= 0) {
                              return 'Dla platnego wydarzenia cena > 0';
                            }
                            if (!_isPaid && parsed < 0) {
                              return 'Cena nie moze byc ujemna';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _participantLimitController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Limit uczestnikow',
                          ),
                          validator: (value) {
                            final parsed = int.tryParse(value ?? '');
                            if (parsed == null || parsed <= 0) {
                              return 'Podaj dodatni limit';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _DateTimeField(
                          label: 'Start',
                          value: _startTime,
                          onPick: () async {
                            final picked = await _pickDateTime(_startTime);
                            if (picked != null) {
                              setState(() => _startTime = picked);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        _DateTimeField(
                          label: 'Koniec',
                          value: _endTime,
                          onPick: () async {
                            final picked = await _pickDateTime(_endTime);
                            if (picked != null) {
                              setState(() => _endTime = picked);
                            }
                          },
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
                      : const Text('Utworz wydarzenie'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<DictionaryItemModel> _eventLevelOptions(
    AsyncValue<Map<String, List<DictionaryItemModel>>> dictionaries,
    List<DictionaryItemModel>? fallback,
  ) {
    final map =
        dictionaries.value ?? const <String, List<DictionaryItemModel>>{};
    final eventLevels = map['event_levels'];
    if (eventLevels != null && eventLevels.isNotEmpty) {
      return eventLevels;
    }

    return fallback ?? const <DictionaryItemModel>[];
  }

  List<DictionaryItemModel> _eventGenderOptions(
    AsyncValue<Map<String, List<DictionaryItemModel>>> dictionaries,
    List<DictionaryItemModel>? fallback,
  ) {
    final map =
        dictionaries.value ?? const <String, List<DictionaryItemModel>>{};
    final eventGenders = map['event_genders'];
    if (eventGenders != null && eventGenders.isNotEmpty) {
      return eventGenders;
    }

    return fallback ?? const <DictionaryItemModel>[];
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitError = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDisciplineId == null) {
      setState(() => _submitError = 'Wybierz dyscypline.');
      return;
    }

    final sportFacilitiesState = ref.read(
      disciplineSportFacilitiesProvider(_selectedDisciplineId!),
    );

    if (sportFacilitiesState.isLoading) {
      setState(
        () => _submitError = 'Poczekaj na pobranie obiektow sportowych.',
      );
      return;
    }

    if (sportFacilitiesState.hasError) {
      setState(() {
        _submitError =
            'Nie udalo sie pobrac obiektow dla wybranej dyscypliny. Sprobuj ponownie.';
      });
      return;
    }

    final availableFacilities =
        sportFacilitiesState.value ?? const <DisciplineSportFacilityModel>[];

    if (availableFacilities.isEmpty) {
      setState(() => _submitError = 'Brak obiektow dla wybranej dyscypliny.');
      return;
    }

    if (_selectedDisciplineSportFacilityId == null) {
      setState(() => _submitError = 'Wybierz obiekt sportowy.');
      return;
    }

    DisciplineSportFacilityModel? selectedRelation;
    for (final item in availableFacilities) {
      if (item.disciplineSportFacilityId ==
          _selectedDisciplineSportFacilityId) {
        selectedRelation = item;
        break;
      }
    }

    if (selectedRelation == null ||
        selectedRelation.disciplineSportFacilityId.trim().isEmpty) {
      setState(() {
        _submitError =
            'Nie udalo sie ustalic discipline_sport_facility_id dla wybranego obiektu.';
      });
      return;
    }

    if (_startTime == null || _endTime == null) {
      setState(() => _submitError = 'Wybierz date startu i konca.');
      return;
    }

    if (!_endTime!.isAfter(_startTime!)) {
      setState(() => _submitError = 'Koniec wydarzenia musi byc po starcie.');
      return;
    }

    if (_selectedLevel == null || _selectedGender == null) {
      setState(() => _submitError = 'Uzupelnij poziom i plec.');
      return;
    }

    final participantLimit = int.tryParse(
      _participantLimitController.text.trim(),
    );
    if (participantLimit == null || participantLimit <= 0) {
      setState(() => _submitError = 'Podaj poprawny limit uczestnikow.');
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null) {
      setState(() => _submitError = 'Podaj poprawna cene.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final created = await ref
          .read(eventsRepositoryProvider)
          .createEvent(<String, dynamic>{
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'discipline_sport_facility_id':
                selectedRelation.requestDisciplineSportFacilityId,
            'level': _selectedLevel,
            'gender': _selectedGender,
            'is_public': _isPublic,
            'is_paid': _isPaid,
            'price': price,
            'participant_limit': participantLimit,
            'start_time': _startTime!.toUtc().toIso8601String(),
            'end_time': _endTime!.toUtc().toIso8601String(),
          });

      ref.invalidate(eventsListControllerProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wydarzenie utworzone.')));
      if (created.id.trim().isEmpty) {
        context.go('/events');
      } else {
        context.go('/events/${created.id}');
      }
    } on ApiException catch (error) {
      setState(() => _submitError = _businessMessage(error));
    } catch (error) {
      setState(
        () => _submitError = 'Nie udalo sie utworzyc wydarzenia: $error',
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

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final initialDate = initial ?? now.add(const Duration(hours: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );

    if (pickedDate == null || !mounted) {
      return null;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null) {
      return null;
    }

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }
}

class _DisciplineSportFacilityField extends StatefulWidget {
  const _DisciplineSportFacilityField({
    required this.asyncValue,
    required this.selectedValue,
    required this.onChanged,
    this.onRetry,
  });

  final AsyncValue<List<DisciplineSportFacilityModel>>? asyncValue;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onRetry;

  @override
  State<_DisciplineSportFacilityField> createState() =>
      _DisciplineSportFacilityFieldState();
}

class _DisciplineSportFacilityFieldState
    extends State<_DisciplineSportFacilityField> {
  @override
  Widget build(BuildContext context) {
    final asyncValue = widget.asyncValue;

    if (asyncValue == null) {
      return DropdownButtonFormField<String>(
        key: const ValueKey('facility-disabled-no-discipline'),
        initialValue: null,
        decoration: const InputDecoration(labelText: 'Obiekt sportowy'),
        items: const <DropdownMenuItem<String>>[],
        onChanged: null,
        validator: (_) => 'Najpierw wybierz dyscypline',
      );
    }

    if (asyncValue.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DropdownButtonFormField<String>(
            key: const ValueKey('facility-loading'),
            initialValue: null,
            decoration: const InputDecoration(labelText: 'Obiekt sportowy'),
            items: const <DropdownMenuItem<String>>[],
            onChanged: null,
            validator: (_) => 'Trwa pobieranie obiektow',
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(minHeight: 2),
        ],
      );
    }

    if (asyncValue.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DropdownButtonFormField<String>(
            key: const ValueKey('facility-error'),
            initialValue: null,
            decoration: const InputDecoration(labelText: 'Obiekt sportowy'),
            items: const <DropdownMenuItem<String>>[],
            onChanged: null,
            validator: (_) => 'Nie udalo sie pobrac obiektow',
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Nie udalo sie pobrac obiektow. Sprobuj ponownie.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              TextButton(onPressed: widget.onRetry, child: const Text('Ponow')),
            ],
          ),
        ],
      );
    }

    final items = asyncValue.value ?? const <DisciplineSportFacilityModel>[];

    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DropdownButtonFormField<String>(
            key: const ValueKey('facility-empty'),
            initialValue: null,
            decoration: const InputDecoration(labelText: 'Obiekt sportowy'),
            items: const <DropdownMenuItem<String>>[],
            onChanged: null,
            validator: (_) => 'Brak obiektow dla wybranej dyscypliny',
          ),
          const SizedBox(height: 8),
          const Text('Brak obiektow dla wybranej dyscypliny.'),
        ],
      );
    }

    final hasSelected = items.any(
      (item) => item.disciplineSportFacilityId == widget.selectedValue,
    );
    final effectiveSelected = hasSelected ? widget.selectedValue : null;

    if (!hasSelected && widget.selectedValue != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(null);
      });
    }

    return DropdownButtonFormField<String>(
      key: const ValueKey('facility-ready'),
      initialValue: effectiveSelected,
      decoration: const InputDecoration(labelText: 'Obiekt sportowy'),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.disciplineSportFacilityId,
              child: Text(item.facilityDisplayName),
            ),
          )
          .toList(),
      onChanged: widget.onChanged,
      validator: (_) {
        if (effectiveSelected == null) {
          return 'Wybierz obiekt sportowy';
        }
        return null;
      },
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPick,
      icon: const Icon(Icons.schedule),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$label: ${value == null ? 'Wybierz' : DateFormat('dd.MM.yyyy HH:mm').format(value!.toLocal())}',
        ),
      ),
    );
  }
}
