import 'package:flutter/material.dart';
import 'package:tato/models/command_result.dart';
import 'package:tato/services/accessibility_service.dart';
import 'package:tato/services/command_interpreter_service.dart';
import 'package:tato/services/gemini_service.dart';
import 'package:tato/services/global_command_service.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/utils/app_theme.dart';

// Importações das páginas de destino
import 'sos_page.dart';

/// Uma página de mapa demonstrativa (Empresarial) controlada por voz.
class BlindMapEnterprisePage extends StatefulWidget {
  const BlindMapEnterprisePage({super.key});

  @override
  State<BlindMapEnterprisePage> createState() => _BlindMapEnterprisePageState();
}

class _BlindMapEnterprisePageState extends State<BlindMapEnterprisePage> {
  // --- Serviços ---
  final SettingsService _settingsService = SettingsService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  final GeminiService _geminiService = GeminiService();
  late final CommandInterpreterService _commandInterpreterService;
  late final GlobalCommandService _globalCommandService;

  // --- Estado da UI ---
  bool _isListening = false;
  String _lastWords = '';
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  @override
  void initState() {
    super.initState();
    _commandInterpreterService = CommandInterpreterService(_geminiService);
    _globalCommandService = GlobalCommandService(_commandInterpreterService, _accessibilityService);
    _initializePage();
  }

  /// Carrega configurações e inicializa os serviços.
  Future<void> _initializePage() async {
    _fontScale = await _settingsService.loadFontScale();
    _colorScheme = await _settingsService.loadColorScheme();

    // CORRIGIDO: Passa o callback necessário para o method initialize.
    await _accessibilityService.initialize(
      onListeningStateChanged: (isListening) {
        if (mounted) setState(() => _isListening = isListening);
      },
    );

    await _accessibilityService.speak(
      "Você está na página de mapa demonstrativo. Toque no botão de microfone para interagir.",
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _accessibilityService.stopSpeaking();
    _accessibilityService.stopListening();
    super.dispose();
  }

  /// Inicia a escuta de voz.
  void _startListening() {
    setState(() => _lastWords = '');
    // CORRIGIDO: A chamada agora é mais simples.
    _accessibilityService.startListening(
      onResult: (recognizedWords) {
        setState(() => _lastWords = recognizedWords);
        _handleVoiceCommand(recognizedWords);
      },
    );
  }

  /// Para a escuta de voz.
  void _stopListening() {
    // CORRIGIDO: A chamada agora é mais simples.
    _accessibilityService.stopListening();
  }

  /// Processa o texto falado, delegando para o serviço global primeiro.
  Future<void> _handleVoiceCommand(String text) async {
    final CommandResult result = await _commandInterpreterService.interpretCommand(text);
    final bool wasHandledGlobally = await _globalCommandService.executeCommand(text, result);

    if (!wasHandledGlobally) {
      // Trata comandos que NÃO são globais e são específicos desta página
      switch (result.intent) {
        case 'navigate_to_address':
          await _accessibilityService.speak(
            "Esta é uma página de demonstração, não é possível traçar rotas.",
          );
          break;
        default:
          await _accessibilityService.speak(
            "Comando não reconhecido. Diga 'guia de uso' para ver os comandos.",
          );
          break;
      }
    }
  }

  void _navigateToSosPage() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SosPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackgroundColor(_colorScheme),
      appBar: AppBar(
        backgroundColor: AppTheme.getPrimaryColor(_colorScheme),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24 * _fontScale),
          onPressed: () {
            _accessibilityService.stopSpeaking();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white, size: 24 * _fontScale),
            onPressed: () => _globalCommandService.executeCommand("guia de uso", CommandResult(intent: 'read_usage_guide', parameters: {})),
            tooltip: 'Guia de Uso',
          ),
          IconButton(
            icon: Icon(Icons.chat, color: Colors.white, size: 24 * _fontScale),
            onPressed: () => _globalCommandService.executeCommand("abrir chat", CommandResult(intent: 'open_chat', parameters: {})),
            tooltip: 'Chat',
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white, size: 24 * _fontScale),
            onPressed: () => _globalCommandService.executeCommand("abrir configurações", CommandResult(intent: 'open_settings', parameters: {})),
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
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey,
                  child: Center(
                    child: Text('Erro ao carregar o mapa',
                        style: TextStyle(color: AppTheme.getMessageTextColor(_colorScheme, false))),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 64.0,
                    height: 64.0,
                    child: Card(
                      color: Colors.red[800],
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: InkWell(
                        onTap: _navigateToSosPage,
                        borderRadius: BorderRadius.circular(15),
                        child: Icon(Icons.warning, color: Colors.white, size: 40 * _fontScale),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: AppTheme.getScaffoldBackgroundColor(_colorScheme),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: InkWell(
                      onTap: _isListening ? _stopListening : _startListening,
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isListening ? Icons.mic_off : Icons.mic,
                              color: _isListening ? Colors.red : AppTheme.getPrimaryColor(_colorScheme),
                              size: 36 * _fontScale,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _isListening
                                    ? "Ouvindo..."
                                    : (_lastWords.isEmpty ? "Toque para falar" : _lastWords),
                                style: TextStyle(
                                    fontSize: 18 * _fontScale,
                                    color: AppTheme.getMessageTextColor(_colorScheme, false)),
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