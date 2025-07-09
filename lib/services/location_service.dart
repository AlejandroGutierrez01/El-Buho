// location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

class LocationService {
  
  /// Manejar permisos de ubicación de forma amigable
  static Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('⚠️ Los servicios de ubicación están desactivados.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('⚠️ Permiso de ubicación denegado por el usuario.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('⛔ Permiso de ubicación denegado permanentemente.');
      return false;
    }

    return true;
  }

  /// Obtener la posición actual del dispositivo
  static Future<Position?> getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      print('✅ Posición obtenida: (${position.latitude}, ${position.longitude})');
      return position;
    } catch (e) {
      print('❌ Error obteniendo ubicación: $e');
      return null;
    }
  }

  /// Obtener enlace de Google Maps de la posición actual
  static Future<String?> getCurrentLocationLink() async {
    final position = await getCurrentPosition();
    if (position != null) {
      final link = createGoogleMapsLink(position.latitude, position.longitude);
      print('🌍 Enlace de Google Maps generado: $link');
      return link;
    }
    return null;
  }

  /// Crear enlace de Google Maps a partir de coordenadas
  static String createGoogleMapsLink(double latitude, double longitude) {
    return 'https://maps.google.com/?q=$latitude,$longitude';
  }

  /// Extraer coordenadas desde un enlace de Google Maps
  static Map<String, double>? extractCoordinatesFromLink(String link) {
    try {
      final uri = Uri.parse(link);
      final query = uri.queryParameters['q'];

      if (query != null) {
        final coords = query.split(',');
        if (coords.length == 2) {
          final lat = double.parse(coords[0].trim());
          final lng = double.parse(coords[1].trim());
          print('📍 Coordenadas extraídas: lat=$lat, lng=$lng');
          return {'latitude': lat, 'longitude': lng};
        }
      }
    } catch (e) {
      print('❌ Error extrayendo coordenadas: $e');
    }

    return null;
  }
}
