import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'deaf_map_enterprise_page.dart'; // Importa a nova página empresarial
import 'deaf_settings_page.dart'; // Importa a página de configurações

const String _fontScaleKey = 'fontScale';
const String _colorSchemeKey = 'colorScheme';

// Chave da API para OpenRouteService
// A chave fornecida pelo usuário é para o OpenRouteService, não para o OSRM.
// O OSRM é o motor de roteamento, mas o OpenRouteService é a plataforma que o usa.
const String _openRouteServiceApiKey = 'eyJvcmciOiI1YjNjZmM5OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjRkOGQ4YTEwOWE2ZTRmNjhiM2RiNDY4ODc3NTUzZDZlIiwiaCI6Im11cm11cjY0In0=';

class DeafMapPage extends StatefulWidget {
  const DeafMapPage({super.key});

  @override
  State<DeafMapPage> createState() => _DeafMapPageState();
}

class _DeafMapPageState extends State<DeafMapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();
  List<LatLng> _routePoints = [];

  LatLng? _currentLocation;
  bool _isTracingRoute = false;

  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _requestLocationPermissionAndGetLocation();
  }

  // Carrega as configurações de fonte e cores salvas no SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
      _colorScheme = prefs.getString(_colorSchemeKey) ?? 'Padrão';
    });
  }

  // Solicita permissões de localização e obtém a localização atual
  Future<void> _requestLocationPermissionAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Exibe uma SnackBar para informar ao usuário que a localização está desativada
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serviço de localização desativado.')),
        );
      }
      return Future.error('Serviço de localização desativado.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Exibe uma SnackBar caso a permissão seja negada
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de localização negada.')),
          );
        }
        return Future.error('Permissão de localização negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Exibe uma SnackBar informando que a permissão foi negada permanentemente
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de localização negada para sempre. Habilite nas configurações do aplicativo.')),
        );
      }
      return Future.error('Permissão de localização negada para sempre. Habilite nas configurações do aplicativo.');
    }

    _getCurrentLocation();
  }

  // Obtém a localização atual do usuário e move o mapa
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentLocation!, 15.0);
      });
    } catch (e) {
      print('Erro ao obter a localização: $e');
    }
  }

  // Traça a rota entre a localização atual e o endereço de destino usando OpenRouteService
  Future<void> _traceRoute(String destinationAddress) async {
    if (destinationAddress.isEmpty) return;

    setState(() {
      _isTracingRoute = true;
      _routePoints = [];
    });

    try {
      List<geocoding.Location> locations = await geocoding.locationFromAddress(destinationAddress);
      if (locations.isNotEmpty && _currentLocation != null) {
        final destination = LatLng(locations.first.latitude, locations.first.longitude);

        // URL da API do OpenRouteService
        final apiUrl = 'https://api.openrouteservice.org/v2/directions/driving-car';
        final body = json.encode({
          'coordinates': [
            [_currentLocation!.longitude, _currentLocation!.latitude],
            [destination.longitude, destination.latitude]
          ]
        });

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Authorization': _openRouteServiceApiKey,
            'Content-Type': 'application/json',
          },
          body: body,
        );

        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          final route = data['routes'][0]['geometry']['coordinates'] as List;
          setState(() {
            _routePoints = route.map((e) => LatLng(e[1], e[0])).toList();
            _mapController.fitBounds(
              LatLngBounds(_currentLocation!, destination),
              options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
            );
          });
        } else {
          print('Erro na API do OpenRouteService: ${response.statusCode} - ${response.body}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao traçar a rota. Verifique o endereço e a chave da API.')),
            );
          }
        }
      }
    } catch (e) {
      print('Erro ao traçar a rota: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao traçar a rota. Tente novamente.')),
        );
      }
    } finally {
      setState(() {
        _isTracingRoute = false;
      });
    }
  }

  // Retorna a cor primária baseada no esquema de cores selecionado
  Color _getPrimaryColor() {
    switch (_colorScheme) {
      case 'Alto Contraste':
        return Colors.black;
      case 'Protanopia':
        return const Color.fromRGBO(85, 148, 179, 1);
      case 'Deuteranopia':
        return const Color.fromRGBO(179, 148, 85, 1);
      case 'Tritanopia':
        return const Color.fromRGBO(148, 85, 179, 1);
      case 'Modo Escuro':
        return Colors.blueGrey[800]!;
      default:
        return const Color.fromRGBO(0, 69, 118, 1);
    }
  }

  // Retorna a cor de fundo do Scaffold baseada no esquema de cores
  Color _getScaffoldBackgroundColor() {
    return _colorScheme == 'Modo Escuro' ? Colors.grey[900]! : Colors.white;
  }

  // Retorna a cor do cartão da barra de pesquisa baseada no esquema de cores
  Color _getCardColor() {
    return _colorScheme == 'Modo Escuro' ? Colors.grey[850]! : Colors.white;
  }

  // Retorna a cor do texto baseada no esquema de cores
  Color _getTextColor() {
    return _colorScheme == 'Modo Escuro' ? Colors.white : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _getPrimaryColor(),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              // Navega para a página de configurações e espera o retorno
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DeafSettingsPage(),
                ),
              );
              // Recarrega as configurações quando o usuário retorna da página de configurações
              _loadSettings();
            },
          ),
        ],
      ),
      backgroundColor: _getScaffoldBackgroundColor(),
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                center: _currentLocation ?? const LatLng(-23.5505, -46.6333),
                zoom: 15.0,
              ),
              mapController: _mapController,
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _currentLocation!,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40.0,
                        ),
                      ),
                    ],
                  ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.blue,
                        strokeWidth: 5.0,
                      ),
                    ],
                  ),
              ],
            ),
            // Barra de pesquisa
            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
              child: Card(
                color: _getCardColor(), // APLICAÇÃO DA COR CORRIGIDA
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            hintText: 'Pesquisar endereço...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: _getTextColor().withOpacity(0.5),
                            ),
                          ),
                          style: TextStyle(
                            color: _getTextColor(),
                            fontSize: 16 * _fontScale,
                          ),
                          onSubmitted: (value) => _traceRoute(value),
                        ),
                      ),
                      _isTracingRoute
                          ? SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_getPrimaryColor()),
                        ),
                      )
                          : IconButton(
                        icon: Icon(Icons.search, color: _getPrimaryColor()),
                        onPressed: () => _traceRoute(_addressController.text),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Botão para ir para a página empresarial
            Positioned(
              bottom: 80.0,
              right: 16.0,
              child: FloatingActionButton(
                heroTag: 'enterpriseBtn',
                mini: false,
                backgroundColor: _getPrimaryColor(),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DeafMapEnterprisePage(),
                    ),
                  );
                },
                child: const Icon(Icons.business, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
