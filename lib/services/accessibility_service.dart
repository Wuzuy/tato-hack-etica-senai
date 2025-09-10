import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AccessibilityService {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText speechToText = SpeechToText();
  Function(bool isListening)? _onListeningStateChanged;

  /// Inicializa os serviços de TTS e STT, configurando o listener de status.
  Future<void> initialize({
    required Function(bool isListening) onListeningStateChanged,
  }) async {
    _onListeningStateChanged = onListeningStateChanged;
    await flutterTts.setLanguage("pt-BR");
    await flutterTts.setSpeechRate(0.5);
    await speechToText.initialize(
      onStatus: (status) {
        _onListeningStateChanged?.call(speechToText.isListening);
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

  /// Inicia a escuta do microfone com proteção contra erros.
  Future<void> startListening({
    required Function(String recognizedText) onResult,
  }) async {
    if (!speechToText.isAvailable || speechToText.isListening) {
      await speak("O reconhecimento de voz não está disponível ou já está em uso.");
      return;
    }

    // ADICIONADO: Bloco try/catch para robustez extra.
    try {
      await speechToText.listen(
        localeId: "pt_BR",
        onResult: (result) {
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
      );
    } catch (e) {
      print("Erro ao iniciar a escuta (startListening): $e");
      // Garante que a UI seja notificada do erro e volte ao estado 'não ouvindo'.
      _onListeningStateChanged?.call(false);
    }
  }

  /// Para a escuta do microfone manualmente.
  Future<void> stopListening() async {
    if (speechToText.isListening) {
      await speechToText.stop();
    }
  }
}