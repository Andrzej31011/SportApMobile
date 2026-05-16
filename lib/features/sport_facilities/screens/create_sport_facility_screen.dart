import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_ap_mobile/core/network/api_exception.dart';
import 'package:sport_ap_mobile/features/dictionaries/models/discipline_model.dart';
import 'package:sport_ap_mobile/features/dictionaries/state/dictionaries_provider.dart';
import 'package:sport_ap_mobile/features/sport_facilities/data/sport_facilities_repository.dart';
import 'package:sport_ap_mobile/features/sport_facilities/state/sport_facilities_list_controller.dart';

class CreateSportFacilityScreen extends ConsumerStatefulWidget {
  const CreateSportFacilityScreen({super.key});

  @override
  ConsumerState<CreateSportFacilityScreen> createState() =>
      _CreateSportFacilityScreenState();
}

class _CreateSportFacilityScreenState
    extends ConsumerState<CreateSportFacilityScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _surfaceTypeController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _rulesController = TextEditingController();

  bool _isPaid = false;
  bool _hasLighting = false;
  bool _hasLockerRoom = false;
  bool _hasShowers = false;
  bool _hasParking = false;
  bool _hasEquipmentRental = false;
  bool _hasBasketballNets = false;
  bool _hasFootballGoals = false;
  bool _isIndoor = false;
  bool _isOutdoor = true;
  final Set<int> _disciplineIds = <int>{};

  bool _isSaving = false;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _surfaceTypeController.dispose();
    _openingHoursController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disciplines =
        ref.watch(disciplinesProvider).value ?? const <DisciplineModel>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Dodaj obiekt')),
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
                              return 'Podaj nazwe obiektu';
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
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Adres'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email kontaktowy',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final ok = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(value.trim());
                            if (!ok) {
                              return 'Podaj poprawny email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telefon kontaktowy',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: _latController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Latitude',
                                ),
                                validator: (value) {
                                  if (double.tryParse(value ?? '') == null) {
                                    return 'Lat wymagane';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _lngController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Longitude',
                                ),
                                validator: (value) {
                                  if (double.tryParse(value ?? '') == null) {
                                    return 'Lng wymagane';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _surfaceTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Typ nawierzchni',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _openingHoursController,
                          decoration: const InputDecoration(
                            labelText: 'Godziny otwarcia',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _rulesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Regulamin',
                          ),
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
                        Text(
                          'Dyscypliny',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: disciplines
                              .map(
                                (discipline) => FilterChip(
                                  label: Text(discipline.name),
                                  selected: _disciplineIds.contains(
                                    discipline.id,
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _disciplineIds.add(discipline.id);
                                      } else {
                                        _disciplineIds.remove(discipline.id);
                                      }
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _isPaid,
                          onChanged: (value) => setState(() => _isPaid = value),
                          title: const Text('Platny'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _hasLighting,
                          onChanged: (value) =>
                              setState(() => _hasLighting = value),
                          title: const Text('Oswietlenie'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _hasLockerRoom,
                          onChanged: (value) =>
                              setState(() => _hasLockerRoom = value),
                          title: const Text('Szatnia'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _hasShowers,
                          onChanged: (value) =>
                              setState(() => _hasShowers = value),
                          title: const Text('Prysznice'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _hasParking,
                          onChanged: (value) =>
                              setState(() => _hasParking = value),
                          title: const Text('Parking'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _hasEquipmentRental,
                          onChanged: (value) =>
                              setState(() => _hasEquipmentRental = value),
                          title: const Text('Wypozyczalnia sprzetu'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _hasBasketballNets,
                          onChanged: (value) =>
                              setState(() => _hasBasketballNets = value),
                          title: const Text('Kosze do koszykowki'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _hasFootballGoals,
                          onChanged: (value) =>
                              setState(() => _hasFootballGoals = value),
                          title: const Text('Bramki pilkarskie'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _isIndoor,
                          onChanged: (value) =>
                              setState(() => _isIndoor = value),
                          title: const Text('Indoor'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _isOutdoor,
                          onChanged: (value) =>
                              setState(() => _isOutdoor = value),
                          title: const Text('Outdoor'),
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
                      : const Text('Dodaj obiekt'),
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

    if (_disciplineIds.isEmpty) {
      setState(() => _submitError = 'Wybierz co najmniej jedna dyscypline.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final created = await ref
          .read(sportFacilitiesRepositoryProvider)
          .createFacility(<String, dynamic>{
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            'address': _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            'contact_email': _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            'contact_phone': _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            'is_paid': _isPaid,
            'geo_lat': double.parse(_latController.text.trim()),
            'geo_long': double.parse(_lngController.text.trim()),
            'surface_type': _surfaceTypeController.text.trim().isEmpty
                ? null
                : _surfaceTypeController.text.trim(),
            'has_lighting': _hasLighting,
            'has_locker_room': _hasLockerRoom,
            'has_showers': _hasShowers,
            'has_parking': _hasParking,
            'has_equipment_rental': _hasEquipmentRental,
            'has_basketball_nets': _hasBasketballNets,
            'has_football_goals': _hasFootballGoals,
            'is_indoor': _isIndoor,
            'is_outdoor': _isOutdoor,
            'opening_hours': _openingHoursController.text.trim().isEmpty
                ? null
                : _openingHoursController.text.trim(),
            'rules': _rulesController.text.trim().isEmpty
                ? null
                : _rulesController.text.trim(),
            'discipline_ids': _disciplineIds.toList(),
          });

      ref.invalidate(sportFacilitiesListControllerProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Obiekt utworzony.')));
      context.go('/facilities/${created.id}');
    } on ApiException catch (error) {
      setState(() => _submitError = _businessMessage(error));
    } catch (error) {
      setState(() => _submitError = 'Nie udalo sie dodac obiektu: $error');
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
