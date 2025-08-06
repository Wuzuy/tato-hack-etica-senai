import 'package:flutter/material.dart';

class DeafChatPage extends StatefulWidget {
  const DeafChatPage({super.key});

  @override
  State<DeafChatPage> createState() => _DeafChatPageState();
}

class _DeafChatPageState extends State<DeafChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Representa uma mensagem de chat. O tipo 'isAudio' indica se é um áudio recebido.
  List<Map<String, dynamic>> _messages = [
    {'sender': 'Equipe de Apoio', 'text': 'Olá! Como posso ajudar você?', 'isAudio': false},
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({'sender': 'Você', 'text': text, 'isAudio': false});
      });
      _textController.clear();
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      // Simula o recebimento de uma mensagem de áudio após 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _messages.add({'sender': 'Equipe de Apoio', 'text': 'Áudio (A ser transcrito)', 'isAudio': true});
        });
      });
    }
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
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isMe ? const Color.fromRGBO(0, 69, 118, 1) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: message['isAudio']
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mic, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          message['text'],
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    )
                        : Text(
                      message['text'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
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
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color.fromRGBO(0, 69, 118, 1)),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}