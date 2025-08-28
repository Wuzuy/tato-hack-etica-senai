import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'blind_usage_guide_page.dart';
import 'blind_chat_page.dart';
import 'blind_settings_page.dart';

class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = 'Toque para falar.';

  String _listeningText = "Ouvindo";
  Timer? _typingTimer;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeechToText();
    _speak('Socorro enviado! Sua localização e pedido de ajuda foram enviados para os serviços de emergência.');
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('pt-BR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _initSpeechToText() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (status) {
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
      onError: (errorNotification) => print('onError: $errorNotification'),
    );
    if (!available) {
      if (mounted) {
        setState(() {
          _lastWords = 'O serviço de reconhecimento de voz não está disponível.';
        });
      }
      _speak(_lastWords);
    }
  }

  void _startTypingAnimation() {
    _dotCount = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
          _listeningText = "Ouvindo" + "." * _dotCount;
        });
      }
    });
  }

  void _stopTypingAnimation() {
    _typingTimer?.cancel();
    _listeningText = "Ouvindo";
    _dotCount = 0;
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  void _startListening() async {
    _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _lastWords = result.recognizedWords;
          });
        }
        if (result.finalResult) {
          _processVoiceCommand(_lastWords);
          _stopListening();
        }
      },
      localeId: 'pt_BR',
      listenFor: const Duration(seconds: 10),
      onSoundLevelChange: (level) => print('onSoundLevelChange: $level'),
    );
  }

  void _stopListening() {
    _speech.stop();
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _processVoiceCommand(String command) {
    String normalizedCommand = command.toLowerCase().trim();

    if (normalizedCommand.contains('abrir mapa') || normalizedCommand.contains('voltar')) {
      _speak('Voltando para o mapa.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (normalizedCommand.contains('guia')) {
      _navigateToUsageGuidePage();
    } else if (normalizedCommand.contains('chat')) {
      _navigateToChatPage();
    } else if (normalizedCommand.contains('configurações') || normalizedCommand.contains('ajustes')) {
      _navigateToSettingsPage();
    } else {
      _speak("Comando não reconhecido. Por favor, toque novamente e tente outra vez.");
    }
  }

  void _navigateToUsageGuidePage() {
    _flutterTts.stop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const UsageGuidePage()),
    );
  }

  void _navigateToChatPage() {
    _flutterTts.stop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }

  void _navigateToSettingsPage() {
    _flutterTts.stop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[800],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 100,
              ),
              const SizedBox(height: 32),
              const Text(
                'Socorro Enviado!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sua localização e pedido de ajuda foram enviados para os serviços de emergência.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _isListening ? _listeningText : _lastWords,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _toggleListening,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mic,
                      color: _isListening ? Colors.red : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isListening ? _listeningText : 'Toque para Falar',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                child: const Text(
                  'Voltar para o Mapa',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
