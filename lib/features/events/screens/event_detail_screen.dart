import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sport_ap_mobile/core/widgets/app_error_view.dart';
import 'package:sport_ap_mobile/core/widgets/app_loading_view.dart';
import 'package:sport_ap_mobile/features/events/data/events_repository.dart';
import 'package:sport_ap_mobile/features/events/models/event_model.dart';
import 'package:sport_ap_mobile/features/events/state/events_list_controller.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _actionLoading = false;

  Future<void> _toggleJoin(EventModel event) async {
    setState(() => _actionLoading = true);
    try {
      final repository = ref.read(eventsRepositoryProvider);
      if (event.joined == true) {
        await repository.leaveEvent(event.id);
      } else {
        await repository.joinEvent(event.id);
      }

      ref.invalidate(eventDetailProvider(widget.eventId));
      ref.invalidate(eventsListControllerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              event.joined == true
                  ? 'Opuszczono wydarzenie.'
                  : 'Dolaczono do wydarzenia.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncEvent = ref.watch(eventDetailProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('Szczegoly wydarzenia')),
      body: asyncEvent.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(eventDetailProvider(widget.eventId)),
        ),
        data: (event) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(eventDetailProvider(widget.eventId)),
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
                        event.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      _row('Opis', event.description ?? '-'),
                      _row('Dyscyplina', event.disciplineName ?? '-'),
                      _row('Obiekt', event.facilityName ?? '-'),
                      _row('Poziom', event.level ?? '-'),
                      _row('Plec', event.gender ?? '-'),
                      _row('Publiczne', _yesNo(event.isPublic)),
                      _row('Platne', _yesNo(event.isPaid)),
                      _row('Cena', event.price?.toStringAsFixed(2) ?? '-'),
                      _row('Start', _formatDate(event.startTime)),
                      _row('Koniec', _formatDate(event.endTime)),
                      _row(
                        'Uczestnicy',
                        '${event.participantsCount ?? '-'} / ${event.participantLimit ?? '-'}',
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _actionLoading
                              ? null
                              : () => _toggleJoin(event),
                          child: _actionLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(event.joined == true ? 'Opusc' : 'Dolacz'),
                        ),
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
          SizedBox(width: 110, child: Text('$label:')),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return DateFormat('dd.MM.yyyy HH:mm').format(date.toLocal());
  }

  String _yesNo(bool? value) {
    if (value == null) {
      return '-';
    }
    return value ? 'Tak' : 'Nie';
  }
}
