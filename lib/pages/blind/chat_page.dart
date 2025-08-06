import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isAudioInputMode = true;

  List<Map<String, String>> _messages = [
    {'sender': 'Equipe de Apoio', 'text': 'Olá! Como posso ajudar você?'},
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _readLastMessage();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  // Novo método para ler uma mensagem específica
  Future<void> _speakMessage(String message) async {
    await _flutterTts.speak(message);
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

  void _toggleInputMode() {
    setState(() {
      _isAudioInputMode = !_isAudioInputMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat da Equipe', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(0, 69, 118, 1),
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
                        color: isMe ? const Color.fromRGBO(0, 69, 118, 1) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Text(
                        message['text']!,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
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
                    child: FloatingActionButton.extended(
                      heroTag: 'micButtonChat',
                      backgroundColor: const Color.fromRGBO(0, 69, 118, 1),
                      onPressed: () {
                        print("Botão de microfone pressionado para entrada de voz.");
                      },
                      label: const Text(
                        "Pressione para falar",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      icon: const Icon(Icons.mic, color: Colors.white),
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
                      onSubmitted: _sendMessage,
                    ),
                  ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: 'toggleInputButton',
                  mini: true,
                  backgroundColor: const Color.fromRGBO(0, 69, 118, 1),
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