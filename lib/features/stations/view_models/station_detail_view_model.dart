import 'package:flutter/foundation.dart';
import '../../../domain/models/station.dart';
import '../../../domain/models/detection_event.dart';
import '../../../domain/repositories/station_repository.dart';

enum StationDetailLoadStatus { initial, loading, success, error }

class StationDetailViewModel extends ChangeNotifier {
  final String stationId;
  final StationRepository _stationRepository;

  StationDetailViewModel({
    required this.stationId,
    required StationRepository stationRepository,
  }) : _stationRepository = stationRepository;

  StationDetailLoadStatus _status = StationDetailLoadStatus.initial;
  StationDetailLoadStatus get status => _status;

  Station? _station;
  Station? get station => _station;

  List<DetectionEvent> _events = const [];
  List<DetectionEvent> get events => _events;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  int _refreshErrorEventId = 0;
  int get refreshErrorEventId => _refreshErrorEventId;
  String? _refreshErrorMessage;
  String? get refreshErrorMessage => _refreshErrorMessage;

  int _actionEventId = 0;
  int get actionEventId => _actionEventId;
  String? _actionErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  String? _actionSuccessMessage;
  String? get actionSuccessMessage => _actionSuccessMessage;

  Future<void> load() async {
    if (_status == StationDetailLoadStatus.loading) return;

    _status = StationDetailLoadStatus.loading;
    notifyListeners();

    try {
      final loadedStation = await _stationRepository.getStationById(stationId);
      if (loadedStation == null) {
        _status = StationDetailLoadStatus.error;
        notifyListeners();
        return;
      }

      _station = loadedStation;
      final loadedEvents = await _stationRepository.getStationEvents(stationId);
      _events = List.unmodifiable(loadedEvents);
      _status = StationDetailLoadStatus.success;
    } catch (e) {
      _status = StationDetailLoadStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_status != StationDetailLoadStatus.success || _isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      final loadedStation = await _stationRepository.getStationById(stationId);
      if (loadedStation == null) {
        _refreshErrorMessage = 'Station $stationId is no longer available.';
        _refreshErrorEventId++;
      } else {
        _station = loadedStation;
        final loadedEvents = await _stationRepository.getStationEvents(
          stationId,
        );
        _events = List.unmodifiable(loadedEvents);
      }
    } catch (e) {
      _refreshErrorMessage = 'Failed to refresh station data.';
      _refreshErrorEventId++;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> setNotificationsMuted(bool muted) async {
    if (_station == null) return;
    try {
      final updated = await _stationRepository.setNotificationsMuted(
        stationId: stationId,
        muted: muted,
      );
      _station = updated;

      _actionSuccessMessage = muted
          ? 'Notifications muted for $stationId'
          : 'Notifications unmuted for $stationId';
      _actionEventId++;
      notifyListeners();
    } catch (e) {
      _actionErrorMessage = 'Failed to change notification settings.';
      _actionEventId++;
      notifyListeners();
    }
  }
}
