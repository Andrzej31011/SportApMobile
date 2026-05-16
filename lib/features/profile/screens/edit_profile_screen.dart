import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/features/dictionaries/models/dictionary_item_model.dart';
import 'package:sport_ap_mobile/features/dictionaries/state/dictionaries_provider.dart';
import 'package:sport_ap_mobile/features/profile/state/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nickController;
  late final TextEditingController _birthYearController;
  late final TextEditingController _avatarController;

  String _gender = 'male';
  bool _marketingConsent = false;
  bool _gdprConsent = true;
  bool _regulationsConsent = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(profileControllerProvider).user;

    _nickController = TextEditingController(text: user?.nick ?? '');
    _birthYearController = TextEditingController(
      text: user?.birthYear?.toString() ?? '',
    );
    _avatarController = TextEditingController(text: user?.avatarUrl ?? '');
    _gender = user?.gender ?? 'male';
    _marketingConsent = user?.marketingConsent ?? false;
    _gdprConsent = user?.gdprConsent ?? true;
    _regulationsConsent = user?.regulationsConsent ?? true;
  }

  @override
  void dispose() {
    _nickController.dispose();
    _birthYearController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(<String, dynamic>{
          'nick': _nickController.text.trim(),
          'gender': _gender,
          'birth_year': int.parse(_birthYearController.text),
          'avatar_url': _avatarController.text.trim().isEmpty
              ? null
              : _avatarController.text.trim(),
          'marketing_consent': _marketingConsent,
          'gdpr_consent': _gdprConsent,
          'regulations_consent': _regulationsConsent,
        });

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil zapisany.')));
      Navigator.of(context).pop();
      return;
    }

    final message = ref.read(profileControllerProvider).errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final genders = ref.watch(gendersProvider);
    final genderItems = genders.maybeWhen(
      data: (items) => items,
      orElse: () => const <DictionaryItemModel>[
        DictionaryItemModel(value: 'male', label: 'Male'),
        DictionaryItemModel(value: 'female', label: 'Female'),
      ],
    );

    final selectedGenderExists = genderItems.any(
      (item) => item.value == _gender,
    );
    if (!selectedGenderExists && genderItems.isNotEmpty) {
      _gender = genderItems.first.value;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edytuj profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _nickController,
                      decoration: const InputDecoration(labelText: 'Nick'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Podaj nick';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Plec'),
                      items: genderItems
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item.value,
                              child: Text(item.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _gender = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _birthYearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Rok urodzenia',
                      ),
                      validator: (value) {
                        final year = int.tryParse(value ?? '');
                        if (year == null) {
                          return 'Podaj poprawny rok';
                        }
                        if (year < 1900 || year > DateTime.now().year) {
                          return 'Podaj poprawny rok';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _avatarController,
                      decoration: const InputDecoration(
                        labelText: 'Avatar URL',
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _marketingConsent,
                      title: const Text('Zgoda marketingowa'),
                      onChanged: (value) {
                        setState(() => _marketingConsent = value ?? false);
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _gdprConsent,
                      title: const Text('Zgoda GDPR'),
                      onChanged: (value) {
                        setState(() => _gdprConsent = value ?? false);
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _regulationsConsent,
                      title: const Text('Akceptacja regulaminu'),
                      onChanged: (value) {
                        setState(() => _regulationsConsent = value ?? false);
                      },
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: state.isSaving ? null : _save,
                      child: state.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Zapisz'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
