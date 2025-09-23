import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tato/pages/settings_page.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/utils/app_theme.dart';

/// Página de emergência para o fluxo de usuário "deaf".
class DeafSosPage extends StatefulWidget {
  const DeafSosPage({super.key});

  @override
  State<DeafSosPage> createState() => _DeafSosPageState();
}

class _DeafSosPageState extends State<DeafSosPage> {
  // --- Serviços ---
  final SettingsService _settingsService = SettingsService();

  // --- Estado da UI ---
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  /// Carrega as configurações da página usando o serviço.
  Future<void> _initializePage() async {
    _fontScale = await _settingsService.loadFontScale();
    _colorScheme = await _settingsService.loadColorScheme();
    if (mounted) setState(() {});
  }

  /// Simula o envio de um alerta SOS.
  Future<void> _sendSosAlert() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    // Simula uma requisição de rede
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alerta de Socorro enviado com sucesso!',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(fontSize: 16 * _fontScale),
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackgroundColor(_colorScheme),
      appBar: AppBar(
        backgroundColor: AppTheme.getPrimaryColor(_colorScheme),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const SettingsPage(useGoogleFonts: true),
                    ),
                  )
                  .then(
                    (_) => _initializePage(),
                  ); // Recarrega as configurações ao voltar
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Em caso de emergência, pressione o botão',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    color: AppTheme.getMessageTextColor(_colorScheme, false),
                    fontSize: 20 * _fontScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 200,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendSosAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    elevation: 10,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 100 * _fontScale,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
