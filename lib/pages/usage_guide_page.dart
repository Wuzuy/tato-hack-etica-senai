import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

Para traçar uma rota, digite o endereço no campo de texto e pressione o botão de pesquisa.

Diga: 'abrir chat' para conversar com os membros da equipe.

Diga: 'configurações' para acessar a aba de ajustes do app.
''';

  @override
  void initState() {
    super.initState();
    _initTts();
    _speakUsageGuide();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speakUsageGuide() async {
    await _flutterTts.speak(_usageGuide);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guia de Uso', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(0, 69, 118, 1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _flutterTts.stop();
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: const Color.fromRGBO(0, 69, 118, 1),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Text(
            _usageGuide,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}