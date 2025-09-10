import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapService {
  /// Obtém a localização atual do dispositivo, lidando com as permissões.
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Serviço de localização desativado.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permissão de localização negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permissão de localização negada permanentemente.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Converte uma string de endereço em coordenadas, priorizando locais próximos ao usuário.
  Future<LatLng?> getCoordinatesFromAddress(String address, LatLng userLocation) async {
    // Usamos o endpoint de autocomplete que permite um 'ponto de foco'
    final url = Uri.parse(
        'https://api.openrouteservice.org/geocode/autocomplete'
            '?text=$address'
            '&focus.point.lon=${userLocation.longitude}'
            '&focus.point.lat=${userLocation.latitude}'
    );

    try {
      // A chave da API é necessária para esta busca também
      final apiKey = dotenv.env['OPEN_ROUTE_SERVICE_API_KEY'] ?? '';
      final response = await http.get(url, headers: {'Authorization': apiKey});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List;
        if (features.isNotEmpty) {
          // Pegamos o primeiro resultado, que será o mais relevante
          final coords = features.first['geometry']['coordinates'] as List;
          return LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
        }
      }
      return null;
    } catch (e) {
      print('Erro de Geocoding: $e');
      return null;
    }
  }

  /// Traça uma rota entre dois pontos usando a API OpenRouteService.
  Future<List<LatLng>> getRoute(LatLng start, LatLng end, String apiKey) async {
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/foot-walking/geojson',
    );
    final body = jsonEncode({
      "coordinates": [
        [start.longitude, start.latitude],
        [end.longitude, end.latitude],
      ],
    });

    try {
      final response = await http.post(
        url,
        headers: {'Authorization': apiKey, 'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = data['features'][0]['geometry']['coordinates'] as List;
        return coords
            .map(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
            )
            .toList();
      } else {
        // Se a API falhar, retorna uma rota simples (linha reta)
        return [start, end];
      }
    } catch (e) {
      print('Erro na requisição ORS: $e');
      // Em caso de erro, retorna uma rota simples (linha reta)
      return [start, end];
    }
  }
}
