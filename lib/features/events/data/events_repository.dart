import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/network/api_client.dart';
import 'package:sport_ap_mobile/core/network/paginated_response.dart';
import 'package:sport_ap_mobile/core/network/response_parser.dart';
import 'package:sport_ap_mobile/core/providers.dart';
import 'package:sport_ap_mobile/features/events/models/event_model.dart';

class EventFilters {
  const EventFilters({
    this.search,
    this.discipline,
    this.facilityId,
    this.city,
    this.dateFrom,
    this.dateTo,
    this.level,
    this.gender,
    this.isPaid,
    this.isPublic,
    this.lat,
    this.lng,
    this.radius,
    this.perPage = 15,
  });

  final String? search;
  final String? discipline;
  final String? facilityId;
  final String? city;
  final String? dateFrom;
  final String? dateTo;
  final String? level;
  final String? gender;
  final bool? isPaid;
  final bool? isPublic;
  final double? lat;
  final double? lng;
  final double? radius;
  final int perPage;

  Map<String, dynamic> toQueryMap({required int page}) {
    return <String, dynamic>{
      'search': search,
      'discipline': discipline,
      'facility_id': facilityId,
      'city': city,
      'date_from': dateFrom,
      'date_to': dateTo,
      'level': level,
      'gender': gender,
      'is_paid': isPaid,
      'is_public': isPublic,
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'per_page': perPage,
      'page': page,
    };
  }

  EventFilters copyWith({String? search}) {
    return EventFilters(
      search: search ?? this.search,
      discipline: discipline,
      facilityId: facilityId,
      city: city,
      dateFrom: dateFrom,
      dateTo: dateTo,
      level: level,
      gender: gender,
      isPaid: isPaid,
      isPublic: isPublic,
      lat: lat,
      lng: lng,
      radius: radius,
      perPage: perPage,
    );
  }
}

class EventsRepository {
  EventsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResponse<EventModel>> getEvents({
    EventFilters filters = const EventFilters(),
    int page = 1,
  }) {
    return _apiClient.getPaginated<EventModel>(
      '/events',
      EventModel.fromJson,
      queryParameters: filters.toQueryMap(page: page),
    );
  }

  Future<EventModel> getEvent(String id) async {
    final response = await _apiClient.get('/events/$id');
    final json = ResponseParser.dataMap(response);
    return EventModel.fromJson(json);
  }

  Future<void> joinEvent(String id) async {
    await _apiClient.post('/events/$id/join');
  }

  Future<void> leaveEvent(String id) async {
    await _apiClient.delete('/events/$id/leave');
  }

  Future<EventModel> createEvent(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('/events', data: payload);
    final json = ResponseParser.dataMap(response);
    return EventModel.fromJson(json);
  }

  Future<EventModel> updateEvent(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.patch('/events/$id', data: payload);
    final json = ResponseParser.dataMap(response);
    return EventModel.fromJson(json);
  }

  Future<void> deleteEvent(String id) {
    return _apiClient.delete('/events/$id');
  }
}

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.watch(apiClientProvider));
});

final eventDetailProvider = FutureProvider.family<EventModel, String>((
  ref,
  id,
) {
  return ref.watch(eventsRepositoryProvider).getEvent(id);
});

final eventJoinedProvider = Provider.family<bool?, EventModel>((ref, event) {
  return event.joined;
});
