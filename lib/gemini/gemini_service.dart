import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiService {
  bool _isLoading = false;
  final Gemini _gemini = Gemini.instance;

  Future<String> sendMessage(String userMessage) async {
    try {
      // 1. Envia a mensagem para a API
      final response = await _gemini.chat([
        Content(parts: [Part.text(userMessage)], role: 'user'),
      ]);

      // 2. LÓGICA FINAL E CORRETA PARA LER A RESPOSTA
      // Acessamos a propriedade '.output' que já contém o texto completo.
      final output = response?.output;

      // 3. Verificamos se a saída de texto é válida
      if (output != null && output.isNotEmpty) {
        return output; // Retornamos o texto diretamente
      } else {
        // Fallback caso a resposta venha sem texto por algum motivo
        return "Não recebi uma resposta em texto. Tente novamente.";
      }
    } catch (e) {
      print('Erro ao se comunicar com a API do Gemini: $e');
      return "Ocorreu um erro de comunicação. Verifique sua conexão.";
    }
  }
}
