import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/features/auth/models/user_model.dart';
import 'package:sport_ap_mobile/features/sport_facilities/data/sport_facilities_repository.dart';
import 'package:sport_ap_mobile/features/sport_facilities/models/discipline_sport_facility_model.dart';
import 'package:sport_ap_mobile/features/sport_facilities/models/facility_discipline_model.dart';
import 'package:sport_ap_mobile/features/sport_facilities/models/sport_facility_model.dart';
import 'package:sport_ap_mobile/features/teams/data/teams_repository.dart';
import 'package:sport_ap_mobile/features/teams/models/team_model.dart';
import 'package:sport_ap_mobile/features/users/data/users_repository.dart';

final usersLookupProvider = FutureProvider<List<UserModel>>((ref) async {
  final response = await ref
      .watch(usersRepositoryProvider)
      .getUsers(perPage: 100);
  return response.data;
});

final teamsLookupProvider = FutureProvider<List<TeamModel>>((ref) async {
  final response = await ref
      .watch(teamsRepositoryProvider)
      .getTeams(page: 1, filters: const TeamFilters(perPage: 100));
  return response.data;
});

final sportFacilitiesLookupProvider = FutureProvider<List<SportFacilityModel>>((
  ref,
) async {
  final response = await ref
      .watch(sportFacilitiesRepositoryProvider)
      .getFacilities(
        page: 1,
        filters: const SportFacilityFilters(perPage: 100),
      );
  return response.data;
});

final facilityDisciplinesProvider =
    FutureProvider.family<List<FacilityDisciplineModel>, String>((
      ref,
      facilityId,
    ) async {
      return ref
          .watch(sportFacilitiesRepositoryProvider)
          .getFacilityDisciplines(facilityId);
    });

final disciplineSportFacilitiesProvider =
    FutureProvider.family<List<DisciplineSportFacilityModel>, String>((
      ref,
      disciplineId,
    ) async {
      return ref
          .watch(sportFacilitiesRepositoryProvider)
          .getSportFacilitiesForDiscipline(disciplineId);
    });
