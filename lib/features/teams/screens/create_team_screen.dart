import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sport_ap_mobile/core/network/api_exception.dart';
import 'package:sport_ap_mobile/features/dictionaries/models/dictionary_item_model.dart';
import 'package:sport_ap_mobile/features/dictionaries/models/discipline_model.dart';
import 'package:sport_ap_mobile/features/dictionaries/state/dictionaries_provider.dart';
import 'package:sport_ap_mobile/features/teams/data/teams_repository.dart';
import 'package:sport_ap_mobile/features/teams/state/teams_list_controller.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _establishmentDate;
  int? _selectedDisciplineId;
  String? _selectedLevel;
  String? _selectedStyle;
  bool _isSaving = false;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disciplines =
        ref.watch(disciplinesProvider).value ?? const <DisciplineModel>[];
    final dictionaries = ref.watch(dictionariesProvider);
    final fallbackLevels = ref.watch(levelsProvider).value;

    final levels = _teamLevels(dictionaries, fallbackLevels);
    final styles = _teamStyles(dictionaries);

    if (_selectedLevel == null && levels.isNotEmpty) {
      _selectedLevel = levels.first.value;
    }
    if (_selectedStyle == null && styles.isNotEmpty) {
      _selectedStyle = styles.first.value;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Utworz druzyne')),
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
                              return 'Podaj nazwe druzyny';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Opis'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Podaj opis druzyny';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_month),
                          label: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _establishmentDate == null
                                  ? 'Data zalozenia: wybierz'
                                  : 'Data zalozenia: ${DateFormat('dd.MM.yyyy').format(_establishmentDate!.toLocal())}',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedDisciplineId,
                          decoration: const InputDecoration(
                            labelText: 'Dyscyplina',
                          ),
                          items: disciplines
                              .map(
                                (item) => DropdownMenuItem<int>(
                                  value: item.id,
                                  child: Text(item.name),
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
                          initialValue: _selectedLevel,
                          decoration: const InputDecoration(
                            labelText: 'Poziom',
                          ),
                          items: levels
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
                          initialValue: _selectedStyle,
                          decoration: const InputDecoration(
                            labelText: 'Styl gry',
                          ),
                          items: styles
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item.value,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedStyle = value);
                          },
                          validator: (_) {
                            if (_selectedStyle == null) {
                              return 'Wybierz styl gry';
                            }
                            return null;
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
                      : const Text('Utworz druzyne'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<DictionaryItemModel> _teamLevels(
    AsyncValue<Map<String, List<DictionaryItemModel>>> dictionaries,
    List<DictionaryItemModel>? fallback,
  ) {
    final map =
        dictionaries.value ?? const <String, List<DictionaryItemModel>>{};
    final preferred = map['team_levels'];
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }
    return fallback ?? const <DictionaryItemModel>[];
  }

  List<DictionaryItemModel> _teamStyles(
    AsyncValue<Map<String, List<DictionaryItemModel>>> dictionaries,
  ) {
    final map =
        dictionaries.value ?? const <String, List<DictionaryItemModel>>{};
    final preferred = map['team_styles'];
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }
    final styles = map['styles'];
    if (styles != null && styles.isNotEmpty) {
      return styles;
    }
    return const <DictionaryItemModel>[];
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _establishmentDate ?? now,
      firstDate: DateTime(1950),
      lastDate: now,
    );

    if (picked != null) {
      setState(() => _establishmentDate = picked);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_establishmentDate == null) {
      setState(() => _submitError = 'Wybierz date zalozenia.');
      return;
    }

    if (_selectedDisciplineId == null ||
        _selectedLevel == null ||
        _selectedStyle == null) {
      setState(() => _submitError = 'Uzupelnij dyscypline, poziom i styl.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final created = await ref.read(teamsRepositoryProvider).createTeam(
        <String, dynamic>{
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'establishment_date': DateFormat(
            'yyyy-MM-dd',
          ).format(_establishmentDate!.toLocal()),
          'disciplines': <Map<String, dynamic>>[
            <String, dynamic>{
              'discipline_id': _selectedDisciplineId,
              'level': _selectedLevel,
              'style': _selectedStyle,
            },
          ],
        },
      );

      ref.invalidate(teamsListControllerProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Druzyna utworzona.')));
      context.go('/teams/${created.id}');
    } on ApiException catch (error) {
      setState(() => _submitError = _businessMessage(error));
    } catch (error) {
      setState(() => _submitError = 'Nie udalo sie utworzyc druzyny: $error');
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
}
