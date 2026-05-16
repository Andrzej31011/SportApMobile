import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class MapMarkerModel {
  const MapMarkerModel({
    required this.id,
    required this.type,
    this.name,
    this.lat,
    this.lng,
    this.discipline,
    this.disciplineSlug,
    this.startsAt,
    this.isPaid,
    this.participantsCount,
    this.participantLimit,
  });

  final String id;
  final String type;
  final String? name;
  final double? lat;
  final double? lng;
  final String? discipline;
  final String? disciplineSlug;
  final DateTime? startsAt;
  final bool? isPaid;
  final int? participantsCount;
  final int? participantLimit;

  bool get isEvent => type == 'event';
  bool get isFacility => type == 'facility';
  bool get hasCoordinates => lat != null && lng != null;
  String get title =>
      (name == null || name!.trim().isEmpty) ? 'Marker $id' : name!;
  double get latitude => lat ?? 0;
  double get longitude => lng ?? 0;

  factory MapMarkerModel.fromJson(Map<String, dynamic> json) {
    final rawType =
        JsonUtils.asString(json['type']) ??
        JsonUtils.asString(json['marker_type']) ??
        JsonUtils.asString(json['resource_type']) ??
        'unknown';

    return MapMarkerModel(
      id:
          JsonUtils.asString(json['id']) ??
          JsonUtils.asString(json['uuid']) ??
          JsonUtils.asString(json['resource_id']) ??
          '',
      type: rawType.trim().toLowerCase(),
      name:
          JsonUtils.asString(json['name']) ?? JsonUtils.asString(json['title']),
      lat:
          JsonUtils.asDouble(json['lat']) ??
          JsonUtils.asDouble(json['latitude']) ??
          JsonUtils.asDouble(json['geo_lat']),
      lng:
          JsonUtils.asDouble(json['lng']) ??
          JsonUtils.asDouble(json['longitude']) ??
          JsonUtils.asDouble(json['geo_long']),
      discipline:
          JsonUtils.asString(json['discipline']) ??
          JsonUtils.asString(json['discipline_name']),
      disciplineSlug:
          JsonUtils.asString(json['discipline_slug']) ??
          JsonUtils.asString(json['disciplineSlug']),
      startsAt:
          JsonUtils.asDateTime(json['starts_at']) ??
          JsonUtils.asDateTime(json['start_time']),
      isPaid: JsonUtils.asBool(json['is_paid']),
      participantsCount: JsonUtils.asInt(json['participants_count']),
      participantLimit:
          JsonUtils.asInt(json['participant_limit']) ??
          JsonUtils.asInt(json['participants_limit']),
    );
  }
}
