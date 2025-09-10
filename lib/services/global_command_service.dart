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

  GlobalCommandService(
    this._commandInterpreterService,
    this._accessibilityService,
  );

  Future<bool> executeCommand(String rawText, CommandResult result) async {
    final CommandResult result = await _commandInterpreterService
        .interpretCommand(rawText);
    await _accessibilityService.stopSpeaking();

    switch (result.intent) {
      case 'open_map':
        await _accessibilityService.speak('Abrindo o mapa geral.');
        _navigateTo(const BlindMapPage());
        return true;
      case 'open_chat':
        await _accessibilityService.speak('Abrindo a página de chat.');
        _navigateTo(BlindChatPage());
        return true;

      case 'open_settings':
        await _accessibilityService.speak('Abrindo as configurações.');
        _navigateTo(SettingsPage());
        return true;

      case 'read_usage_guide':
        await _accessibilityService.speak('Abrindo o guia de uso.');
        _navigateTo(UsageGuidePage());
        return true;

      case 'emergency_call':
        await _accessibilityService.speak(
          'Se mantenha em um local seguro marcado no mapa, estou contatando a empresa sobre o risco.',
        );
        _navigateTo(SosPage());
        return true;

      case 'open_map_enterprise':
        _navigateTo(const BlindMapEnterprisePage());
        return true;

      default:
        return false;
    }
  }

  void _navigateTo(Widget page) {
    navigationKey.currentState?.push(
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
