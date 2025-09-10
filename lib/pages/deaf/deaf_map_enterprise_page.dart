import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tato/settings_page.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/utils/app_theme.dart';

import 'deaf_chat_page.dart';
import 'deaf_sos_page.dart';
import 'deaf_voice_transcription_page.dart';

/// Página de mapa empresarial estático para o fluxo de usuário "deaf".
class DeafMapEnterprisePage extends StatefulWidget {
  const DeafMapEnterprisePage({super.key});

  @override
  State<DeafMapEnterprisePage> createState() => _DeafMapEnterprisePageState();
}

class _DeafMapEnterprisePageState extends State<DeafMapEnterprisePage> {
  // --- Serviços ---
  final SettingsService _settingsService = SettingsService();

  // --- Estado da UI ---
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  /// Carrega as configurações da página usando o serviço.
  Future<void> _initializePage() async {
    _fontScale = await _settingsService.loadFontScale();
    _colorScheme = await _settingsService.loadColorScheme();
    if (mounted) setState(() {});
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
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => const SettingsPage(useGoogleFonts: true)))
                  .then((_) => _initializePage()); // Recarrega as configurações ao voltar
            },
          ),
        ],
      ),
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
                  // Caminho padrão do Flutter para assets
                  'images/mapa.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey,
                      child: Center(
                        child: Text(
                          'Erro ao carregar o mapa. Verifique a configuração no pubspec.yaml.',
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              color: AppTheme.getMessageTextColor(_colorScheme, false),
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

            // --- BOTÕES FLUTUANTES ADICIONADOS ---
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'chatBtn',
                    backgroundColor: AppTheme.getPrimaryColor(_colorScheme),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const DeafChatPage()),
                      );
                    },
                    child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    heroTag: 'transcriptionBtn',
                    backgroundColor: AppTheme.getPrimaryColor(_colorScheme),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const VoiceTranscriptionDeafPage()),
                      );
                    },
                    child: const Icon(Icons.mic, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16.0,
              left: 16.0,
              child: FloatingActionButton(
                heroTag: 'sosBtn',
                backgroundColor: Colors.red,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const DeafSosPage()),
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