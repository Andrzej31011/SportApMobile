import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/network/api_client.dart';
import 'package:sport_ap_mobile/core/network/response_parser.dart';
import 'package:sport_ap_mobile/core/providers.dart';
import 'package:sport_ap_mobile/core/utils/json_utils.dart';
import 'package:sport_ap_mobile/features/dictionaries/models/dictionary_item_model.dart';
import 'package:sport_ap_mobile/features/dictionaries/models/discipline_model.dart';

class DictionariesRepository {
  DictionariesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<DisciplineModel>> getDisciplines() async {
    final response = await _apiClient.get('/disciplines');
    return ResponseParser.dataList(
      response,
    ).map((item) => DisciplineModel.fromJson(JsonUtils.asMap(item))).toList();
  }

  Future<List<DictionaryItemModel>> getSports() async {
    return _loadDictionaryItems('/sports');
  }

  Future<List<DictionaryItemModel>> getLevels() async {
    return _loadDictionaryItems('/levels');
  }

  Future<List<DictionaryItemModel>> getGenders() async {
    return _loadDictionaryItems('/genders');
  }

  Future<Map<String, List<DictionaryItemModel>>> getDictionaries() async {
    final response = await _apiClient.get('/dictionaries');
    final map = ResponseParser.dataMap(response);

    final result = <String, List<DictionaryItemModel>>{};
    for (final entry in map.entries) {
      final list = JsonUtils.asList(entry.value)
          .map((item) => DictionaryItemModel.fromJson(JsonUtils.asMap(item)))
          .toList();
      result[entry.key] = list;
    }

    return result;
  }

  Future<List<DictionaryItemModel>> _loadDictionaryItems(String path) async {
    final response = await _apiClient.get(path);
    return ResponseParser.dataList(response)
        .map((item) => DictionaryItemModel.fromJson(JsonUtils.asMap(item)))
        .toList();
  }
}

final dictionariesRepositoryProvider = Provider<DictionariesRepository>((ref) {
  return DictionariesRepository(ref.watch(apiClientProvider));
});
