import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class UserChallengeModel {
  const UserChallengeModel({
    required this.id,
    this.status,
    this.message,
    this.discipline,
    this.locationName,
    this.challengerNick,
    this.challengedNick,
    this.terms = const <UserChallengeTerm>[],
    this.comments = const <UserChallengeComment>[],
  });

  final String id;
  final String? status;
  final String? message;
  final String? discipline;
  final String? locationName;
  final String? challengerNick;
  final String? challengedNick;
  final List<UserChallengeTerm> terms;
  final List<UserChallengeComment> comments;

  factory UserChallengeModel.fromJson(Map<String, dynamic> json) {
    final challenger = JsonUtils.asMap(json['challenger']);
    final challenged = JsonUtils.asMap(json['challenged']);

    final terms = JsonUtils.asList(
      json['terms'] ?? json['proposed_terms'],
    ).map((item) => UserChallengeTerm.fromJson(JsonUtils.asMap(item))).toList();

    final comments = JsonUtils.asList(json['comments'])
        .map((item) => UserChallengeComment.fromJson(JsonUtils.asMap(item)))
        .toList();

    return UserChallengeModel(
      id:
          JsonUtils.asString(json['id']) ??
          JsonUtils.asString(json['uuid']) ??
          '',
      status: JsonUtils.asString(json['status']),
      message: JsonUtils.asString(json['message']),
      discipline:
          JsonUtils.asString(json['discipline_name']) ??
          JsonUtils.asString(JsonUtils.asMap(json['discipline'])['name']),
      locationName: JsonUtils.asString(json['location_name']),
      challengerNick: JsonUtils.asString(challenger['nick']),
      challengedNick: JsonUtils.asString(challenged['nick']),
      terms: terms,
      comments: comments,
    );
  }
}

class UserChallengeTerm {
  const UserChallengeTerm({
    required this.id,
    this.startsAt,
    this.endsAt,
    this.note,
    this.selected,
  });

  final String id;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? note;
  final bool? selected;

  factory UserChallengeTerm.fromJson(Map<String, dynamic> json) {
    return UserChallengeTerm(
      id:
          JsonUtils.asString(json['id']) ??
          JsonUtils.asString(json['uuid']) ??
          '',
      startsAt: JsonUtils.asDateTime(json['starts_at']),
      endsAt: JsonUtils.asDateTime(json['ends_at']),
      note: JsonUtils.asString(json['note']),
      selected:
          JsonUtils.asBool(json['is_selected']) ??
          JsonUtils.asBool(json['selected']) ??
          JsonUtils.asBool(json['selected_by_challenged_user']),
    );
  }
}

class UserChallengeComment {
  const UserChallengeComment({
    required this.id,
    this.author,
    this.body,
    this.termId,
    this.createdAt,
  });

  final String id;
  final String? author;
  final String? body;
  final String? termId;
  final DateTime? createdAt;

  factory UserChallengeComment.fromJson(Map<String, dynamic> json) {
    final authorMap = JsonUtils.asMap(json['author']);

    return UserChallengeComment(
      id:
          JsonUtils.asString(json['id']) ??
          JsonUtils.asString(json['uuid']) ??
          '',
      author:
          JsonUtils.asString(authorMap['nick']) ??
          JsonUtils.asString(json['author_name']),
      body: JsonUtils.asString(json['body']),
      termId: JsonUtils.asString(json['term_id']),
      createdAt: JsonUtils.asDateTime(json['created_at']),
    );
  }
}
