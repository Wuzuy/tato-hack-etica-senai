import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tato/services/gemini_service.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/utils/app_theme.dart';

class DeafChatPage extends StatefulWidget {
  const DeafChatPage({super.key});

  @override
  State<DeafChatPage> createState() => _DeafChatPageState();
}

class _DeafChatPageState extends State<DeafChatPage> {
  // --- Serviços ---
  final SettingsService _settingsService = SettingsService();
  final GeminiService _geminiService = GeminiService();

  // --- Controladores e Estado da UI ---
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';
  bool _isLoading = false;
  List<Map<String, String>> _messages = [
    {'sender': 'Equipe de Apoio', 'text': 'Olá! Como posso ajudar você?'},
  ];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Carrega as configurações usando o serviço.
  Future<void> _initializePage() async {
    _fontScale = await _settingsService.loadFontScale();
    _colorScheme = await _settingsService.loadColorScheme();
    if (mounted) setState(() {});
  }

  /// Envia uma mensagem e obtém uma resposta real da IA.
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'sender': 'Você', 'text': text});
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Adiciona um feedback de "digitando..."
    setState(() => _messages.add({'sender': 'Equipe de Apoio', 'text': '...'}));
    _scrollToBottom();

    // Chama o GeminiService para uma resposta real
    final geminiResponse = await _geminiService.sendMessage(text);

    setState(() {
      _messages.removeLast(); // Remove o "..."
      _messages.add({'sender': 'Equipe de Apoio', 'text': geminiResponse});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackgroundColor(_colorScheme),
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
        backgroundColor: AppTheme.getPrimaryColor(_colorScheme),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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
                        color: AppTheme.getMessageBubbleColor(_colorScheme, isMe),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Text(
                        message['text']!,
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            color: AppTheme.getMessageTextColor(_colorScheme, isMe),
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
                        hintStyle: TextStyle(
                            color: AppTheme.getMessageTextColor(_colorScheme, false).withOpacity(0.6)),
                      ),
                      style: TextStyle(
                          color: AppTheme.getMessageTextColor(_colorScheme, false)),
                      onSubmitted: _isLoading ? null : _sendMessage,
                    ),
                  ),
                  IconButton(
                    icon: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Icon(Icons.send, color: AppTheme.getPrimaryColor(_colorScheme)),
                    onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
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