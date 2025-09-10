import 'package:flutter/material.dart';
import 'package:tato/models/command_result.dart';
import 'package:tato/services/accessibility_service.dart';
import 'package:tato/services/command_interpreter_service.dart';
import 'package:tato/services/gemini_service.dart';
import 'package:tato/services/global_command_service.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/utils/app_theme.dart';

// import 'package:tato/pages/settings_page.dart';

/// A página de chat para interação por voz e texto com o assistente de IA.
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
  late final CommandInterpreterService _commandInterpreterService;
  late final GlobalCommandService _globalCommandService;

  // --- Controladores e Estado da UI ---
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  bool _isAudioInputMode = true;
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';
  bool _isLoading = false;
  List<Map<String, String>> _messages = [
    {
      'sender': 'Gemini',
      'text': 'Olá! Sou o assistente do Tato. Como posso ajudar?',
    },
  ];

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

  /// Carrega as configurações e inicializa os serviços necessários para a página.
  Future<void> _initializePage() async {
    _fontScale = await _settingsService.loadFontScale();
    _colorScheme = await _settingsService.loadColorScheme();

    await _accessibilityService.initialize(
      onListeningStateChanged: (isListening) {
        if (mounted) setState(() => _isListening = isListening);
      },
    );

    _readLastMessage();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _accessibilityService.stopSpeaking();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Utiliza o serviço de acessibilidade para ler a última mensagem da conversa.
  Future<void> _readLastMessage() async {
    if (_messages.isNotEmpty) {
      final lastMessage = _messages.last;
      final textToSpeak =
          "${lastMessage['sender']} disse: ${lastMessage['text']}";
      await _accessibilityService.speak(textToSpeak);
    }
  }

  /// Processa o texto de um comando de voz, o interpreta e executa a ação.
  Future<void> _handleVoiceCommand(String text) async {
    setState(() {
      _messages.add({'sender': 'Você', 'text': text});
      _isLoading = true;
    });
    _scrollToBottom();

    final CommandResult result = await _commandInterpreterService
        .interpretCommand(text);
    final bool wasHandledGlobally = await _globalCommandService.executeCommand(
      text,
      result,
    );

    if (!wasHandledGlobally) {
      switch (result.intent) {
        case 'send_chat_message':
          await _sendMessage(result.parameters['message'] ?? text);
          break;
        default:
          await _sendMessage(text);
          break;
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// Envia uma mensagem de texto para a IA e atualiza o chat.
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (_messages.last['sender'] != 'Você') {
      setState(() => _messages.add({'sender': 'Você', 'text': text}));
    }

    _textController.clear();
    setState(() => _isLoading = true);

    _scrollToBottom();
    setState(() => _messages.add({'sender': 'Gemini', 'text': '...'}));
    _scrollToBottom();

    final geminiResponse = await _geminiService.sendMessage(text);

    setState(() {
      _messages.removeLast();
      _messages.add({'sender': 'Gemini', 'text': geminiResponse});
    });

    _scrollToBottom();
    _readLastMessage();
  }

  // /// Adiciona uma resposta do bot na tela sem consultar a IA.
  // void _addBotMessage(String text) {
  //   setState(() {
  //     _messages.add({'sender': 'Gemini', 'text': text});
  //   });
  //   _scrollToBottom();
  //   _readLastMessage();
  // }

  /// Inicia o processo de escuta de voz.
  void _startListening() {
    _accessibilityService.startListening(
      onResult: (recognizedWords) {
        _handleVoiceCommand(recognizedWords);
      },
    );
  }

  /// Para o processo de escuta de voz.
  void _stopListening() {
    _accessibilityService.stopListening();
  }

  void _toggleInputMode() =>
      setState(() => _isAudioInputMode = !_isAudioInputMode);

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
          'Assistente Tato',
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
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isMe = message['sender'] == 'Você';
                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () =>
                          _accessibilityService.speak(message['text']!),
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
                        child: Text(
                          message['text']!,
                          style: TextStyle(
                            color: AppTheme.getMessageTextColor(
                              _colorScheme,
                              isMe,
                            ),
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
                    child: _isAudioInputMode
                        ? GestureDetector(
                            onLongPressStart: _isLoading
                                ? null
                                : (_) => _startListening(),
                            onLongPressEnd: _isListening
                                ? (_) => _stopListening()
                                : null,
                            child: FloatingActionButton.extended(
                              heroTag: 'micButtonChat',
                              backgroundColor: AppTheme.getPrimaryColor(
                                _colorScheme,
                              ),
                              onPressed: () {},
                              label: Text(
                                _isLoading
                                    ? "Processando..."
                                    : (_isListening
                                          ? "Ouvindo..."
                                          : "Pressione para falar"),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16 * _fontScale,
                                ),
                              ),
                              icon: Icon(
                                _isLoading ? Icons.sync : Icons.mic,
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
                            onSubmitted: _isLoading
                                ? null
                                : (text) => _sendMessage(text),
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
