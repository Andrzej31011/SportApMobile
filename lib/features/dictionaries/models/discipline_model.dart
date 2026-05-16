import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class DisciplineModel {
  const DisciplineModel({
    required this.id,
    required this.name,
    this.sportId,
    this.sportName,
  });

  final int id;
  final String name;
  final int? sportId;
  final String? sportName;

  factory DisciplineModel.fromJson(Map<String, dynamic> json) {
    return DisciplineModel(
      id: JsonUtils.asInt(json['id']) ?? 0,
      name: JsonUtils.asString(json['name']) ?? 'Brak nazwy',
      sportId: JsonUtils.asInt(json['sport_id']),
      sportName: JsonUtils.asString(json['sport_name']),
    );
  }
}
