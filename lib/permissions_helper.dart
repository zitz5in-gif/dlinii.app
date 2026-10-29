import 'package:geolocator/geolocator.dart';

enum LocPermResult { granted, denied, deniedForever, serviceOff }

class PermissionsHelper {
  static Future<LocPermResult> ensureLocation() async {
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever) {
      return LocPermResult.deniedForever;
    }
    if (p == LocationPermission.denied) {
      return LocPermResult.denied;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocPermResult.serviceOff;
    }
    return LocPermResult.granted;
  }

  static Future<void> openAppSettings() => Geolocator.openAppSettings();

  static Future<void> openLocationSettings() =>
      Geolocator.openLocationSettings();
}
