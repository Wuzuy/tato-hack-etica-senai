import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'deaf_sos_page.dart';
import 'deaf_settings_page.dart';
import 'deaf_voice_transcription_page.dart';
import 'deaf_chat_page.dart';

const String _fontScaleKey = 'fontScale';
const String _colorSchemeKey = 'colorScheme';

class DeafMapEnterprisePage extends StatefulWidget {
  const DeafMapEnterprisePage({super.key});

  @override
  State<DeafMapEnterprisePage> createState() => _DeafMapEnterprisePageState();
}

class _DeafMapEnterprisePageState extends State<DeafMapEnterprisePage> {
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DeafSettingsPage(),
                ),
              );
              _loadSettings();
            },
          ),
        ],
      ),
      backgroundColor: _getScaffoldBackgroundColor(),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                minScale: 1.0,
                maxScale: 3.0,
                child: Image.asset(
                  'images/mapa.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey,
                      child: Center(
                        child: Text(
                          'Erro ao carregar a imagem do mapa. Verifique a configuração do pubspec.yaml e a pasta images.',
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              color: _getTextColor(),
                              fontSize: 14 * _fontScale,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Botões da direita
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'chatBtn',
                    mini: false,
                    backgroundColor: _getPrimaryColor(),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DeafChatPage(),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    heroTag: 'transcriptionBtn',
                    mini: false,
                    backgroundColor: _getPrimaryColor(),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const VoiceTranscriptionDeafPage(),
                        ),
                      );
                    },
                    child: const Icon(Icons.mic, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),

            // Botão SOS na esquerda
            Positioned(
              bottom: 16.0,
              left: 16.0,
              child: FloatingActionButton(
                heroTag: 'sosBtn',
                mini: false,
                backgroundColor: Colors.red,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DeafSosPage(),
                    ),
                  );
                },
                child: const Icon(Icons.warning, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
