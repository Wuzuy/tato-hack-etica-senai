import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

const String _fontScaleKey = 'fontScale';
const String _colorSchemeKey = 'colorScheme';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isAudioInputMode = true;
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';
  String _lastWords = '';

  List<Map<String, String>> get _messages => [
    {'sender': 'Equipe de Apoio', 'text': 'Olá! Como posso ajudar você?'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initTts();
    _readLastMessage();
    _speech = stt.SpeechToText();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _textController.dispose();
    _scrollController.dispose();
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

  Future<void> _readLastMessage() async {
    if (_messages.isNotEmpty) {
      final lastMessage = _messages.last;
      final textToSpeak = "${lastMessage['sender']} disse: ${lastMessage['text']}";
      await _flutterTts.speak(textToSpeak);
    }
  }

  Future<void> _speakMessage(String message) async {
    await _flutterTts.speak(message);
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if (status == stt.SpeechToText.listeningStatus) {
          setState(() => _isListening = true);
        } else {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => debugPrint('Speech error: $error'),
    );
    if (!available) {
      _flutterTts.speak("O reconhecimento de voz não está disponível neste dispositivo.");
    }
  }

  void _sendMessage(String text) {
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({'sender': 'Você', 'text': text});
      });
      _textController.clear();
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _messages.add({'sender': 'Equipe de Apoio', 'text': 'Mensagem recebida, estamos verificando.'});
        });
        _readLastMessage();
      });
    }
  }

  Future<void> _startListening() async {
    await _speech.listen(
      localeId: 'pt_BR',
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
        });
        if (result.finalResult && _lastWords.isNotEmpty) {
          _sendMessage(_lastWords);
          _stopListening();
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
  }

  void _toggleInputMode() {
    setState(() {
      _isAudioInputMode = !_isAudioInputMode;
      _lastWords = '';
    });
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

  Color _getMessageBubbleColor(bool isMe) {
    if (_colorScheme == 'Alto Contraste') {
      return isMe ? Colors.black : Colors.white;
    }
    if (_colorScheme == 'Protanopia') {
      return isMe ? const Color.fromRGBO(85, 148, 179, 1) : Colors.grey[300]!;
    }
    if (_colorScheme == 'Deuteranopia') {
      return isMe ? const Color.fromRGBO(179, 148, 85, 1) : Colors.grey[300]!;
    }
    if (_colorScheme == 'Tritanopia') {
      return isMe ? const Color.fromRGBO(148, 85, 179, 1) : Colors.grey[300]!;
    }
    if (_colorScheme == 'Modo Escuro') {
      return isMe ? Colors.blueGrey[700]! : Colors.grey[800]!;
    }
    return isMe ? _getPrimaryColor() : Colors.grey[300]!;
  }

  Color _getMessageTextColor(bool isMe) {
    if (_colorScheme == 'Alto Contraste' || _colorScheme == 'Modo Escuro') {
      return isMe ? Colors.white : Colors.white;
    }
    return isMe ? Colors.white : Colors.black;
  }

  Color _getMicIconColor() {
    return _colorScheme == 'Modo Escuro' ? Colors.white : _getPrimaryColor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getScaffoldBackgroundColor(),
      appBar: AppBar(
        title: Text(
          'Chat da Equipe',
          style: TextStyle(color: Colors.white, fontSize: 20 * _fontScale),
        ),
        backgroundColor: _getPrimaryColor(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['sender'] == 'Você';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      _speakMessage(message['text']!);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: _getMessageBubbleColor(isMe),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Text(
                        message['text']!,
                        style: TextStyle(
                          color: _getMessageTextColor(isMe),
                          fontSize: 16 * _fontScale,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_isAudioInputMode)
                  Expanded(
                    child: GestureDetector(
                      onLongPressStart: (_) => _startListening(),
                      onLongPressEnd: (_) => _stopListening(),
                      child: FloatingActionButton.extended(
                        heroTag: 'micButtonChat',
                        backgroundColor: _getPrimaryColor(),
                        onPressed: () {},
                        label: Text(
                          _isListening ? "Ouvindo..." : "Pressione e segure para falar",
                          style: TextStyle(color: Colors.white, fontSize: 16 * _fontScale),
                        ),
                        icon: Icon(
                          _isListening ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "Digite sua mensagem...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      style: TextStyle(fontSize: 16 * _fontScale),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: 'toggleInputButton',
                  mini: true,
                  backgroundColor: _getPrimaryColor(),
                  onPressed: _toggleInputMode,
                  child: Icon(
                    _isAudioInputMode ? Icons.chat : Icons.mic,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}