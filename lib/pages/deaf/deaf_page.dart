import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'deaf_chat_page.dart';

class DeafPage extends StatefulWidget {
  const DeafPage({super.key});

  @override
  State<DeafPage> createState() => _DeafPageState();
}

class _DeafPageState extends State<DeafPage> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  List<Marker> _markers = [];
  final LatLng _userLocation = LatLng(-22.7884, -43.3101); // Localização de exemplo (SENAI Caxias)
  final LatLng _senaiLocation = LatLng(-22.7884, -43.3101); // Exemplo de um local na empresa

  @override
  void initState() {
    super.initState();
    _addInitialMarkers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addInitialMarkers() {
    _markers = [
      Marker(
        width: 80.0,
        height: 80.0,
        point: _userLocation,
        child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
      ),
      Marker(
        width: 80.0,
        height: 80.0,
        point: _senaiLocation,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ),
      Marker(
        width: 80.0,
        height: 80.0,
        point: const LatLng(-22.7882, -43.3102),
        child: const Icon(Icons.person_pin_circle, color: Colors.purple, size: 40),
      ),
      Marker(
        width: 80.0,
        height: 80.0,
        point: const LatLng(-22.7886, -43.3100),
        child: const Icon(Icons.person_pin_circle, color: Colors.green, size: 40),
      ),
    ];
  }

  Future<void> _searchLocal() async {
    try {
      List<geocoding.Location> locations = await geocoding.locationFromAddress(_searchController.text);
      if (locations.isNotEmpty) {
        final LatLng destination = LatLng(locations.first.latitude, locations.first.longitude);

        setState(() {
          _markers.add(
            Marker(
              width: 80.0,
              height: 80.0,
              point: destination,
              child: const Icon(Icons.location_pin, color: Colors.orange, size: 40),
            ),
          );
        });

        _mapController.move(destination, 18.0);
      }
    } catch (e) {
      print("Erro ao buscar endereço: $e");
    }
  }

  void _sendSOSMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Alerta de Emergência"),
          content: const Text("Uma mensagem de SOS foi enviada para a equipe."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToDeafChatPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DeafChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TATO', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(0, 69, 118, 1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: <Widget>[
          // Mapa da Empresa
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-22.7884, -43.3101),
              initialZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.tato',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // Campo de pesquisa
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Pesquisar Local..',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) => _searchLocal(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Color.fromRGBO(0, 69, 118, 1)),
                      onPressed: _searchLocal,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botões de ação
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botão de chat
                FloatingActionButton(
                  heroTag: 'chatButton',
                  backgroundColor: const Color.fromRGBO(0, 69, 118, 1),
                  onPressed: _navigateToDeafChatPage,
                  child: const Icon(Icons.chat, color: Colors.white),
                ),
                const SizedBox(height: 10),
                // Botão de SOS
                FloatingActionButton(
                  heroTag: 'sosButton',
                  backgroundColor: Colors.red,
                  onPressed: _sendSOSMessage,
                  child: const Icon(Icons.warning, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}