import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/features/dictionaries/data/dictionaries_repository.dart';
import 'package:sport_ap_mobile/features/dictionaries/models/dictionary_item_model.dart';
import 'package:sport_ap_mobile/features/dictionaries/models/discipline_model.dart';

final disciplinesProvider = FutureProvider<List<DisciplineModel>>((ref) {
  return ref.watch(dictionariesRepositoryProvider).getDisciplines();
});

final levelsProvider = FutureProvider<List<DictionaryItemModel>>((ref) {
  return ref.watch(dictionariesRepositoryProvider).getLevels();
});

final gendersProvider = FutureProvider<List<DictionaryItemModel>>((ref) {
  return ref.watch(dictionariesRepositoryProvider).getGenders();
});

final sportsProvider = FutureProvider<List<DictionaryItemModel>>((ref) {
  return ref.watch(dictionariesRepositoryProvider).getSports();
});

final dictionariesProvider =
    FutureProvider<Map<String, List<DictionaryItemModel>>>((ref) {
      return ref.watch(dictionariesRepositoryProvider).getDictionaries();
    });
