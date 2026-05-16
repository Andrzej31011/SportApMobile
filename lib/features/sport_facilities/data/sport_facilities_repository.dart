import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/network/api_client.dart';
import 'package:sport_ap_mobile/core/network/paginated_response.dart';
import 'package:sport_ap_mobile/core/network/response_parser.dart';
import 'package:sport_ap_mobile/core/providers.dart';
import 'package:sport_ap_mobile/core/utils/json_utils.dart';
import 'package:sport_ap_mobile/features/sport_facilities/models/discipline_sport_facility_model.dart';
import 'package:sport_ap_mobile/features/sport_facilities/models/facility_discipline_model.dart';
import 'package:sport_ap_mobile/features/sport_facilities/models/sport_facility_model.dart';

class SportFacilityFilters {
  const SportFacilityFilters({
    this.search,
    this.city,
    this.discipline,
    this.lat,
    this.lng,
    this.radius,
    this.isPaid,
    this.hasLighting,
    this.hasLockerRoom,
    this.hasShowers,
    this.hasParking,
    this.isIndoor,
    this.isOutdoor,
    this.perPage = 15,
  });

  final String? search;
  final String? city;
  final String? discipline;
  final double? lat;
  final double? lng;
  final double? radius;
  final bool? isPaid;
  final bool? hasLighting;
  final bool? hasLockerRoom;
  final bool? hasShowers;
  final bool? hasParking;
  final bool? isIndoor;
  final bool? isOutdoor;
  final int perPage;

  Map<String, dynamic> toQueryMap({required int page}) {
    return <String, dynamic>{
      'search': search,
      'city': city,
      'discipline': discipline,
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'is_paid': isPaid,
      'has_lighting': hasLighting,
      'has_locker_room': hasLockerRoom,
      'has_showers': hasShowers,
      'has_parking': hasParking,
      'is_indoor': isIndoor,
      'is_outdoor': isOutdoor,
      'per_page': perPage,
      'page': page,
    };
  }

  SportFacilityFilters copyWith({String? search}) {
    return SportFacilityFilters(
      search: search ?? this.search,
      city: city,
      discipline: discipline,
      lat: lat,
      lng: lng,
      radius: radius,
      isPaid: isPaid,
      hasLighting: hasLighting,
      hasLockerRoom: hasLockerRoom,
      hasShowers: hasShowers,
      hasParking: hasParking,
      isIndoor: isIndoor,
      isOutdoor: isOutdoor,
      perPage: perPage,
    );
  }
}

class SportFacilitiesRepository {
  SportFacilitiesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedResponse<SportFacilityModel>> getFacilities({
    SportFacilityFilters filters = const SportFacilityFilters(),
    int page = 1,
  }) {
    return _apiClient.getPaginated<SportFacilityModel>(
      '/sport-facilities',
      SportFacilityModel.fromJson,
      queryParameters: filters.toQueryMap(page: page),
    );
  }

  Future<SportFacilityModel> getFacility(String id) async {
    final response = await _apiClient.get('/sport-facilities/$id');
    final json = ResponseParser.dataMap(response);
    return SportFacilityModel.fromJson(json);
  }

  Future<SportFacilityModel> createFacility(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.post('/sport-facilities', data: payload);
    final json = ResponseParser.dataMap(response);
    return SportFacilityModel.fromJson(json);
  }

  Future<List<FacilityDisciplineModel>> getFacilityDisciplines(
    String facilityId,
  ) async {
    final response = await _apiClient.get(
      '/sport-facilities/$facilityId/disciplines',
    );
    final list = ResponseParser.dataList(response);
    return list
        .map((item) => FacilityDisciplineModel.fromJson(JsonUtils.asMap(item)))
        .toList();
  }

  Future<List<DisciplineSportFacilityModel>> getSportFacilitiesForDiscipline(
    String disciplineId,
  ) async {
    final response = await _apiClient.get(
      '/disciplines/$disciplineId/sport-facilities',
    );
    final list = ResponseParser.dataList(response);
    return list
        .map(
          (item) =>
              DisciplineSportFacilityModel.fromJson(JsonUtils.asMap(item)),
        )
        .toList();
  }
}

final sportFacilitiesRepositoryProvider = Provider<SportFacilitiesRepository>((
  ref,
) {
  return SportFacilitiesRepository(ref.watch(apiClientProvider));
});

final sportFacilityDetailProvider =
    FutureProvider.family<SportFacilityModel, String>((ref, id) {
      return ref.watch(sportFacilitiesRepositoryProvider).getFacility(id);
    });
