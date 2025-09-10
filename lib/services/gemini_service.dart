// lib/services/gemini_service.dart

import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiService {
  final Gemini _gemini = Gemini.instance;

  Future<String> sendMessage(String userMessage) async {
    try {
      final response = await _gemini.chat([
        Content(
          parts: [Part.text(userMessage)],
          role: 'user',
        ),
      ]);

      final output = response?.output;

      if (output != null && output.isNotEmpty) {
        return output;
      } else {
        // Se a resposta vier vazia, isso também é um erro.
        throw Exception('A resposta do Gemini veio vazia ou nula.');
      }
    } catch (e) {
      print("Erro no GeminiService: $e");
      // ALTERADO: Em vez de retornar um texto, lançamos uma exceção.
      throw Exception('Falha ao comunicar com a API do Gemini. Verifique a chave, faturamento ou conexão.');
    }
  }
}