import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';

import 'blind_usage_guide_page.dart';
import 'blind_chat_page.dart';
import 'blind_settings_page.dart';
import 'sos_page.dart';

const String _fontScaleKey = 'fontScale';
const String _colorSchemeKey = 'colorScheme';

class BlindMapEnterprisePage extends StatefulWidget {
  const BlindMapEnterprisePage({super.key});

  @override
  State<BlindMapEnterprisePage> createState() => _BlindMapEnterprisePageState();
}

class _BlindMapEnterprisePageState extends State<BlindMapEnterprisePage> {
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';

  String _listeningText = "Escutando";
  Timer? _typingTimer;
  int _dotCount = 0;

  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initTts();
    _speakInitialInstructions();
    _speech = stt.SpeechToText();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    _typingTimer?.cancel();
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
        "Você está na página de mapa demonstrativo. Toque no botão de microfone para interagir.");
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if (mounted) {
          if (status == stt.SpeechToText.listeningStatus) {
            setState(() {
              _isListening = true;
              _startTypingAnimation();
            });
          } else {
            setState(() {
              _isListening = false;
              _stopTypingAnimation();
            });
          }
        }
      },
      onError: (error) => debugPrint('Speech error: $error'),
    );
    if (!available) {
      _flutterTts.speak("O reconhecimento de voz não está disponível neste dispositivo.");
    }
  }

  void _startTypingAnimation() {
    _dotCount = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4; // Ciclo de 0 a 3 pontos
          _listeningText = "Escutando" + "." * _dotCount;
        });
      }
    });
  }

  void _stopTypingAnimation() {
    _typingTimer?.cancel();
    _listeningText = "Escutando";
    _dotCount = 0;
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

    if (normalizedCommand.contains('tati socorro') || normalizedCommand.contains('socorro')) {
      _flutterTts.stop();
      _speech.stop();
      _flutterTts.speak('Comando de socorro recebido. Enviando sua localização para a equipe de emergência.');
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SosPage(),
          ),
        );
      });
      return;
    }

    if (normalizedCommand.contains('me leve a') || normalizedCommand.contains('me leve ao')) {
      _flutterTts.speak("Esta é uma página de demonstração, não é possível traçar rotas.");
    } else if (normalizedCommand.contains('guia')) {
      _navigateToUsageGuidePage();
    } else if (normalizedCommand.contains('chat')) {
      _navigateToChatPage();
    } else if (normalizedCommand.contains('configurações') || normalizedCommand.contains('ajustes')) {
      _navigateToSettingsPage();
    } else {
      _flutterTts.speak("Comando não reconhecido. Por favor, tente novamente.");
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
            icon: Icon(Icons.help_outline, color: _getAppBarIconColor(), size: 24 * _fontScale),
            onPressed: _navigateToUsageGuidePage,
            tooltip: 'Guia de Uso',
          ),
          IconButton(
            icon: Icon(Icons.chat, color: _getAppBarIconColor(), size: 24 * _fontScale),
            onPressed: _navigateToChatPage,
            tooltip: 'Chat',
          ),
          IconButton(
            icon: Icon(Icons.settings, color: _getAppBarIconColor(), size: 24 * _fontScale),
            onPressed: _navigateToSettingsPage,
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Image.asset(
                'images/mapa.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey,
                    child: Center(
                      child: Text(
                        'Erro ao carregar a imagem do mapa',
                        style: TextStyle(color: _getTextColor()),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 64.0,
                    height: 64.0,
                    child: Card(
                      color: Colors.red[800],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: InkWell(
                        onTap: () {
                          _flutterTts.stop();
                          _speech.stop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SosPage(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Icon(Icons.warning, color: Colors.white, size: 40 * _fontScale),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botão de microfone
                  Card(
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
                                    ? _listeningText
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
