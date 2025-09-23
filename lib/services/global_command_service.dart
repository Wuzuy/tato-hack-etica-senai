import 'package:flutter/material.dart';
import 'package:tato/models/command_result.dart';
import 'package:tato/navigation_key.dart';
import 'package:tato/services/accessibility_service.dart';
import 'package:tato/services/command_interpreter_service.dart';

import 'package:tato/pages/blind/blind_map_page.dart';
import 'package:tato/pages/blind/blind_chat_page.dart';
import 'package:tato/settings_page.dart';
import 'package:tato/pages/blind/blind_usage_guide_page.dart';
import 'package:tato/pages/blind/sos_page.dart';
import 'package:tato/pages/blind/blind_map_enterprise_page.dart';

class GlobalCommandService {
  // ignore: unused_field
  final CommandInterpreterService _interpreterService;
  final AccessibilityService _accessibilityService;

  GlobalCommandService(this._interpreterService, this._accessibilityService);

  /// Tenta executar um comando. Retorna 'true' se for um comando global e for executado.
  Future<bool> executeCommand(String rawText, CommandResult result) async {
    await _accessibilityService.stopSpeaking();

    switch (result.intent) {
      // --- Cases de Comandos GLOBAIS ---
      case 'open_map':
        await _accessibilityService.speak('Abrindo o mapa geral.');
        _navigateTo(const BlindMapPage());
        return true; // Comando tratado
      case 'open_chat':
        await _accessibilityService.speak('Abrindo a página de chat.');
        _navigateTo(const BlindChatPage());
        return true; // Comando tratado
      case 'open_settings':
        await _accessibilityService.speak('Abrindo as configurações.');
        _navigateTo(const SettingsPage());
        return true; // Comando tratado
      case 'read_usage_guide':
        await _accessibilityService.speak('Abrindo o guia de uso.');
        _navigateTo(const UsageGuidePage());
        return true; // Comando tratado
      case 'emergency_call':
        await _accessibilityService.speak(
          'Iniciando procedimento de emergência.',
        );
        _navigateTo(const SosPage());
        return true; // Comando tratado
      case 'open_map_enterprise':
        await _accessibilityService.speak('Abrindo o mapa empresarial.');
        _navigateTo(const BlindMapEnterprisePage());
        return true; // Comando tratado

      // --- Comando NÃO é global ---
      default:
        // Se a intenção for 'navigate_to_address', 'send_chat_message', ou 'unknown',
        // este serviço não faz nada e retorna 'false', devolvendo o controle para a página.
        return false;
    }
  }

  /// Navega usando a GlobalKey.
  void _navigateTo(Widget page) {
    // Usa a chave global para acessar o navegador sem precisar de um BuildContext!
    navigationKey.currentState?.push(
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
