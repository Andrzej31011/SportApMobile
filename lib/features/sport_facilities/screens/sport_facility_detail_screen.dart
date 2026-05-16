import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/widgets/app_error_view.dart';
import 'package:sport_ap_mobile/core/widgets/app_loading_view.dart';
import 'package:sport_ap_mobile/features/sport_facilities/data/sport_facilities_repository.dart';

class SportFacilityDetailScreen extends ConsumerWidget {
  const SportFacilityDetailScreen({super.key, required this.facilityId});

  final String facilityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFacility = ref.watch(sportFacilityDetailProvider(facilityId));

    return Scaffold(
      appBar: AppBar(title: const Text('Szczegoly obiektu')),
      body: asyncFacility.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(sportFacilityDetailProvider(facilityId)),
        ),
        data: (facility) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(sportFacilityDetailProvider(facilityId)),
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
                        facility.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      _row('Opis', facility.description ?? '-'),
                      _row('Adres', facility.address ?? '-'),
                      _row('Miasto', facility.city ?? '-'),
                      _row('Email', facility.contactEmail ?? '-'),
                      _row('Telefon', facility.contactPhone ?? '-'),
                      _row('Platny', _yesNo(facility.isPaid)),
                      _row('Nawierzchnia', facility.surfaceType ?? '-'),
                      _row(
                        'Wspolrzedne',
                        '${facility.latitude ?? '-'}, ${facility.longitude ?? '-'}',
                      ),
                      _row('Szatnia', _yesNo(facility.hasLockerRoom)),
                      _row('Prysznice', _yesNo(facility.hasShowers)),
                      _row('Parking', _yesNo(facility.hasParking)),
                      _row('Oswietlenie', _yesNo(facility.hasLighting)),
                      _row('Indoor', _yesNo(facility.isIndoor)),
                      _row('Outdoor', _yesNo(facility.isOutdoor)),
                      _row('Godziny', facility.openingHours ?? '-'),
                      _row('Regulamin', facility.rules ?? '-'),
                      _row(
                        'Dyscypliny',
                        facility.disciplines.isEmpty
                            ? '-'
                            : facility.disciplines.join(', '),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
          SizedBox(width: 120, child: Text('$label:')),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _yesNo(bool? value) {
    if (value == null) {
      return '-';
    }
    return value ? 'Tak' : 'Nie';
  }
}
