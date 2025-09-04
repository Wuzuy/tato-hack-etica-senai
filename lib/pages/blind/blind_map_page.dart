import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'blind_usage_guide_page.dart';
import 'blind_chat_page.dart';
import 'blind_settings_page.dart';
import 'blind_map_enterprise_page.dart';

const String _fontScaleKey = 'fontScale';
const String _colorSchemeKey = 'colorScheme';

class BlindMapPage extends StatefulWidget {
  const BlindMapPage({super.key});

  @override
  State<BlindMapPage> createState() => _BlindMapPageState();
}

class _BlindMapPageState extends State<BlindMapPage> {
  final FlutterTts _flutterTts = FlutterTts();
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();
  List<LatLng> _routePoints = [];

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';

  LatLng _center = LatLng(-22.7884, -43.3101);

  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  final String _openRouteServiceApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjRkOGQ4YTEwOWE5ZTRmNjhiM2RiNDY4ODc3NTczZDZlIiwiaCI6Im11cm11cjY0In0=';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initTts();
    _speakInitialInstructions();
    _speech = stt.SpeechToText();
    _initializeSpeech();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _flutterTts.stop();
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

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speakInitialInstructions() async {
    await _flutterTts.speak(
        "Bem-vindo ao Tato. Toque no botão de microfone e diga o nome da sua empresa.");
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if (status == stt.SpeechToText.listeningStatus) {
          setState(() => _isListening = true);
        } else {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => debugPrint('Speech error: $error'),
    );
    if (!available) {
      _flutterTts.speak("O reconhecimento de voz não está disponível neste dispositivo.");
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _flutterTts.speak("Serviço de localização está desativado.");
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _flutterTts.speak("Permissão de localização negada.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _flutterTts.speak("Permissão de localização negada permanentemente.");
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

  void _startListening() async {
    await _speech.listen(
      localeId: 'pt_BR',
      onResult: (result) {
        if (mounted) {
          setState(() {
            _lastWords = result.recognizedWords;
          });
        }
        if (result.finalResult && _lastWords.isNotEmpty) {
          _processVoiceCommand(_lastWords);
          _stopListening();
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
  }

  void _processVoiceCommand(String command) {
    String normalizedCommand = command.toLowerCase().trim();

    if (normalizedCommand.contains('me leve a') || normalizedCommand.contains('me leve ao')) {
      final address = normalizedCommand.substring(normalizedCommand.indexOf('a') + 1).trim();
      _searchAddressAndCreateRoute(address);
    } else if (normalizedCommand.contains('guia')) {
      _navigateToUsageGuidePage();
    } else if (normalizedCommand.contains('chat')) {
      _navigateToChatPage();
    } else if (normalizedCommand.contains('configurações') || normalizedCommand.contains('ajustes')) {
      _navigateToSettingsPage();
    } else if (normalizedCommand.contains('mapa empresarial')) {
      _navigateToBlindMapEnterprisePage();
    } else {
      _flutterTts.speak("Comando não reconhecido. Por favor, tente novamente.");
    }
  }

  Future<void> _searchAddressAndCreateRoute(String address) async {
    _flutterTts.speak("Buscando o endereço: $address");
    try {
      List<geocoding.Location> locations = await geocoding.locationFromAddress(address);
      if (locations.isNotEmpty) {
        final LatLng destination = LatLng(locations.first.latitude, locations.first.longitude);
        await _traceRouteByRoads(_center, destination);
        _flutterTts.speak("Rota para o destino traçada no mapa.");
        if (mounted) setState(() {});
        _mapController.move(destination, 15.0);
      } else {
        _flutterTts.speak("Não foi possível encontrar o endereço. Tente novamente.");
      }
    } catch (e) {
      _flutterTts.speak("Houve um erro ao processar o endereço.");
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
        debugPrint('Erro ORS: ${response.statusCode} ${response.body}');
        _flutterTts.speak("Não foi possível traçar a rota detalhada, usando linha reta.");
        if (mounted) {
          setState(() {
            _routePoints = [start, end];
          });
        }
      }
    } catch (e) {
      debugPrint('Erro requisição ORS: $e');
      _flutterTts.speak("Erro ao buscar rota detalhada, usando linha reta.");
      if (mounted) {
        setState(() {
          _routePoints = [start, end];
        });
      }
    }
  }

  void _navigateToUsageGuidePage() {
    _flutterTts.stop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const UsageGuidePage()),
    ).then((_) => _loadSettings());
  }

  void _navigateToChatPage() {
    _flutterTts.stop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ChatPage()),
    ).then((_) => _loadSettings());
  }

  void _navigateToSettingsPage() {
    _flutterTts.stop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    ).then((_) => _loadSettings());
  }

  void _navigateToBlindMapEnterprisePage() {
    _flutterTts.stop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BlindMapEnterprisePage()),
    ).then((_) => _loadSettings());
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

  Color _getMicIconColor() {
    return _colorScheme == 'Modo Escuro' ? Colors.white : const Color.fromRGBO(0, 69, 118, 1);
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
            _flutterTts.stop();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: _getAppBarIconColor(), size: 24 * _fontScale),
            onPressed: _navigateToSettingsPage,
            tooltip: 'Configurações',
          ),
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
                center: _center,
                zoom: 15.0,
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
            // Floating Action Button maior para o mapa empresarial
            Positioned(
              bottom: 120, // Posição ajustada para ficar mais perto do botão de microfone
              right: 20,
              child: FloatingActionButton.large(
                heroTag: 'enterpriseMapButton',
                backgroundColor: _getPrimaryColor(),
                onPressed: _navigateToBlindMapEnterprisePage,
                child: const Icon(Icons.business, color: Colors.white),
              ),
            ),
            // Card do botão de microfone
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
                child: InkWell(
                  onTap: () {
                    if (_isListening) {
                      _stopListening();
                    } else {
                      _startListening();
                    }
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isListening ? Icons.mic_off : Icons.mic,
                          color: _isListening ? Colors.red : _getMicIconColor(),
                          size: 36 * _fontScale,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _isListening
                                ? "Ouvindo..."
                                : (_lastWords.isEmpty ? "Toque para falar" : _lastWords),
                            style: TextStyle(fontSize: 18 * _fontScale, color: _getTextColor()),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
