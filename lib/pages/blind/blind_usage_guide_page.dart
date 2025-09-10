import 'package:flutter/material.dart';
import 'package:tato/services/accessibility_service.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/utils/app_theme.dart';

/// Uma página que exibe e lê em voz alta o guia de uso do aplicativo.
class UsageGuidePage extends StatefulWidget {
  const UsageGuidePage({super.key});

  @override
  State<UsageGuidePage> createState() => _UsageGuidePageState();
}

class _UsageGuidePageState extends State<UsageGuidePage> {
  // --- Serviços ---
  final SettingsService _settingsService = SettingsService();
  final AccessibilityService _accessibilityService = AccessibilityService();

  // --- Conteúdo e Estado da UI ---
  final String _usageGuide = '''
GUIA DO USUÁRIO

Para interagir com o assistente, toque e segure o botão do microfone e fale um comando.

Para traçar uma rota no mapa, diga "me leve para" seguido do seu destino.

Para enviar um alerta de emergência, diga "socorro" ou utilize o botão de SOS.

Para conversar livremente com a inteligência artificial, use a página de Chat.

Para ajustar as cores e o tamanho da fonte, diga "abrir configurações".
''';

  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  /// Carrega configurações e inicializa os serviços.
  Future<void> _initializePage() async {
    _fontScale = await _settingsService.loadFontScale();
    _colorScheme = await _settingsService.loadColorScheme();

    // CORREÇÃO: Passamos a função exigida pelo method 'initialize'.
    await _accessibilityService.initialize(
      onListeningStateChanged: (isListening) {
        // Esta página não tem feedback de escuta, então a função pode ser vazia.
        // Apenas cumprimos o contrato do method.
      },
    );

    await _accessibilityService.speak(_usageGuide);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _accessibilityService.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackgroundColor(_colorScheme),
      appBar: AppBar(
        title: Text(
          'Guia de Uso',
          style: TextStyle(color: Colors.white, fontSize: 20 * _fontScale),
        ),
        backgroundColor: AppTheme.getPrimaryColor(_colorScheme),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 24 * _fontScale,
          ),
          onPressed: () {
            // Garante que a fala pare ao voltar
            _accessibilityService.stopSpeaking();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _usageGuide,
            style: TextStyle(
              fontSize: 16 * _fontScale,
              height: 1.5,
              color: AppTheme.getMessageTextColor(_colorScheme, false),
            ),
          ),
        ),
      ),
    );
  }
}
