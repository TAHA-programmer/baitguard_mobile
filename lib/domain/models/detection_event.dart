import 'detected_species.dart';

class DetectionEvent {
  final String id;
  final String stationId;
  final DateTime timestamp;
  final DetectedSpecies species;
  final double confidenceScore;
  final String? evidenceImageUrl;

  const DetectionEvent({
    required this.id,
    required this.stationId,
    required this.timestamp,
    required this.species,
    required this.confidenceScore,
    this.evidenceImageUrl,
  });
}
