import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class DictionaryItemModel {
  const DictionaryItemModel({
    required this.value,
    required this.label,
    this.id,
  });

  final String value;
  final String label;
  final int? id;

  factory DictionaryItemModel.fromJson(Map<String, dynamic> json) {
    final value =
        JsonUtils.asString(json['value']) ??
        JsonUtils.asString(json['key']) ??
        JsonUtils.asString(json['name']) ??
        '';

    final label =
        JsonUtils.asString(json['label']) ??
        JsonUtils.asString(json['name']) ??
        value;

    return DictionaryItemModel(
      id: JsonUtils.asInt(json['id']),
      value: value,
      label: label,
    );
  }
}
