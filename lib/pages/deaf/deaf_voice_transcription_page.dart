import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tato/services/accessibility_service.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/utils/app_theme.dart';

/// Uma página dedicada a transcrever a fala do ambiente para texto.
class VoiceTranscriptionDeafPage extends StatefulWidget {
  const VoiceTranscriptionDeafPage({super.key});

  @override
  State<VoiceTranscriptionDeafPage> createState() =>
      _VoiceTranscriptionDeafPageState();
}

class _VoiceTranscriptionDeafPageState
    extends State<VoiceTranscriptionDeafPage> {
  // --- Serviços ---
  final SettingsService _settingsService = SettingsService();
  final AccessibilityService _accessibilityService = AccessibilityService();

  // --- Estado da UI ---
  bool _isListening = false;
  String _transcribedText = 'O que for dito aparecerá aqui.';
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  @override
  void dispose() {
    _accessibilityService.stopListening();
    super.dispose();
  }

  /// Carrega as configurações e inicializa o serviço de acessibilidade.
  Future<void> _initializePage() async {
    _fontScale = await _settingsService.loadFontScale();
    _colorScheme = await _settingsService.loadColorScheme();
    await _accessibilityService.initialize(
      onListeningStateChanged: (isListening) {
        if (mounted) setState(() => _isListening = isListening);
      },
    );
    if (mounted) setState(() {});
  }

  /// Alterna o estado de escuta do microfone usando o serviço.
  void _toggleListening() {
    if (_isListening) {
      _accessibilityService.stopListening();
    } else {
      setState(() => _transcribedText = ''); // Limpa o texto anterior
      _accessibilityService.startListening(
        onResult: (recognizedWords) {
          if (mounted) {
            setState(() => _transcribedText = recognizedWords);
          }
        },
      );
    }
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
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                InkWell(
                  onTap: _toggleListening,
                  borderRadius: BorderRadius.circular(100),
                  child: CircleAvatar(
                    radius: 80 * _fontScale,
                    backgroundColor: AppTheme.getPrimaryColor(_colorScheme),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 100 * _fontScale,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isListening ? 'Ouvindo...' : 'Toque no botão para captar voz',
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      color: AppTheme.getMessageTextColor(_colorScheme, false),
                      fontSize: 18 * _fontScale,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transcrição:',
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            color: AppTheme.getMessageTextColor(_colorScheme, false),
                            fontSize: 16 * _fontScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        width: double.infinity,
                        height: 150, // Altura fixa para a caixa de texto
                        decoration: BoxDecoration(
                          color: _colorScheme == 'Modo Escuro' ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.getPrimaryColor(_colorScheme), width: 2),
                        ),
                        child: SingleChildScrollView( // Permite rolagem se o texto for grande
                          child: Text(
                            _transcribedText,
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                fontSize: 16 * _fontScale,
                                color: AppTheme.getMessageTextColor(_colorScheme, false),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}