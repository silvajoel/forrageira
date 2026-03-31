abstract class ILocationService {
  Future<({double latitude, double longitude})> getCurrentLocation();
}