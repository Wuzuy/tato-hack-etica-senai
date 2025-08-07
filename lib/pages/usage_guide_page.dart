import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _fontScaleKey = 'fontScale';
const String _colorSchemeKey = 'colorScheme';

class UsageGuidePage extends StatefulWidget {
  const UsageGuidePage({super.key});

  @override
  State<UsageGuidePage> createState() => _UsageGuidePageState();
}

class _UsageGuidePageState extends State<UsageGuidePage> {
  final FlutterTts _flutterTts = FlutterTts();
  final String _usageGuide = '''
GUIA DO USUÁRIO

Diga: 'olá Tati' para ativar nossa inteligência artificial.

Para traçar uma rota, diga \"Tati, traçar rota para o local\"..

Diga: 'Tati, abrir chat' para conversar com os membros da equipe.

Diga: 'Tati, configurações' para acessar a aba de ajustes do app.
''';

  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initTts();
    _speakUsageGuide();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
        _colorScheme = prefs.getString(_colorSchemeKey) ?? 'Padrão';
      });
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speakUsageGuide() async {
    await _flutterTts.speak(_usageGuide);
  }

  Color _getPrimaryColor() {
    switch (_colorScheme) {
      case 'Alto Contraste':
        return Colors.black;
      case 'Protanopia':
        return const Color.fromRGBO(85, 148, 179, 1);
      case 'Deuteranopia':
        return const Color.fromRGBO(179, 148, 85, 1);
      case 'Tritanopia':
        return const Color.fromRGBO(148, 85, 179, 1);
      case 'Modo Escuro':
        return Colors.blueGrey[800]!;
      default:
        return const Color.fromRGBO(0, 69, 118, 1);
    }
  }

  Color _getScaffoldBackgroundColor() {
    return _colorScheme == 'Modo Escuro' ? Colors.grey[900]! : Colors.white;
  }

  Color _getAppBarContentColor() {
    return _colorScheme == 'Alto Contraste' || _colorScheme == 'Modo Escuro' ? Colors.white : Colors.white;
  }

  Color _getTextColor() {
    return _colorScheme == 'Modo Escuro' ? Colors.white : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getScaffoldBackgroundColor(),
      appBar: AppBar(
        title: Text('Guia de Uso', style: TextStyle(color: _getAppBarContentColor(), fontSize: 20 * _fontScale)),
        backgroundColor: _getPrimaryColor(),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _getAppBarContentColor(), size: 24 * _fontScale),
          onPressed: () {
            _flutterTts.stop();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _usageGuide,
          style: TextStyle(
            fontSize: 16 * _fontScale,
            height: 1.5,
            color: _getTextColor(),
          ),
        ),
      ),
    );
  }
}