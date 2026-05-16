import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:sport_ap_mobile/core/providers.dart';
import 'package:sport_ap_mobile/features/map/data/map_repository.dart';
import 'package:sport_ap_mobile/features/map/models/map_marker_model.dart';
import 'package:sport_ap_mobile/features/profile/data/profile_repository.dart';
import 'package:sport_ap_mobile/features/profile/state/profile_controller.dart';

enum _MapMarkerFilter { all, events, facilities }

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const LatLng _defaultCenter = LatLng(52.2297, 21.0122);
  static const Duration _fetchDebounce = Duration(milliseconds: 500);

  final MapController _mapController = MapController();
  Timer? _debounceTimer;

  List<MapMarkerModel> _allMarkers = const <MapMarkerModel>[];
  _MapMarkerFilter _filter = _MapMarkerFilter.all;
  bool _isLoading = false;
  bool _isLocating = false;
  bool _hasLoadedAtLeastOnce = false;
  bool _lastApiResultWasEmpty = false;
  bool _isMapReady = false;
  LatLng _resolvedCenter = _defaultCenter;
  String? _errorMessage;
  String? _lastBboxKey;
  int _requestCounter = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveInitialCenter());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleMarkers = _filteredMarkers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: <Widget>[
          IconButton(
            onPressed: _refreshCurrentBounds,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _resolvedCenter,
              initialZoom: 11,
              onMapReady: () {
                _isMapReady = true;
                _moveMap(_resolvedCenter, forceFetch: true);
              },
              onPositionChanged: (camera, _) {
                _scheduleFetch(camera.visibleBounds);
              },
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sportap.mobile',
              ),
              MarkerLayer(
                markers: visibleMarkers
                    .where((marker) => marker.hasCoordinates)
                    .map(
                      (marker) => Marker(
                        point: LatLng(marker.latitude, marker.longitude),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openMarkerDetails(marker),
                          child: _MapMarkerIcon(marker: marker),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: _MapMarkerFilter.values
                      .map(
                        (item) => ChoiceChip(
                          label: Text(_filterLabel(item)),
                          selected: _filter == item,
                          onSelected: (_) => setState(() => _filter = item),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 22,
            child: FloatingActionButton.small(
              heroTag: 'map-my-location',
              onPressed: _isLocating ? null : _centerOnMyLocation,
              child: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          if (_isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
          if (_errorMessage != null)
            Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _refreshCurrentBounds,
                        child: const Text('Sprobuj ponownie'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_isLoading &&
              _errorMessage == null &&
              _hasLoadedAtLeastOnce &&
              _lastApiResultWasEmpty)
            const Center(
              child: Card(
                margin: EdgeInsets.all(24),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Brak obiektow lub wydarzen w tym obszarze.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          if (!_isLoading &&
              _errorMessage == null &&
              _hasLoadedAtLeastOnce &&
              !_lastApiResultWasEmpty &&
              visibleMarkers.isEmpty)
            const Center(
              child: Card(
                margin: EdgeInsets.all(24),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Brak markerow dla wybranego filtra.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          if (_isLoading && !_hasLoadedAtLeastOnce)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  List<MapMarkerModel> get _filteredMarkers {
    switch (_filter) {
      case _MapMarkerFilter.all:
        return _allMarkers;
      case _MapMarkerFilter.events:
        return _allMarkers.where((item) => item.isEvent).toList();
      case _MapMarkerFilter.facilities:
        return _allMarkers.where((item) => item.isFacility).toList();
    }
  }

  String _filterLabel(_MapMarkerFilter filter) {
    switch (filter) {
      case _MapMarkerFilter.all:
        return 'Wszystko';
      case _MapMarkerFilter.events:
        return 'Wydarzenia';
      case _MapMarkerFilter.facilities:
        return 'Obiekty';
    }
  }

  Future<void> _resolveInitialCenter() async {
    final locationResult = await ref
        .read(locationServiceProvider)
        .getCurrentLocation(requestPermission: false);

    if (locationResult.isSuccess) {
      final center = LatLng(
        locationResult.latitude!,
        locationResult.longitude!,
      );
      _resolvedCenter = center;
      if (mounted && _isMapReady) {
        _moveMap(center, forceFetch: true);
      }
      return;
    }

    final profileCenter = await _profileCenter();
    if (profileCenter != null) {
      _resolvedCenter = profileCenter;
      if (mounted && _isMapReady) {
        _moveMap(profileCenter, forceFetch: true);
      }
    }
  }

  Future<LatLng?> _profileCenter() async {
    final userFromState = ref.read(profileControllerProvider).user;
    final fromState = _toLatLng(
      latitude: userFromState?.latitude,
      longitude: userFromState?.longitude,
    );
    if (fromState != null) {
      return fromState;
    }

    try {
      final user = await ref
          .read(profileRepositoryProvider)
          .getProfile()
          .timeout(const Duration(seconds: 6));
      return _toLatLng(latitude: user.latitude, longitude: user.longitude);
    } catch (_) {
      return null;
    }
  }

  LatLng? _toLatLng({double? latitude, double? longitude}) {
    if (latitude == null || longitude == null) {
      return null;
    }
    if (!latitude.isFinite || !longitude.isFinite) {
      return null;
    }
    return LatLng(latitude, longitude);
  }

  Future<void> _centerOnMyLocation() async {
    setState(() => _isLocating = true);
    final result = await ref
        .read(locationServiceProvider)
        .getCurrentLocation(requestPermission: true);
    if (!mounted) {
      return;
    }

    setState(() => _isLocating = false);

    if (result.isSuccess) {
      final center = LatLng(result.latitude!, result.longitude!);
      _resolvedCenter = center;
      _moveMap(center, forceFetch: true);
      return;
    }

    _showLocationError(
      message: result.message ?? 'Nie udalo sie pobrac lokalizacji.',
      openLocationSettings: result.canOpenLocationSettings,
      openAppSettings: result.canOpenAppSettings,
    );
  }

  void _refreshCurrentBounds() {
    _scheduleFetchForCurrentCamera(immediate: true, force: true);
  }

  void _moveMap(LatLng center, {bool forceFetch = false}) {
    if (!_isMapReady) {
      return;
    }
    final zoom = _mapController.camera.zoom;
    _mapController.move(center, zoom.isFinite ? zoom : 11);
    _scheduleFetchForCurrentCamera(immediate: true, force: forceFetch);
  }

  void _showLocationError({
    required String message,
    required bool openLocationSettings,
    required bool openAppSettings,
  }) {
    final action = openLocationSettings || openAppSettings
        ? SnackBarAction(
            label: 'Ustawienia',
            onPressed: () {
              if (openLocationSettings) {
                ref.read(locationServiceProvider).openLocationSettings();
              } else {
                ref.read(locationServiceProvider).openAppSettings();
              }
            },
          )
        : null;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), action: action));
  }

  void _scheduleFetchForCurrentCamera({
    bool immediate = false,
    bool force = false,
  }) {
    if (!_isMapReady) {
      return;
    }

    _scheduleFetch(
      _mapController.camera.visibleBounds,
      immediate: immediate,
      force: force,
    );
  }

  void _scheduleFetch(
    LatLngBounds bounds, {
    bool immediate = false,
    bool force = false,
  }) {
    if (!_isBoundsValid(bounds)) {
      return;
    }

    final bboxKey = _buildBboxKey(bounds);
    if (!force && bboxKey == _lastBboxKey) {
      return;
    }

    _debounceTimer?.cancel();

    void trigger() {
      _fetchMarkers(bounds: bounds, bboxKey: bboxKey);
    }

    if (immediate) {
      trigger();
      return;
    }

    _debounceTimer = Timer(_fetchDebounce, trigger);
  }

  bool _isBoundsValid(LatLngBounds bounds) {
    final values = <double>[
      bounds.south,
      bounds.west,
      bounds.north,
      bounds.east,
    ];
    if (values.any((value) => !value.isFinite)) {
      return false;
    }
    if (bounds.north <= bounds.south) {
      return false;
    }
    if (bounds.east <= bounds.west) {
      return false;
    }
    return true;
  }

  String _buildBboxKey(LatLngBounds bounds) {
    return '${bounds.south.toStringAsFixed(4)},'
        '${bounds.west.toStringAsFixed(4)},'
        '${bounds.north.toStringAsFixed(4)},'
        '${bounds.east.toStringAsFixed(4)}';
  }

  Future<void> _fetchMarkers({
    required LatLngBounds bounds,
    required String bboxKey,
  }) async {
    final requestId = ++_requestCounter;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final markers = await ref
          .read(mapRepositoryProvider)
          .fetchMarkers(
            south: bounds.south,
            west: bounds.west,
            north: bounds.north,
            east: bounds.east,
          );

      if (!mounted || requestId != _requestCounter) {
        return;
      }

      setState(() {
        _allMarkers = markers;
        _lastApiResultWasEmpty = markers.isEmpty;
        _lastBboxKey = bboxKey;
        _isLoading = false;
        _hasLoadedAtLeastOnce = true;
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[MAP] Failed to fetch markers: $error');
      }
      if (!mounted || requestId != _requestCounter) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasLoadedAtLeastOnce = true;
        _errorMessage = 'Nie udalo sie pobrac markerow mapy.';
      });
    }
  }

  Future<void> _openMarkerDetails(MapMarkerModel marker) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final typeText = marker.isEvent
            ? 'Wydarzenie'
            : marker.isFacility
            ? 'Obiekt sportowy'
            : marker.type;
        final startsAtText = marker.startsAt == null
            ? null
            : DateFormat('dd.MM.yyyy HH:mm').format(marker.startsAt!.toLocal());
        final paidText = marker.isPaid == null
            ? null
            : marker.isPaid!
            ? 'Platne'
            : 'Bezplatne';
        final participantsText =
            marker.isEvent &&
                marker.participantsCount != null &&
                marker.participantLimit != null
            ? '${marker.participantsCount}/${marker.participantLimit} uczestnikow'
            : null;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  marker.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Typ: $typeText'),
                if (marker.discipline != null &&
                    marker.discipline!.trim().isNotEmpty)
                  Text('Dyscyplina: ${marker.discipline}'),
                if (startsAtText != null) Text('Start: $startsAtText'),
                if (participantsText != null)
                  Text('Uczestnicy: $participantsText'),
                if (paidText != null) Text('Platnosc: $paidText'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: marker.id.trim().isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _openDetails(marker);
                        },
                  child: const Text('Zobacz szczegoly'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDetails(MapMarkerModel marker) {
    final id = marker.id.trim();
    if (id.isEmpty) {
      return;
    }

    if (marker.isEvent) {
      context.push('/events/$id');
      return;
    }

    if (marker.isFacility) {
      context.push('/facilities/$id');
    }
  }
}

class _MapMarkerIcon extends StatelessWidget {
  const _MapMarkerIcon({required this.marker});

  final MapMarkerModel marker;

  @override
  Widget build(BuildContext context) {
    final isEvent = marker.isEvent;

    return Container(
      decoration: BoxDecoration(
        color: isEvent ? Colors.orangeAccent : Colors.lightBlueAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(
        isEvent ? Icons.event : Icons.sports_soccer,
        color: Colors.black87,
        size: 20,
      ),
    );
  }
}
