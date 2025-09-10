import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:tato/models/command_result.dart';
import 'package:tato/services/accessibility_service.dart';
import 'package:tato/services/command_interpreter_service.dart';
import 'package:tato/services/gemini_service.dart';
import 'package:tato/services/global_command_service.dart';
import 'package:tato/services/map_service.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/settings_page.dart';
import 'package:tato/utils/app_theme.dart';

import 'blind_chat_page.dart';
import 'blind_map_enterprise_page.dart';
import 'blind_usage_guide_page.dart';

/// Página principal do mapa com navegação por voz inteligente.
class BlindMapPage extends StatefulWidget {
  const BlindMapPage({super.key});

  @override
  State<BlindMapPage> createState() => _BlindMapPageState();
}

class _BlindMapPageState extends State<BlindMapPage> {
  // --- Serviços ---
  final SettingsService _settingsService = SettingsService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  final GeminiService _geminiService = GeminiService();
  final MapService _mapService = MapService();
  late final CommandInterpreterService _commandInterpreterService;
  late final GlobalCommandService _globalCommandService;

  // --- Estado da UI e Controladores ---
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  LatLng? _center; // Alterado para nulo inicialmente
  bool _isListening = false;
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';
  String _lastWords = '';
  final String _orsApiKey = dotenv.env['OPEN_ROUTE_SERVICE_API_KEY'] ?? '';
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _commandInterpreterService = CommandInterpreterService(_geminiService);
    _globalCommandService =
        GlobalCommandService(_commandInterpreterService, _accessibilityService);
    _initializePage();
  }

  @override
  void dispose() {
    _accessibilityService.stopSpeaking();
    _accessibilityService.stopListening();
    super.dispose();
  }

  /// Carrega configs, inicializa serviços e busca a localização inicial.
  Future<void> _initializePage() async {
    _fontScale = await _settingsService.loadFontScale();
    _colorScheme = await _settingsService.loadColorScheme();
    await _accessibilityService.initialize(
      onListeningStateChanged: (isListening) {
        if (mounted) setState(() => _isListening = isListening);
      },
    );
    await _accessibilityService.speak(
      "Bem-vindo ao mapa. Toque no botão de microfone e diga para onde quer ir.",
    );
    await _centerOnCurrentLocation();
  }

  /// Inicia a escuta de voz, com proteção contra toques rápidos.
  void _startListening() {
    if (_isActionInProgress || _isListening) return;

    try {
      setState(() {
        _isActionInProgress = true;
        _lastWords = '';
      });
      _accessibilityService.startListening(
        onResult: (recognizedWords) {
          setState(() => _lastWords = recognizedWords);
          _handleVoiceCommand(recognizedWords);
        },
      );
    } finally {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isActionInProgress = false);
      });
    }
  }

  /// Para a escuta de voz.
  void _stopListening() {
    _accessibilityService.stopListening();
  }

  /// Interpreta o comando de voz e executa a ação correspondente.
  Future<void> _handleVoiceCommand(String text) async {
    final CommandResult result =
    await _commandInterpreterService.interpretCommand(text);

    final bool wasHandledGlobally =
    await _globalCommandService.executeCommand(text, result);

    if (!wasHandledGlobally) {
      switch (result.intent) {
        case 'navigate_to_address':
          final address = result.parameters['address'] as String?;
          if (address != null) {
            await _plotRouteToAddress(address);
          } else {
            await _accessibilityService
                .speak("Não entendi o endereço. Tente novamente.");
          }
          break;
        default:
          await _accessibilityService.speak(
              "Comando não reconhecido. Diga 'me leve para' e um endereço, ou 'guia de uso' para ajuda.");
          break;
      }
    }
  }

  /// Orquestra a busca e o traçado de uma rota para um endereço.
  Future<void> _plotRouteToAddress(String address) async {
    if (_center == null) {
      await _accessibilityService.speak("Aguarde, ainda buscando sua localização inicial.");
      return;
    }
    await _accessibilityService.speak("Buscando o endereço: $address");
    LatLng? destination = await _mapService.getCoordinatesFromAddress(address, _center!);

    if (destination != null) {
      List<LatLng> points =
      await _mapService.getRoute(_center!, destination, _orsApiKey);
      setState(() => _routePoints = points);
      _mapController.move(destination, 15.0);
      await _accessibilityService.speak("Rota para o destino traçada no mapa.");
    } else {
      await _accessibilityService
          .speak("Não foi possível encontrar o endereço.");
    }
  }

  /// Busca a localização atual e centraliza o mapa nela.
  Future<void> _centerOnCurrentLocation() async {
    try {
      final Position position = await _mapService.getCurrentLocation();
      final currentLocation = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _center = currentLocation;
          _routePoints = [currentLocation];
        });
      }
    } catch (e) {
      await _accessibilityService.speak(e.toString());
    }
  }

  void _navigateToPage(Widget page) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page))
        .then((_) => _initializePage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackgroundColor(_colorScheme),
      appBar: AppBar(
        backgroundColor: AppTheme.getPrimaryColor(_colorScheme),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24 * _fontScale),
          onPressed: () {
            _accessibilityService.stopSpeaking();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white, size: 24 * _fontScale),
            onPressed: () => _navigateToPage(const UsageGuidePage()),
            tooltip: 'Guia de Uso',
          ),
          IconButton(
            icon: Icon(Icons.chat, color: Colors.white, size: 24 * _fontScale),
            onPressed: () => _navigateToPage(const BlindChatPage()),
            tooltip: 'Chat',
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white, size: 24 * _fontScale),
            onPressed: () => _navigateToPage(const SettingsPage()),
            tooltip: 'Configurações',
          ),
          IconButton(
            icon: Icon(Icons.my_location, color: Colors.white, size: 24 * _fontScale),
            onPressed: _centerOnCurrentLocation,
            tooltip: 'Centralizar',
          ),
        ],
      ),
      body: SafeArea(
        child: _center == null
            ? Center(child: CircularProgressIndicator(color: AppTheme.getPrimaryColor(_colorScheme)))
            : Stack(
          children: <Widget>[
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(center: _center!, zoom: 15.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tato.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(points: _routePoints, strokeWidth: 5.0, color: Colors.blue),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _center!,
                      child: Icon(Icons.my_location, color: Colors.red, size: 40 * _fontScale),
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
              bottom: 150,
              right: 20,
              child: FloatingActionButton.large(
                heroTag: 'enterpriseMapButton',
                backgroundColor: AppTheme.getPrimaryColor(_colorScheme),
                onPressed: () => _navigateToPage(const BlindMapEnterprisePage()),
                child: const Icon(Icons.business, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                color: AppTheme.getScaffoldBackgroundColor(_colorScheme),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: InkWell(
                  onTap: _isListening ? _stopListening : _startListening,
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isListening ? Icons.mic_off : Icons.mic,
                          color: _isListening ? Colors.red : AppTheme.getPrimaryColor(_colorScheme),
                          size: 36 * _fontScale,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _isListening
                                ? "Ouvindo..."
                                : (_lastWords.isEmpty ? "Toque para falar" : _lastWords),
                            style: TextStyle(
                              fontSize: 18 * _fontScale,
                              color: AppTheme.getMessageTextColor(_colorScheme, false),
                            ),
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