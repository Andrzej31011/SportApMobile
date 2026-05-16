import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class SportFacilityModel {
  const SportFacilityModel({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.city,
    this.contactEmail,
    this.contactPhone,
    this.isPaid,
    this.latitude,
    this.longitude,
    this.surfaceType,
    this.hasLighting,
    this.hasLockerRoom,
    this.hasShowers,
    this.hasParking,
    this.isIndoor,
    this.isOutdoor,
    this.openingHours,
    this.rules,
    this.disciplines = const <String>[],
  });

  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final String? contactEmail;
  final String? contactPhone;
  final bool? isPaid;
  final double? latitude;
  final double? longitude;
  final String? surfaceType;
  final bool? hasLighting;
  final bool? hasLockerRoom;
  final bool? hasShowers;
  final bool? hasParking;
  final bool? isIndoor;
  final bool? isOutdoor;
  final String? openingHours;
  final String? rules;
  final List<String> disciplines;

  factory SportFacilityModel.fromJson(Map<String, dynamic> json) {
    final disciplinesRaw = JsonUtils.asList(json['disciplines']);
    final disciplineNames = disciplinesRaw.map((item) {
      final map = JsonUtils.asMap(item);
      return JsonUtils.asString(map['name']) ?? item.toString();
    }).toList();

    return SportFacilityModel(
      id:
          JsonUtils.asString(json['id']) ??
          JsonUtils.asString(json['uuid']) ??
          '',
      name: JsonUtils.asString(json['name']) ?? 'Bez nazwy',
      description: JsonUtils.asString(json['description']),
      address: JsonUtils.asString(json['address']),
      city: JsonUtils.asString(json['city']),
      contactEmail: JsonUtils.asString(json['contact_email']),
      contactPhone: JsonUtils.asString(json['contact_phone']),
      isPaid: JsonUtils.asBool(json['is_paid']),
      latitude:
          JsonUtils.asDouble(json['geo_lat']) ??
          JsonUtils.asDouble(json['lat']) ??
          JsonUtils.asDouble(json['latitude']),
      longitude:
          JsonUtils.asDouble(json['geo_long']) ??
          JsonUtils.asDouble(json['lng']) ??
          JsonUtils.asDouble(json['longitude']),
      surfaceType: JsonUtils.asString(json['surface_type']),
      hasLighting: JsonUtils.asBool(json['has_lighting']),
      hasLockerRoom: JsonUtils.asBool(json['has_locker_room']),
      hasShowers: JsonUtils.asBool(json['has_showers']),
      hasParking: JsonUtils.asBool(json['has_parking']),
      isIndoor: JsonUtils.asBool(json['is_indoor']),
      isOutdoor: JsonUtils.asBool(json['is_outdoor']),
      openingHours: JsonUtils.asString(json['opening_hours']),
      rules: JsonUtils.asString(json['rules']),
      disciplines: disciplineNames,
    );
  }
}
