import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _fontScaleKey = 'fontScale';
const String _colorSchemeKey = 'colorScheme';

class DeafChatPage extends StatefulWidget {
  const DeafChatPage({super.key});

  @override
  State<DeafChatPage> createState() => _DeafChatPageState();
}

class _DeafChatPageState extends State<DeafChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  // Lista de mensagens do chat. Agora contém apenas texto.
  List<Map<String, String>> _messages = [
    {'sender': 'Equipe de Apoio', 'text': 'Olá! Como posso ajudar você?'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
      _colorScheme = prefs.getString(_colorSchemeKey) ?? 'Padrão';
    });
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
          _messages.add({'sender': 'Equipe de Apoio', 'text': 'Resposta simulada'});
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      });
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

  Color _getMessageBubbleColor(bool isMe) {
    if (isMe) {
      return _getPrimaryColor();
    }
    return _colorScheme == 'Modo Escuro' ? Colors.grey[700]! : Colors.grey[300]!;
  }

  Color _getMessageTextColor(bool isMe) {
    if (isMe) {
      return Colors.white;
    }
    return _colorScheme == 'Modo Escuro' ? Colors.white : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getScaffoldBackgroundColor(),
      appBar: AppBar(
        title: Text(
          'Chat da Equipe',
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 20 * _fontScale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: _getPrimaryColor(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
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
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: _getMessageBubbleColor(isMe),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Text(
                        message['text']!,
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
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
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "Digite sua mensagem...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        hintStyle: TextStyle(color: _getTextColor().withOpacity(0.5)),
                      ),
                      style: TextStyle(color: _getTextColor()),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: _getPrimaryColor()),
                    onPressed: () => _sendMessage(_textController.text),
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
