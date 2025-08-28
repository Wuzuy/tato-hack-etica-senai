import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'deaf_map_enterprise_page.dart';

const String _fontScaleKey = 'fontScale';
const String _colorSchemeKey = 'colorScheme';

class DeafMapPage extends StatefulWidget {
  const DeafMapPage({super.key});

  @override
  State<DeafMapPage> createState() => _DeafMapPageState();
}

class _DeafMapPageState extends State<DeafMapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();
  List<LatLng> _routePoints = [];

  LatLng _center = LatLng(-22.7884, -43.3101);

  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  final String _openRouteServiceApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjY1NDUyY2NkYTRlMzQ1NWI5ZDY5ZTA2NDMwOWNmMzljIiwiaCI6Im11cm11cjY0In0=';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
        _colorScheme = prefs.getString(_colorSchemeKey) ?? 'Padrão';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if(mounted) {
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _routePoints = [_center];
        _mapController.move(_center, 15.0);
      });
    }
  }

  Future<void> _searchAddressAndCreateRoute(String address) async {
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira um endereço.')),
      );
      return;
    }

    try {
      List<geocoding.Location> locations = await geocoding.locationFromAddress(address);
      if (locations.isNotEmpty) {
        final LatLng destination = LatLng(locations.first.latitude, locations.first.longitude);
        await _traceRouteByRoads(_center, destination);
        if (mounted) {
          setState(() {});
          _mapController.move(destination, 15.0);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível encontrar o endereço. Tente novamente.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Houve um erro ao processar o endereço.')),
      );
    }
  }

  Future<void> _traceRouteByRoads(LatLng start, LatLng end) async {
    final url = Uri.parse('https://api.openrouteservice.org/v2/directions/foot-walking/geojson');
    final body = jsonEncode({
      "coordinates": [
        [start.longitude, start.latitude],
        [end.longitude, end.latitude]
      ]
    });
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': _openRouteServiceApiKey,
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = data['features'][0]['geometry']['coordinates'] as List;
        List<LatLng> points = coords
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        if (mounted) {
          setState(() {
            _routePoints = points;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao traçar rota: ${response.statusCode}')),
        );
        if (mounted) {
          setState(() {
            _routePoints = [start, end];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro na conexão com o serviço de rotas.')),
      );
      if (mounted) {
        setState(() {
          _routePoints = [start, end];
        });
      }
    }
  }

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

  Color _getScaffoldBackgroundColor() {
    return _colorScheme == 'Modo Escuro' ? Colors.grey[900]! : Colors.white;
  }

  Color _getAppBarIconColor() {
    return _colorScheme == 'Alto Contraste' || _colorScheme == 'Modo Escuro' ? Colors.white : Colors.white;
  }

  Color _getCardColor() {
    return _colorScheme == 'Modo Escuro' ? Colors.grey[850]! : Colors.white;
  }

  Color _getTextColor() {
    return _colorScheme == 'Modo Escuro' ? Colors.white : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getScaffoldBackgroundColor(),
      appBar: AppBar(
        backgroundColor: _getPrimaryColor(),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _getAppBarIconColor(), size: 24 * _fontScale),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location, color: _getAppBarIconColor(), size: 24 * _fontScale),
            onPressed: _getCurrentLocation,
            tooltip: 'Centralizar',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.tato',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _center,
                      child: Icon(Icons.location_on, color: Colors.red, size: 40 * _fontScale),
                    ),
                    if (_routePoints.length > 1)
                      Marker(
                        point: _routePoints.last,
                        child: Icon(Icons.location_on, color: Colors.blue, size: 40 * _fontScale),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                color: _getCardColor(),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          style: TextStyle(fontSize: 18 * _fontScale, color: _getTextColor()),
                          decoration: InputDecoration(
                            hintText: 'Digite um endereço',
                            hintStyle: TextStyle(color: _getTextColor().withOpacity(0.5)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _getTextColor().withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _getPrimaryColor()),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getPrimaryColor(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          _searchAddressAndCreateRoute(_addressController.text);
                        },
                        child: Icon(Icons.search, color: Colors.white, size: 24 * _fontScale),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: _getPrimaryColor(),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DeafMapEnterprisePage(),
                    ),
                  );
                },
                child: Icon(Icons.business, color: _getAppBarIconColor(), size: 24 * _fontScale),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
