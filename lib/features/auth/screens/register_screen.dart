import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_ap_mobile/features/auth/data/auth_repository.dart';
import 'package:sport_ap_mobile/features/auth/state/auth_controller.dart';
import 'package:sport_ap_mobile/features/dictionaries/models/dictionary_item_model.dart';
import 'package:sport_ap_mobile/features/dictionaries/state/dictionaries_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nickController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  String _gender = 'male';
  bool _marketingConsent = false;
  bool _gdprConsent = false;
  bool _regulationsConsent = false;

  @override
  void dispose() {
    _nickController.dispose();
    _birthYearController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_gdprConsent || !_regulationsConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zgody GDPR i regulamin sa wymagane.')),
      );
      return;
    }

    final payload = RegisterPayload(
      nick: _nickController.text.trim(),
      gender: _gender,
      birthYear: int.parse(_birthYearController.text),
      password: _passwordController.text,
      passwordConfirmation: _passwordConfirmationController.text,
      marketingConsent: _marketingConsent,
      gdprConsent: _gdprConsent,
      regulationsConsent: _regulationsConsent,
    );

    final success = await ref
        .read(authControllerProvider.notifier)
        .register(payload);

    if (!mounted || success) {
      return;
    }

    final message = ref.read(authControllerProvider).errorMessage;
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
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
      appBar: AppBar(title: const Text('Rejestracja')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
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
                            if (value == null) {
                              return;
                            }
                            setState(() => _gender = value);
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
                            if (value == null || value.trim().isEmpty) {
                              return 'Podaj rok urodzenia';
                            }
                            final year = int.tryParse(value);
                            if (year == null) {
                              return 'Rok musi byc liczba';
                            }
                            if (year < 1900 || year > DateTime.now().year) {
                              return 'Podaj poprawny rok';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Haslo'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Podaj haslo';
                            }
                            if (value.length < 6) {
                              return 'Haslo musi miec min. 6 znakow';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordConfirmationController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Potwierdz haslo',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Powtorz haslo';
                            }
                            if (value != _passwordController.text) {
                              return 'Hasla nie sa takie same';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _marketingConsent,
                          onChanged: (value) {
                            setState(() => _marketingConsent = value ?? false);
                          },
                          title: const Text('Zgoda marketingowa'),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _gdprConsent,
                          onChanged: (value) {
                            setState(() => _gdprConsent = value ?? false);
                          },
                          title: const Text('Zgoda GDPR (wymagana)'),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _regulationsConsent,
                          onChanged: (value) {
                            setState(
                              () => _regulationsConsent = value ?? false,
                            );
                          },
                          title: const Text('Akceptacja regulaminu (wymagana)'),
                        ),
                        if (authState.errorMessage != null) ...<Widget>[
                          Text(
                            authState.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: authState.isLoading ? null : _submit,
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Zarejestruj'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/auth/login'),
                          child: const Text('Masz konto? Zaloguj sie'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
