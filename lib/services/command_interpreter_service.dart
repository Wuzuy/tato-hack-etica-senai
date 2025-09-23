import 'dart:convert';

import 'package:tato/models/command_result.dart';
import 'package:tato/services/gemini_service.dart';

class CommandInterpreterService {
  final GeminiService _geminiService;

  CommandInterpreterService(this._geminiService);

  Future<CommandResult> interpretCommand(String rawText) async {
    final prompt = _buildPromptForCommand(rawText);

    try {
      // Esta chamada agora pode lançar uma exceção
      final geminiResponse = await _geminiService.sendMessage(prompt);

      final cleanJsonResponse = geminiResponse
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final jsonResponse = jsonDecode(cleanJsonResponse);

      return CommandResult(
        intent: jsonResponse['intent'] ?? 'unknown',
        parameters: Map<String, dynamic>.from(jsonResponse['parameters'] ?? {}),
      );
    } catch (e) {
      // Este catch agora vai capturar a exceção do GeminiService
      print("Erro ao interpretar comando: $e");
      return CommandResult.failure();
    }
  }

  String _buildPromptForCommand(String userInput) {
    return '''
      Analise o texto do usuário para um aplicativo de acessibilidade.
      Sua tarefa é identificar a intenção principal e extrair os parâmetros relevantes.
      Responda APENAS com um objeto JSON válido. Não inclua texto explicativo antes ou depois.

      Intenções Válidas e seus Parâmetros:
      - "open_map": Quando o usuário quer abrir o mapa geral.
      - "navigate_to_address": Quando o usuário quer ir para um local específico.
      - "open_chat": Quando o usuário quer abrir a página de chat.
      - "open_map_enterprise": Quando o usuário quer abrir o mapa empresarial."
        - Parâmetros: {"address": "o endereço completo extraído do texto"}
      - "emergency_call": Quando o usuário pede ajuda ou menciona emergência.
      - "read_usage_guide": Quando o usuário pergunta como usar o app ou pede o guia.
      - "open_settings": Quando o usuário quer ajustar as configurações.
      - "send_chat_message": Quando o comando parece uma mensagem para o chat e não uma ação.
      
        - Parâmetros: {"message": "o texto original da mensagem"}
      - "unknown": Se o comando não se encaixa em nenhuma das intenções acima.

      Exemplos de Mapeamento:
      - Usuário: "abrir mapa" -> {"intent": "open_map", "parameters": {}}
      - Usuário: "preciso ir para a Avenida Paulista, 500" -> {"intent": "navigate_to_address", "parameters": {"address": "Avenida Paulista, 500"}}
      - Usuário: "socorro, preciso de ajuda agora" -> {"intent": "emergency_call", "parameters": {}}
      - Usuário: "como eu uso isso?" -> {"intent": "read_usage_guide", "parameters": {}}
      - Usuário: "olá tudo bem com você" -> {"intent": "send_chat_message", "parameters": {"message": "olá tudo bem com você"}}
      - Usuário: "qual a capital da frança" -> {"intent": "unknown", "parameters": {}}

      Texto do usuário para analisar: "$userInput"
    ''';
  }
}
