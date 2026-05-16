import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class FacilityDisciplineModel {
  const FacilityDisciplineModel({
    required this.id,
    required this.disciplineSportFacilityId,
    this.disciplineSportFacilityIdInt,
    this.disciplineId,
    this.disciplineName,
    this.sportFacilityId,
    this.sportFacilityName,
  });

  final String id;
  final String disciplineSportFacilityId;
  final int? disciplineSportFacilityIdInt;
  final String? disciplineId;
  final String? disciplineName;
  final String? sportFacilityId;
  final String? sportFacilityName;

  Object get requestDisciplineSportFacilityId =>
      disciplineSportFacilityIdInt ?? disciplineSportFacilityId;

  factory FacilityDisciplineModel.fromJson(Map<String, dynamic> json) {
    final discipline = JsonUtils.asMap(json['discipline']);
    final sportFacility = JsonUtils.asMap(json['sport_facility']);

    final rawRelationId = json.containsKey('discipline_sport_facility_id')
        ? json['discipline_sport_facility_id']
        : json['id'];

    final relationIdString =
        JsonUtils.asString(rawRelationId) ??
        JsonUtils.asString(json['id']) ??
        '';

    return FacilityDisciplineModel(
      id: JsonUtils.asString(json['id']) ?? relationIdString,
      disciplineSportFacilityId: relationIdString,
      disciplineSportFacilityIdInt: JsonUtils.asInt(rawRelationId),
      disciplineId: JsonUtils.asString(discipline['id']),
      disciplineName: JsonUtils.asString(discipline['name']),
      sportFacilityId: JsonUtils.asString(sportFacility['id']),
      sportFacilityName: JsonUtils.asString(sportFacility['name']),
    );
  }
}
