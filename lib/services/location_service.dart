import 'package:geolocator/geolocator.dart';
import 'i_location_service.dart';

class LocationService implements ILocationService {
  @override
  Future<({double latitude, double longitude})> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("GPS desativado");

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Permissão de localização negada permanentemente");
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return (latitude: pos.latitude, longitude: pos.longitude);
  }
}