import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tato/services/auth_service.dart';
import 'package:tato/services/chat_service.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/utils/app_theme.dart';

/// Página de chat em grupo para o fluxo de usuário "deaf".
class DeafChatPage extends StatefulWidget {
  const DeafChatPage({super.key});

  @override
  State<DeafChatPage> createState() => _DeafChatPageState();
}

class _DeafChatPageState extends State<DeafChatPage> {
  // --- Serviços ---
  final SettingsService _settingsService = SettingsService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  // --- Controladores e Estado da UI ---
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';
  // bool _isLoading = false;
  // A lista de mensagens local foi removida. Os dados agora vêm do Firebase.

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

  /// Carrega as configurações da página.
  Future<void> _initializePage() async {
    _fontScale = await _settingsService.loadFontScale();
    _colorScheme = await _settingsService.loadColorScheme();
    if (mounted) setState(() {});
  }

  /// Envia uma mensagem para o chat em grupo no Firestore.
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // A UI agora será atualizada automaticamente pelo StreamBuilder.
    // Nós apenas limpamos o campo de texto.
    _textController.clear();

    try {
      await _chatService.sendMessage(text);
      _scrollToBottom();
    } catch (e) {
      print("Erro ao enviar mensagem: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível enviar a mensagem.")),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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
          style: GoogleFonts.poppins(/* ... estilo do título ... */),
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
              // Usa um StreamBuilder para ouvir o chat em tempo real
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getMessagesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.getPrimaryColor(_colorScheme),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("Seja o primeiro a enviar uma mensagem!"),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Erro ao carregar o chat."),
                    );
                  }

                  // Garante que o scroll vá para o final quando novas mensagens chegarem
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageData =
                          messages[index].data() as Map<String, dynamic>;
                      final isMe =
                          messageData['senderId'] ==
                          _authService.currentUser?.uid;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 5.0,
                            horizontal: 10.0,
                          ),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: AppTheme.getMessageBubbleColor(
                              _colorScheme,
                              isMe,
                            ),
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              // Mostra o nome do remetente (se não for você)
                              if (!isMe)
                                Text(
                                  messageData['senderName'] ?? 'Anônimo',
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12 * _fontScale,
                                      color: AppTheme.getPrimaryColor(
                                        _colorScheme,
                                      ),
                                    ),
                                  ),
                                ),
                              Text(
                                messageData['text'] ?? '',
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(
                                    color: AppTheme.getMessageTextColor(
                                      _colorScheme,
                                      isMe,
                                    ),
                                    fontSize: 16 * _fontScale,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
                      ),
                      style: TextStyle(
                        color: AppTheme.getMessageTextColor(
                          _colorScheme,
                          false,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: AppTheme.getPrimaryColor(_colorScheme),
                    ),
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
