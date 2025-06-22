import 'package:geolocator/geolocator.dart';

class GeofenceService {
  final double geofenceLat;
  final double geofenceLng;
  final double radius;

  GeofenceService({
    required this.geofenceLat,
    required this.geofenceLng,
    this.radius = 50, // default 50 meter
  });

  Future<bool> isOutsideGeofence() async {
    final position = await Geolocator.getCurrentPosition();
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      geofenceLat,
      geofenceLng,
    );
    return distance > radius;
  }
}