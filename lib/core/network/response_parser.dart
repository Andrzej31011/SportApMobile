import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class ResponseParser {
  const ResponseParser._();

  static dynamic dataOrRaw(dynamic response) {
    if (response is Map || response is Map<String, dynamic>) {
      final map = JsonUtils.asMap(response);
      if (map.containsKey('data')) {
        return map['data'];
      }
      return map;
    }
    return response;
  }

  static List<dynamic> dataList(dynamic response) {
    final raw = dataOrRaw(response);
    return JsonUtils.asList(raw);
  }

  static Map<String, dynamic> dataMap(dynamic response) {
    final raw = dataOrRaw(response);
    return JsonUtils.asMap(raw);
  }
}
