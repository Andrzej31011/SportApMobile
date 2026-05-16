import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class DisciplineSportFacilityModel {
  const DisciplineSportFacilityModel({
    required this.id,
    required this.disciplineSportFacilityId,
    this.disciplineSportFacilityIdInt,
    this.disciplineId,
    this.disciplineName,
    this.sportFacilityId,
    this.sportFacilityName,
    this.sportFacilityAddress,
    this.sportFacilityCity,
    this.sportFacilityLatitude,
    this.sportFacilityLongitude,
  });

  final String id;
  final String disciplineSportFacilityId;
  final int? disciplineSportFacilityIdInt;
  final String? disciplineId;
  final String? disciplineName;
  final String? sportFacilityId;
  final String? sportFacilityName;
  final String? sportFacilityAddress;
  final String? sportFacilityCity;
  final double? sportFacilityLatitude;
  final double? sportFacilityLongitude;

  Object get requestDisciplineSportFacilityId =>
      disciplineSportFacilityIdInt ?? disciplineSportFacilityId;

  String get facilityDisplayName {
    final name = (sportFacilityName ?? '').trim();
    final city = (sportFacilityCity ?? '').trim();
    if (name.isEmpty && city.isEmpty) {
      return 'Obiekt';
    }
    if (city.isEmpty) {
      return name;
    }
    if (name.isEmpty) {
      return city;
    }
    return '$name ($city)';
  }

  factory DisciplineSportFacilityModel.fromJson(Map<String, dynamic> json) {
    final discipline = JsonUtils.asMap(json['discipline']);
    final sportFacility = JsonUtils.asMap(json['sport_facility']);

    final rawRelationId = json.containsKey('discipline_sport_facility_id')
        ? json['discipline_sport_facility_id']
        : json['id'];

    final relationIdString =
        JsonUtils.asString(rawRelationId) ??
        JsonUtils.asString(json['id']) ??
        '';

    return DisciplineSportFacilityModel(
      id: JsonUtils.asString(json['id']) ?? relationIdString,
      disciplineSportFacilityId: relationIdString,
      disciplineSportFacilityIdInt: JsonUtils.asInt(rawRelationId),
      disciplineId: JsonUtils.asString(discipline['id']),
      disciplineName: JsonUtils.asString(discipline['name']),
      sportFacilityId: JsonUtils.asString(sportFacility['id']),
      sportFacilityName: JsonUtils.asString(sportFacility['name']),
      sportFacilityAddress: JsonUtils.asString(sportFacility['address']),
      sportFacilityCity: JsonUtils.asString(sportFacility['city']),
      sportFacilityLatitude: JsonUtils.asDouble(
        sportFacility['geo_lat'] ??
            sportFacility['lat'] ??
            sportFacility['latitude'],
      ),
      sportFacilityLongitude: JsonUtils.asDouble(
        sportFacility['geo_long'] ??
            sportFacility['lng'] ??
            sportFacility['longitude'],
      ),
    );
  }
}
