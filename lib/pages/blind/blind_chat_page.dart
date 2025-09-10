import 'package:flutter/material.dart';
import 'package:tato/services/accessibility_service.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/utils/app_theme.dart';

/// Uma página que funciona como um transcritor de voz, exibindo o que o usuário fala.
class BlindChatPage extends StatefulWidget {
  const BlindChatPage({super.key});

  @override
  State<BlindChatPage> createState() => _BlindChatPageState();
}

class _BlindChatPageState extends State<BlindChatPage> {
  // --- Serviços Necessários ---
  final SettingsService _settingsService = SettingsService();
  final AccessibilityService _accessibilityService = AccessibilityService();

  // --- Controladores e Estado da UI ---
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  bool _isAudioInputMode = true;
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  List<Map<String, String>> _messages = [
    {
      'sender': 'System',
      'text': 'Pressione o botão para começar a transcrever sua voz.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializePage();
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

    _readLastMessage();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _accessibilityService.stopSpeaking();
    _accessibilityService.stopListening();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Lê a última mensagem/transcrição em voz alta.
  Future<void> _readLastMessage() async {
    if (_messages.isNotEmpty) {
      final lastMessage = _messages.last;
      await _accessibilityService.speak(lastMessage['text']!);
    }
  }

  /// Adiciona o texto do usuário (falado ou digitado) à lista.
  void _addMyMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'Você', 'text': text});
    });
    _textController.clear();
    _scrollToBottom();
    _readLastMessage(); // Lê a transcrição em voz alta para confirmação
  }

  /// Inicia o processo de escuta de voz.
  void _startListening() {
    _accessibilityService.startListening(
      onResult: (recognizedWords) {
        _addMyMessage(recognizedWords);
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
          'Minhas Transcrições',
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
                  final isSystemMessage = message['sender'] == 'System';

                  return Align(
                    alignment: Alignment.centerLeft,
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
                          color: isSystemMessage
                              ? Colors.transparent
                              : AppTheme.getMessageBubbleColor(
                                  _colorScheme,
                                  false,
                                ),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Text(
                          message['text']!,
                          style: TextStyle(
                            color: AppTheme.getMessageTextColor(
                              _colorScheme,
                              false,
                            ),
                            fontStyle: isSystemMessage
                                ? FontStyle.italic
                                : FontStyle.normal,
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
                            onLongPressStart: (_) => _startListening(),
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
                                    : "Pressione para transcrever",
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
                              hintText: "Digite para transcrever...",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                            onSubmitted: (text) => _addMyMessage(text),
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
