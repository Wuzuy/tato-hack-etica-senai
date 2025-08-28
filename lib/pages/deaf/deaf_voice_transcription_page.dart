import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _fontScaleKey = 'fontScale';
const String _colorSchemeKey = 'colorScheme';

class VoiceTranscriptionDeafPage extends StatefulWidget {
  const VoiceTranscriptionDeafPage({super.key});

  @override
  State<VoiceTranscriptionDeafPage> createState() => _VoiceTranscriptionDeafPageState();
}

class _VoiceTranscriptionDeafPageState extends State<VoiceTranscriptionDeafPage> {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _transcribedText = 'O que será transcrito aparecerá aqui.';

  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  GenerativeModel? _generativeModel;
  String _optimizedText = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initSpeechToText();
    _initGenerativeModel();
  }

  Future<void> _initGenerativeModel() async {
    const apiKey = "AIzaSyDmc2PD3EaNvSfd5iY3Mn_iTtX1_0CpDfI";
    if (apiKey.isEmpty) {
      print("API Key não configurada para o Gemini.");
      return;
    }
    _generativeModel = GenerativeModel(model: 'gemini', apiKey: apiKey);
    print("API Key carregada com sucesso.");
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
      _colorScheme = prefs.getString(_colorSchemeKey) ?? 'Padrão';
    });
  }

  Future<void> _initSpeechToText() async {
    bool available = await _speechToText.initialize();
    if (!available) {
      if (mounted) {
        setState(() {
          _transcribedText = "O serviço de reconhecimento de voz não está disponível.";
        });
      }
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _speechToText.stop();
      setState(() {
        _isListening = false;
      });

      if (_transcribedText.isNotEmpty) {
      _generateOptimizedText(_transcribedText);
      _transcribedText = _optimizedText;
      }

    } else {
      if (_speechToText.isAvailable) {
        _transcribedText = '';
        _optimizedText = '';
        _speechToText.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _transcribedText = result.recognizedWords;
              });
            }
          },
          listenFor: const Duration(minutes: 1),
          localeId: 'pt_BR',
        );
        setState(() {
          _isListening = true;
        });
      } else {
        if (mounted) {
          setState(() {
            _transcribedText = "O serviço de reconhecimento de voz não está disponível.";
          });
        }
      }
    }
  }

  Future<void> _generateOptimizedText(String textToOptimize) async {
    if (_generativeModel == null) {
      print("Modelo generativo não inicializado.");
      setState(() {
        _optimizedText = "Erro: Modelo generativo não disponível.";
      });
      return;
    }

    if (textToOptimize.trim().isEmpty) {
      setState(() {
        _optimizedText = '';
      });
      return;
    }

    setState(() {
      _optimizedText = "Otimizando...";
    });

    try {
      final prompt = 'Por favor, corrija a gramática e melhore a clareza da seguinte frase, mantendo o significado e seguindo a maneira de fala do usuário. Se a frase estiver vazia, retorne a frase original novamente. Frase: $textToOptimize ';
      final content = [Content.text(prompt)];
      final response = await _generativeModel!.generateContent(content);

      if (mounted) {
        setState(() {
          _optimizedText = response.text ?? "Não foi possível gerar o texto otimizado.";
        });
      }
    } catch (e) {
      print("Erro ao otimizar o texto com o google_generative_ai: $e");
      if (mounted) {
        setState(() {
          _optimizedText = "Erro: Não foi possível otimizar o texto.";
        });
      }
    }
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

  Color _getTextColor() {
    return _colorScheme == 'Modo Escuro' ? Colors.white : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getScaffoldBackgroundColor(),
      appBar: AppBar(
        backgroundColor: _getPrimaryColor(),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                InkWell(
                  onTap: _toggleListening,
                  borderRadius: BorderRadius.circular(100),
                  child: CircleAvatar(
                    radius: 80 * _fontScale,
                    backgroundColor: _getPrimaryColor(),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 100 * _fontScale,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isListening ? 'Ouvindo...' : 'Aperte o botão para captar voz',
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      color: _getTextColor(),
                      fontSize: 18 * _fontScale,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transcrição:',
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            color: _getTextColor(),
                            fontSize: 16 * _fontScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _colorScheme == 'Modo Escuro' ? Colors.grey[700] : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _getPrimaryColor(), width: 2),
                        ),
                        child: Text(
                          _transcribedText,
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              fontSize: 16 * _fontScale,
                              color: _colorScheme == 'Modo Escuro' ? Colors.white : Colors.black,
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
        ),
      ),
    );
  }
}
