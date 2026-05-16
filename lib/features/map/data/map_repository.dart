import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/network/api_client.dart';
import 'package:sport_ap_mobile/core/network/response_parser.dart';
import 'package:sport_ap_mobile/core/providers.dart';
import 'package:sport_ap_mobile/core/utils/json_utils.dart';
import 'package:sport_ap_mobile/features/map/models/map_marker_model.dart';

class MapRepository {
  MapRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<MapMarkerModel>> fetchMarkers({
    required double south,
    required double west,
    required double north,
    required double east,
  }) async {
    final bbox = _buildBbox(south: south, west: west, north: north, east: east);
    if (kDebugMode) {
      debugPrint('[MAP] Request bbox=$bbox');
    }

    final response = await _apiClient.get(
      '/map/markers',
      queryParameters: <String, dynamic>{'bbox': bbox},
    );

    final markers = _parseMarkers(response);
    if (kDebugMode) {
      debugPrint('[MAP] Markers response count=${markers.length}');
      if (markers.isEmpty) {
        debugPrint('[MAP] API returned an empty marker list');
      }
    }
    return markers;
  }

  List<MapMarkerModel> _parseMarkers(dynamic response) {
    final directData = ResponseParser.dataList(response);
    if (directData.isNotEmpty) {
      return directData
          .map((item) => MapMarkerModel.fromJson(JsonUtils.asMap(item)))
          .where((marker) => marker.hasCoordinates)
          .toList();
    }

    final raw = ResponseParser.dataOrRaw(response);
    final map = JsonUtils.asMap(raw);
    final listSource = <dynamic>[];

    if (map['markers'] is List) {
      listSource.addAll(JsonUtils.asList(map['markers']));
    } else {
      for (final key in <String>[
        'events',
        'sport_facilities',
        'event_markers',
        'facility_markers',
      ]) {
        listSource.addAll(JsonUtils.asList(map[key]));
      }
    }

    return listSource
        .map((item) => MapMarkerModel.fromJson(JsonUtils.asMap(item)))
        .where((marker) => marker.hasCoordinates)
        .toList();
  }

  String _buildBbox({
    required double south,
    required double west,
    required double north,
    required double east,
  }) {
    return '${south.toStringAsFixed(6)},'
        '${west.toStringAsFixed(6)},'
        '${north.toStringAsFixed(6)},'
        '${east.toStringAsFixed(6)}';
  }
}

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository(ref.watch(apiClientProvider));
});
