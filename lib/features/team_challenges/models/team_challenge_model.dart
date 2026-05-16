import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class TeamChallengeModel {
  const TeamChallengeModel({
    required this.id,
    this.status,
    this.message,
    this.teamName,
    this.opponentName,
    this.location,
    this.proposedDates = const <DateTime>[],
    this.comments = const <TeamChallengeComment>[],
  });

  final String id;
  final String? status;
  final String? message;
  final String? teamName;
  final String? opponentName;
  final String? location;
  final List<DateTime> proposedDates;
  final List<TeamChallengeComment> comments;

  factory TeamChallengeModel.fromJson(Map<String, dynamic> json) {
    final team = JsonUtils.asMap(json['team']);
    final opponent = JsonUtils.asMap(json['opponent']);

    final proposedDates =
        JsonUtils.asList(json['proposed_dates'] ?? json['terms'])
            .map((item) {
              if (item is String) {
                return DateTime.tryParse(item);
              }

              final map = JsonUtils.asMap(item);
              return JsonUtils.asDateTime(map['value']) ??
                  JsonUtils.asDateTime(map['starts_at']);
            })
            .whereType<DateTime>()
            .toList();

    final comments = JsonUtils.asList(json['comments'])
        .map((item) => TeamChallengeComment.fromJson(JsonUtils.asMap(item)))
        .toList();

    return TeamChallengeModel(
      id:
          JsonUtils.asString(json['id']) ??
          JsonUtils.asString(json['uuid']) ??
          '',
      status: JsonUtils.asString(json['status']),
      message: JsonUtils.asString(json['message']),
      teamName: JsonUtils.asString(team['name']),
      opponentName: JsonUtils.asString(opponent['name']),
      location:
          JsonUtils.asString(json['location']) ??
          JsonUtils.asString(json['location_name']),
      proposedDates: proposedDates,
      comments: comments,
    );
  }
}

class TeamChallengeComment {
  const TeamChallengeComment({
    required this.id,
    this.author,
    this.body,
    this.termValue,
    this.createdAt,
  });

  final String id;
  final String? author;
  final String? body;
  final String? termValue;
  final DateTime? createdAt;

  factory TeamChallengeComment.fromJson(Map<String, dynamic> json) {
    final author = JsonUtils.asMap(json['author']);

    return TeamChallengeComment(
      id:
          JsonUtils.asString(json['id']) ??
          JsonUtils.asString(json['uuid']) ??
          '',
      author:
          JsonUtils.asString(author['nick']) ??
          JsonUtils.asString(json['author_name']),
      body: JsonUtils.asString(json['body']),
      termValue: JsonUtils.asString(json['term_value']),
      createdAt: JsonUtils.asDateTime(json['created_at']),
    );
  }
}
