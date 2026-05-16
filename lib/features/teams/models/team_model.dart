import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class TeamModel {
  const TeamModel({
    required this.id,
    required this.name,
    this.description,
    this.establishmentDate,
    this.level,
    this.style,
    this.disciplines = const <String>[],
    this.membersCount,
    this.joined,
  });

  final String id;
  final String name;
  final String? description;
  final DateTime? establishmentDate;
  final String? level;
  final String? style;
  final List<String> disciplines;
  final int? membersCount;
  final bool? joined;

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    final disciplinesRaw = JsonUtils.asList(
      json['disciplines'] ?? json['team_disciplines'],
    );
    final membership = JsonUtils.asMap(json['current_user_membership']);
    final firstDiscipline = disciplinesRaw.isNotEmpty
        ? JsonUtils.asMap(disciplinesRaw.first)
        : <String, dynamic>{};

    final disciplineNames = disciplinesRaw.map((item) {
      final map = JsonUtils.asMap(item);
      final nested = JsonUtils.asMap(map['discipline']);
      return JsonUtils.asString(map['name']) ??
          JsonUtils.asString(nested['name']) ??
          item.toString();
    }).toList();

    return TeamModel(
      id:
          JsonUtils.asString(json['id']) ??
          JsonUtils.asString(json['uuid']) ??
          '',
      name: JsonUtils.asString(json['name']) ?? 'Bez nazwy',
      description: JsonUtils.asString(json['description']),
      establishmentDate: JsonUtils.asDateTime(
        json['establishment_date'] ?? json['created_at'],
      ),
      level:
          JsonUtils.asString(json['level']) ??
          JsonUtils.asString(firstDiscipline['level']),
      style:
          JsonUtils.asString(json['style']) ??
          JsonUtils.asString(firstDiscipline['style']),
      disciplines: disciplineNames,
      membersCount:
          JsonUtils.asInt(json['members_count']) ??
          JsonUtils.asInt(json['team_members_count']),
      joined:
          JsonUtils.asBool(json['is_member']) ??
          JsonUtils.asBool(json['joined']) ??
          (membership.isNotEmpty ? true : null),
    );
  }

  TeamModel copyWith({bool? joined}) {
    return TeamModel(
      id: id,
      name: name,
      description: description,
      establishmentDate: establishmentDate,
      level: level,
      style: style,
      disciplines: disciplines,
      membersCount: membersCount,
      joined: joined ?? this.joined,
    );
  }
}
