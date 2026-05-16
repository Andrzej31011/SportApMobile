import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class EventModel {
  const EventModel({
    required this.id,
    required this.name,
    this.description,
    this.disciplineName,
    this.facilityName,
    this.city,
    this.level,
    this.gender,
    this.isPublic,
    this.isPaid,
    this.price,
    this.startTime,
    this.endTime,
    this.participantLimit,
    this.participantsCount,
    this.joined,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String? description;
  final String? disciplineName;
  final String? facilityName;
  final String? city;
  final String? level;
  final String? gender;
  final bool? isPublic;
  final bool? isPaid;
  final double? price;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? participantLimit;
  final int? participantsCount;
  final bool? joined;
  final double? latitude;
  final double? longitude;

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final discipline = JsonUtils.asMap(json['discipline']);
    final facility = JsonUtils.asMap(
      json['facility'] ?? json['sport_facility'],
    );

    return EventModel(
      id:
          JsonUtils.asString(json['id']) ??
          JsonUtils.asString(json['uuid']) ??
          '',
      name: JsonUtils.asString(json['name']) ?? 'Bez nazwy',
      description: JsonUtils.asString(json['description']),
      disciplineName:
          JsonUtils.asString(json['discipline_name']) ??
          JsonUtils.asString(discipline['name']),
      facilityName:
          JsonUtils.asString(json['facility_name']) ??
          JsonUtils.asString(json['sport_facility_name']) ??
          JsonUtils.asString(facility['name']),
      city:
          JsonUtils.asString(json['city']) ??
          JsonUtils.asString(facility['city']) ??
          JsonUtils.asString(facility['address']),
      level: JsonUtils.asString(json['level']),
      gender: JsonUtils.asString(json['gender']),
      isPublic: JsonUtils.asBool(json['is_public']),
      isPaid: JsonUtils.asBool(json['is_paid']),
      price: JsonUtils.asDouble(json['price']),
      startTime: JsonUtils.asDateTime(json['start_time']),
      endTime: JsonUtils.asDateTime(json['end_time']),
      participantLimit: JsonUtils.asInt(json['participant_limit']),
      participantsCount:
          JsonUtils.asInt(json['participants_count']) ??
          JsonUtils.asInt(json['participant_count']),
      joined:
          JsonUtils.asBool(json['is_joined']) ??
          JsonUtils.asBool(json['joined']) ??
          JsonUtils.asBool(json['is_participant']),
      latitude:
          JsonUtils.asDouble(json['latitude']) ??
          JsonUtils.asDouble(json['geo_lat']) ??
          JsonUtils.asDouble(facility['latitude']) ??
          JsonUtils.asDouble(facility['geo_lat']),
      longitude:
          JsonUtils.asDouble(json['longitude']) ??
          JsonUtils.asDouble(json['geo_long']) ??
          JsonUtils.asDouble(facility['longitude']) ??
          JsonUtils.asDouble(facility['geo_long']),
    );
  }

  EventModel copyWith({bool? joined}) {
    return EventModel(
      id: id,
      name: name,
      description: description,
      disciplineName: disciplineName,
      facilityName: facilityName,
      city: city,
      level: level,
      gender: gender,
      isPublic: isPublic,
      isPaid: isPaid,
      price: price,
      startTime: startTime,
      endTime: endTime,
      participantLimit: participantLimit,
      participantsCount: participantsCount,
      joined: joined ?? this.joined,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
