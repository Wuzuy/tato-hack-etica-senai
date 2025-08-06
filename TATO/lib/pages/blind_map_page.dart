import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'usage_guide_page.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class BlindMapPage extends StatefulWidget {
  const BlindMapPage({super.key});

  @override
  State<BlindMapPage> createState() => _BlindMapPageState();
}

class _BlindMapPageState extends State<BlindMapPage> {
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _addressController = TextEditingController();
  List<LatLng> _routePoints = [];

  static const LatLng _center = LatLng(-22.7884, -43.3101); // Exemplo: SENAI Caxias

  @override
  void initState() {
    super.initState();
    _initTts();
    _speakInitialInstructions();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speakInitialInstructions() async {
    await _flutterTts.speak(
        "Bem-vindo à navegação por áudio. Informe o nome da instituição em que você trabalha no campo de texto e toque no botão de pesquisa.");
  }

  Future<void> _searchAddressAndCreateRoute() async {
    _flutterTts.speak("Buscando o endereço: ${_addressController.text}");

    try {
      List<geocoding.Location> locations = await geocoding.locationFromAddress(_addressController.text);
      if (locations.isNotEmpty) {
        final LatLng destination = LatLng(locations.first.latitude, locations.first.longitude);
        _routePoints = [_center, destination];
        _flutterTts.speak("Rota para o destino traçada no mapa.");
        setState(() {});
      } else {
        _flutterTts.speak("Não foi possível encontrar o endereço. Tente novamente.");
      }
    } catch (e) {
      _flutterTts.speak("Houve um erro ao processar o endereço.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 69, 118, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _flutterTts.stop();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: <Widget>[
          FlutterMap(
            options: const MapOptions(
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
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                  if (_routePoints.length > 1)
                    Marker(
                      point: _routePoints.last,
                      child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            right: 10,
            child: FloatingActionButton(
              heroTag: 'ttsButton',
              mini: true,
              backgroundColor: const Color.fromRGBO(0, 69, 118, 1),
              onPressed: _speakInitialInstructions,
              child: const Icon(Icons.volume_up, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          hintText: 'Digite o endereço...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) => _searchAddressAndCreateRoute(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Color.fromRGBO(0, 69, 118, 1)),
                      onPressed: _searchAddressAndCreateRoute,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'helpButton',
              backgroundColor: const Color.fromRGBO(0, 69, 118, 1),
              onPressed: () {
                _flutterTts.stop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const UsageGuidePage()),
                );
              },
              child: const Icon(Icons.help, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}