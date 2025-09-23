import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:tato/pages/settings_page.dart';
import 'package:tato/services/map_service.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/utils/app_theme.dart';

import 'deaf_map_enterprise_page.dart';

/// Página de mapa com busca de endereço para o fluxo de usuário "deaf".
class DeafMapPage extends StatefulWidget {
  const DeafMapPage({super.key});

  @override
  State<DeafMapPage> createState() => _DeafMapPageState();
}

class _DeafMapPageState extends State<DeafMapPage> {
  // --- Serviços ---
  final SettingsService _settingsService = SettingsService();
  final MapService _mapService = MapService();

  // --- Controladores e Estado da UI ---
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();
  List<LatLng> _routePoints = [];
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  bool _isTracingRoute = false;
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';
  final String _orsApiKey = dotenv.env['OPEN_ROUTE_SERVICE_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  /// Carrega configurações e busca a localização inicial.
  Future<void> _initializePage() async {
    _fontScale = await _settingsService.loadFontScale();
    _colorScheme = await _settingsService.loadColorScheme();
    await _centerOnCurrentLocation();
  }

  /// Busca a localização atual e atualiza o estado.
  Future<void> _centerOnCurrentLocation() async {
    try {
      final Position position = await _mapService.getCurrentLocation();
      final currentLocation = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentLocation = currentLocation;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  /// Orquestra a busca e o traçado de uma rota para um endereço.
  Future<void> _traceRoute(String destinationAddress) async {
    if (destinationAddress.trim().isEmpty || _currentLocation == null) return;
    setState(() => _isTracingRoute = true);

    try {
      LatLng? destination = await _mapService.getCoordinatesFromAddress(
        destinationAddress,
        _currentLocation!,
      );
      if (destination != null) {
        List<LatLng> points = await _mapService.getRoute(
          _currentLocation!,
          destination,
          _orsApiKey,
        );
        setState(() {
          _routePoints = points;
          _destinationLocation = destination;
          _mapController.fitBounds(
            LatLngBounds(_currentLocation!, destination),
            options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
          );
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Endereço não encontrado.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erro ao traçar a rota.')));
      }
    } finally {
      if (mounted) setState(() => _isTracingRoute = false);
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () =>
                _navigateToPage(const SettingsPage(useGoogleFonts: true)),
          ),
        ],
      ),
      body: SafeArea(
        child: _currentLocation == null
            ? Center(
                child: CircularProgressIndicator(
                  color: AppTheme.getPrimaryColor(_colorScheme),
                ),
              )
            : Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(center: _currentLocation!, zoom: 15.0),
                    mapController: _mapController,
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.tato.app',
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
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation!,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.red,
                              size: 40.0,
                            ),
                          ),
                          if (_destinationLocation != null)
                            Marker(
                              point: _destinationLocation!,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.blue,
                                size: 40.0,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 16.0,
                    left: 16.0,
                    right: 16.0,
                    child: Card(
                      color: AppTheme.getScaffoldBackgroundColor(_colorScheme),
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
                                    color: AppTheme.getMessageTextColor(
                                      _colorScheme,
                                      false,
                                    ).withOpacity(0.6),
                                  ),
                                ),
                                style: TextStyle(
                                  color: AppTheme.getMessageTextColor(
                                    _colorScheme,
                                    false,
                                  ),
                                  fontSize: 16 * _fontScale,
                                ),
                                onSubmitted: _isTracingRoute
                                    ? null
                                    : (value) => _traceRoute(value),
                              ),
                            ),
                            _isTracingRoute
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.getPrimaryColor(_colorScheme),
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      Icons.search,
                                      color: AppTheme.getPrimaryColor(
                                        _colorScheme,
                                      ),
                                    ),
                                    onPressed: () =>
                                        _traceRoute(_addressController.text),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 80.0,
                    right: 16.0,
                    child: FloatingActionButton(
                      heroTag: 'enterpriseBtn',
                      backgroundColor: AppTheme.getPrimaryColor(_colorScheme),
                      onPressed: () =>
                          _navigateToPage(const DeafMapEnterprisePage()),
                      child: const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
