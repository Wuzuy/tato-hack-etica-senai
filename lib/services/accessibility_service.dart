// lib/services/accessibility_service.dart

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AccessibilityService {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText speechToText = SpeechToText();

  // Função para notificar a página sobre mudanças no status de escuta
  Function(bool isListening)? _onListeningStateChanged;

  /// Inicializa os serviços de TTS e STT.
  /// Agora ele configura o listener de status globalmente.
  Future<void> initialize({
    required Function(bool isListening) onListeningStateChanged,
  }) async {
    _onListeningStateChanged = onListeningStateChanged;

    await flutterTts.setLanguage("pt-BR");
    await flutterTts.setSpeechRate(0.5);

    await speechToText.initialize(
      // A CORREÇÃO ESTÁ AQUI: O onStatus é definido na inicialização
      onStatus: (status) {
        final isCurrentlyListening = speechToText.isListening;
        // Notifica a página sempre que o status de escuta mudar.
        _onListeningStateChanged?.call(isCurrentlyListening);
      },
      onError: (errorNotification) {
        print("Erro no SpeechToText: $errorNotification");
        _onListeningStateChanged?.call(false);
      },
    );
  }

  Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await flutterTts.stop();
  }

  /// Inicia a escuta do microfone.
  /// Não precisa mais do callback de status, pois já foi configurado no initialize.
  Future<void> startListening({
    required Function(String recognizedText) onResult,
  }) async {
    if (!speechToText.isAvailable || speechToText.isListening) {
      await speak(
        "O reconhecimento de voz não está disponível ou já está em uso.",
      );
      return;
    }

    await speechToText.listen(
      localeId: "pt_BR",
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          onResult(result.recognizedWords);
        }
      },
    );
  }

  /// Para a escuta do microfone manualmente.
  Future<void> stopListening() async {
    if (speechToText.isListening) {
      await speechToText.stop();
    }
  }
}
