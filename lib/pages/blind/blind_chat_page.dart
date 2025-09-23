import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tato/models/command_result.dart';
import 'package:tato/services/accessibility_service.dart';
import 'package:tato/services/auth_service.dart';
import 'package:tato/services/chat_service.dart';
import 'package:tato/services/command_interpreter_service.dart';
import 'package:tato/services/gemini_service.dart';
import 'package:tato/services/global_command_service.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/utils/app_theme.dart';

/// Página de chat em grupo com comandos de voz inteligentes.
class BlindChatPage extends StatefulWidget {
  const BlindChatPage({super.key});

  @override
  State<BlindChatPage> createState() => _BlindChatPageState();
}

class _BlindChatPageState extends State<BlindChatPage> {
  // --- Serviços ---
  final SettingsService _settingsService = SettingsService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  final GeminiService _geminiService = GeminiService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  late final CommandInterpreterService _commandInterpreterService;
  late final GlobalCommandService _globalCommandService;

  // --- Estado da UI e Controladores ---
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  bool _isAudioInputMode = true;
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _commandInterpreterService = CommandInterpreterService(_geminiService);
    _globalCommandService = GlobalCommandService(
      _commandInterpreterService,
      _accessibilityService,
    );
    _initializePage();
  }

  @override
  void dispose() {
    _accessibilityService.stopSpeaking();
    _accessibilityService.stopListening();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Carrega as configurações e inicializa os serviços.
  Future<void> _initializePage() async {
    _fontScale = await _settingsService.loadFontScale();
    _colorScheme = await _settingsService.loadColorScheme();
    await _accessibilityService.initialize(
      onListeningStateChanged: (isListening) {
        if (mounted) setState(() => _isListening = isListening);
      },
    );
    if (mounted) setState(() {});
  }

  /// Inicia o processo de escuta de voz.
  void _startListening() {
    if (_isActionInProgress || _isListening) return;

    try {
      setState(() => _isActionInProgress = true);
      _accessibilityService.startListening(
        onResult: (recognizedWords) {
          _handleVoiceCommand(recognizedWords);
        },
      );
    } finally {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isActionInProgress = false);
      });
    }
  }

  /// Para o processo de escuta de voz.
  void _stopListening() {
    _accessibilityService.stopListening();
  }

  /// Processa o texto falado, decidindo se é um comando ou uma mensagem de chat.
  Future<void> _handleVoiceCommand(String text) async {
    final CommandResult result = await _commandInterpreterService
        .interpretCommand(text);

    final bool wasHandledGlobally = await _globalCommandService.executeCommand(
      text,
      result,
    );

    if (!wasHandledGlobally) {
      // Se não for um comando global, assume que é uma mensagem para o chat.
      // A IA é inteligente para classificar falas comuns como 'send_chat_message'.
      await _chatService.sendMessage(text);
    }
  }

  void _toggleInputMode() =>
      setState(() => _isAudioInputMode = !_isAudioInputMode);

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
          style: TextStyle(color: Colors.white, fontSize: 20 * _fontScale),
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
                      final senderName = messageData['senderName'] ?? 'Anônimo';

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => _accessibilityService.speak(
                            "${isMe ? 'Você' : senderName} disse: ${messageData['text']}",
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.getMessageBubbleColor(
                                _colorScheme,
                                isMe,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(
                                    senderName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12 * _fontScale,
                                      color: AppTheme.getMessageTextColor(
                                        _colorScheme,
                                        false,
                                      ),
                                    ),
                                  ),
                                Text(
                                  messageData['text'] ?? '',
                                  style: TextStyle(
                                    color: AppTheme.getMessageTextColor(
                                      _colorScheme,
                                      isMe,
                                    ),
                                    fontSize: 16 * _fontScale,
                                  ),
                                ),
                              ],
                            ),
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
                    child: _isAudioInputMode
                        ? GestureDetector(
                            onLongPressStart:
                                _isActionInProgress || _isListening
                                ? null
                                : (_) => _startListening(),
                            onLongPressEnd: (_) => _stopListening(),
                            child: FloatingActionButton.extended(
                              heroTag: 'micButtonChat',
                              backgroundColor: AppTheme.getPrimaryColor(
                                _colorScheme,
                              ),
                              onPressed: () {},
                              label: Text(
                                _isListening
                                    ? "Ouvindo..."
                                    : "Pressione para falar",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16 * _fontScale,
                                ),
                              ),
                              icon: Icon(
                                _isListening ? Icons.mic_off : Icons.mic,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : TextField(
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
                            onSubmitted: (text) =>
                                _chatService.sendMessage(text),
                          ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    heroTag: 'toggleInputButton',
                    mini: true,
                    backgroundColor: AppTheme.getPrimaryColor(_colorScheme),
                    onPressed: _toggleInputMode,
                    child: Icon(
                      _isAudioInputMode
                          ? Icons.chat_bubble_outline
                          : Icons.mic_none,
                      color: Colors.white,
                    ),
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
