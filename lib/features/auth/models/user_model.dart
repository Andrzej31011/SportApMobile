import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.nick,
    this.gender,
    this.birthYear,
    this.avatarUrl,
    this.locationName,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.marketingConsent,
    this.gdprConsent,
    this.regulationsConsent,
    this.preferredSports = const <String>[],
  });

  final String id;
  final String nick;
  final String? gender;
  final int? birthYear;
  final String? avatarUrl;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final int? radiusKm;
  final bool? marketingConsent;
  final bool? gdprConsent;
  final bool? regulationsConsent;
  final List<String> preferredSports;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final location = JsonUtils.asMap(json['location']);
    final preferences = JsonUtils.asList(json['preferences']);

    return UserModel(
      id:
          JsonUtils.asString(json['id']) ??
          JsonUtils.asString(json['uuid']) ??
          '',
      nick:
          JsonUtils.asString(json['nick']) ??
          JsonUtils.asString(json['name']) ??
          'Uzytkownik',
      gender: JsonUtils.asString(json['gender']),
      birthYear: JsonUtils.asInt(json['birth_year']),
      avatarUrl: JsonUtils.asString(json['avatar_url']),
      locationName:
          JsonUtils.asString(json['location_name']) ??
          JsonUtils.asString(location['location_name']) ??
          JsonUtils.asString(location['name']) ??
          JsonUtils.asString(location['city']),
      latitude:
          JsonUtils.asDouble(json['latitude']) ??
          JsonUtils.asDouble(json['geo_lat']) ??
          JsonUtils.asDouble(location['lat']) ??
          JsonUtils.asDouble(location['latitude']) ??
          JsonUtils.asDouble(location['geo_lat']),
      longitude:
          JsonUtils.asDouble(json['longitude']) ??
          JsonUtils.asDouble(json['geo_long']) ??
          JsonUtils.asDouble(location['lng']) ??
          JsonUtils.asDouble(location['longitude']) ??
          JsonUtils.asDouble(location['geo_long']),
      radiusKm:
          JsonUtils.asInt(json['radius_km']) ??
          JsonUtils.asInt(location['radius_km']),
      marketingConsent: JsonUtils.asBool(json['marketing_consent']),
      gdprConsent: JsonUtils.asBool(json['gdpr_consent']),
      regulationsConsent: JsonUtils.asBool(json['regulations_consent']),
      preferredSports: _parsePreferredSports(json, preferences),
    );
  }

  static List<String> _parsePreferredSports(
    Map<String, dynamic> json,
    List<dynamic> preferences,
  ) {
    final direct = JsonUtils.asStringList(
      json['preferred_sports'] ?? json['sports'],
    );
    if (direct.isNotEmpty) {
      return direct;
    }

    final names = <String>[];
    for (final item in preferences) {
      final map = JsonUtils.asMap(item);
      final discipline = JsonUtils.asMap(map['discipline']);
      final name =
          JsonUtils.asString(map['name']) ??
          JsonUtils.asString(discipline['name']);
      if (name != null && name.trim().isNotEmpty) {
        names.add(name);
      }
    }
    return names;
  }

  Map<String, dynamic> toProfileUpdateJson() {
    return <String, dynamic>{
      'nick': nick,
      'gender': gender,
      'birth_year': birthYear,
      'avatar_url': avatarUrl,
      'marketing_consent': marketingConsent,
      'gdpr_consent': gdprConsent,
      'regulations_consent': regulationsConsent,
    };
  }

  UserModel copyWith({
    String? id,
    String? nick,
    String? gender,
    int? birthYear,
    String? avatarUrl,
    String? locationName,
    double? latitude,
    double? longitude,
    int? radiusKm,
    bool? marketingConsent,
    bool? gdprConsent,
    bool? regulationsConsent,
    List<String>? preferredSports,
  }) {
    return UserModel(
      id: id ?? this.id,
      nick: nick ?? this.nick,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      gdprConsent: gdprConsent ?? this.gdprConsent,
      regulationsConsent: regulationsConsent ?? this.regulationsConsent,
      preferredSports: preferredSports ?? this.preferredSports,
    );
  }
}
