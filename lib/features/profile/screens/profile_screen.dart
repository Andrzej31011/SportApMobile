import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_ap_mobile/core/widgets/app_error_view.dart';
import 'package:sport_ap_mobile/core/widgets/app_loading_view.dart';
import 'package:sport_ap_mobile/features/auth/state/auth_controller.dart';
import 'package:sport_ap_mobile/features/profile/state/profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push('/team-challenges'),
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Wyzwania druzynowe',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.user == null) {
            return const AppLoadingView();
          }

          if (state.errorMessage != null && state.user == null) {
            return AppErrorView(
              message: state.errorMessage!,
              onRetry: () =>
                  ref.read(profileControllerProvider.notifier).loadProfile(),
            );
          }

          final user = state.user;
          if (user == null) {
            return const AppErrorView(message: 'Brak danych profilu.');
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(profileControllerProvider.notifier).loadProfile(),
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
                          user.nick,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        _row('Plec', user.gender ?? '-'),
                        _row(
                          'Rok urodzenia',
                          user.birthYear?.toString() ?? '-',
                        ),
                        _row('Avatar', user.avatarUrl ?? '-'),
                        _row('Lokalizacja', user.locationName ?? '-'),
                        _row(
                          'Wspolrzedne',
                          '${user.latitude ?? '-'}, ${user.longitude ?? '-'}',
                        ),
                        _row('Promien (km)', user.radiusKm?.toString() ?? '-'),
                        _row(
                          'Preferencje sportowe',
                          user.preferredSports.isEmpty
                              ? '-'
                              : user.preferredSports.join(', '),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => context.push('/profile/edit'),
                  child: const Text('Edytuj profil'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => _showLocationDialog(context, ref),
                  child: const Text('Edytuj lokalizacje'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => context.push('/users'),
                  child: const Text('Uzytkownicy'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: state.isSaving
                      ? null
                      : () =>
                            ref.read(authControllerProvider.notifier).logout(),
                  child: const Text('Wyloguj'),
                ),
                if (state.errorMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 140, child: Text('$label:')),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _showLocationDialog(BuildContext context, WidgetRef ref) async {
    final state = ref.read(profileControllerProvider);
    final user = state.user;
    if (user == null) {
      return;
    }

    final formKey = GlobalKey<FormState>();
    final latController = TextEditingController(text: '${user.latitude ?? ''}');
    final lngController = TextEditingController(
      text: '${user.longitude ?? ''}',
    );
    final radiusController = TextEditingController(
      text: '${user.radiusKm ?? 25}',
    );
    final locationController = TextEditingController(
      text: user.locationName ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edytuj lokalizacje'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: latController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    validator: (value) {
                      if (double.tryParse(value ?? '') == null) {
                        return 'Podaj poprawna szerokosc';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: lngController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    validator: (value) {
                      if (double.tryParse(value ?? '') == null) {
                        return 'Podaj poprawna dlugosc';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: radiusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Promien (km)',
                    ),
                    validator: (value) {
                      if (int.tryParse(value ?? '') == null) {
                        return 'Podaj poprawny promien';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Nazwa lokalizacji',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Podaj nazwe lokalizacji';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final success = await ref
                    .read(profileControllerProvider.notifier)
                    .updateLocation(
                      latitude: double.parse(latController.text),
                      longitude: double.parse(lngController.text),
                      radiusKm: int.parse(radiusController.text),
                      locationName: locationController.text.trim(),
                    );

                if (!context.mounted) {
                  return;
                }

                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lokalizacja zapisana.')),
                  );
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }
}
