// lib/services/global_command_service.dart

import 'package:flutter/material.dart';
import 'package:tato/models/command_result.dart';
import 'package:tato/pages/blind/blind_map_enterprise_page.dart';
import 'package:tato/pages/blind/blind_map_page.dart';
import 'package:tato/pages/blind/chat_page.dart';
import 'package:tato/pages/blind/sos_page.dart';
import 'package:tato/pages/blind/usage_guide_page.dart';
import 'package:tato/services/accessibility_service.dart';
import 'package:tato/services/command_interpreter_service.dart';
import 'package:tato/settings_page.dart';
import '../navigation_key.dart';

class GlobalCommandService {
  final CommandInterpreterService _commandInterpreterService;
  final AccessibilityService _accessibilityService;

  GlobalCommandService(this._commandInterpreterService, this._accessibilityService);

  /// Tenta executar um comando. Retorna 'true' se for um comando global e for executado.
  Future<bool> executeCommand(String rawText, CommandResult result) async {
    // REMOVIDO: A chamada duplicada ao interpretador foi removida daqui.
    // Usamos o 'result' que já veio da página.

    await _accessibilityService.stopSpeaking();

    switch (result.intent) {
      case 'open_map':
        await _accessibilityService.speak('Abrindo o mapa geral.');
        _navigateTo(const BlindMapPage());
        return true;

      case 'open_chat':
        await _accessibilityService.speak('Abrindo a página de chat.');
        // OTIMIZAÇÃO: Adicionado 'const' para melhor performance.
        _navigateTo(const BlindChatPage());
        return true;

      case 'open_settings':
        await _accessibilityService.speak('Abrindo as configurações.');
        _navigateTo(const SettingsPage());
        return true;

      case 'read_usage_guide':
        await _accessibilityService.speak('Abrindo o guia de uso.');
        _navigateTo(const UsageGuidePage());
        return true;

      case 'emergency_call':
        await _accessibilityService.speak(
          'Se mantenha em um local seguro, estou contatando a empresa sobre o risco.',
        );
        _navigateTo(const SosPage());
        return true;

      case 'open_map_enterprise':
      // ADICIONADO: Feedback de voz para consistência.
        await _accessibilityService.speak('Abrindo o mapa empresarial.');
        _navigateTo(const BlindMapEnterprisePage());
        return true;

      default:
        return false;
    }
  }

  /// Navega para uma nova página usando a chave global.
  void _navigateTo(Widget page) {
    navigationKey.currentState?.push(
      MaterialPageRoute(builder: (context) => page),
    );
  }
}