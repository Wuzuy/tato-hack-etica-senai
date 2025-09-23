import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tato/pages/login_page.dart';
import 'package:tato/services/auth_service.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/utils/app_theme.dart';

class SettingsPage extends StatefulWidget {
  final bool useGoogleFonts;

  const SettingsPage({super.key, this.useGoogleFonts = false});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();
  final AuthService _authService = AuthService();

  // Variáveis de estado da UI
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Carrega as configurações usando o serviço
  Future<void> _loadSettings() async {
    final loadedFontScale = await _settingsService.loadFontScale();
    final loadedColorScheme = await _settingsService.loadColorScheme();
    setState(() {
      _fontScale = loadedFontScale;
      _colorScheme = loadedColorScheme;
    });
  }

  // Métodos para salvar as configurações usando o serviço
  Future<void> _onFontScaleChanged(double value) async {
    setState(() => _fontScale = value);
    await _settingsService.saveFontScale(value);
  }

  Future<void> _onColorSchemeChanged(String? newScheme) async {
    if (newScheme == null) return;
    setState(() => _colorScheme = newScheme);
    await _settingsService.saveColorScheme(newScheme);
  }

  Future<void> _signOut() async {
    await _authService.signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  TextStyle _getTextStyle(
    double fontSize, {
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final style = TextStyle(
      fontSize: fontSize * _fontScale,
      color: AppTheme.getMessageTextColor(
        _colorScheme,
        false,
      ), // Usando a cor de texto padrão
      fontWeight: fontWeight,
    );

    // Aplica a fonte Poppins condicionalmente
    if (widget.useGoogleFonts) {
      return GoogleFonts.poppins(textStyle: style);
    }
    return style;
  }

  @override
  Widget build(BuildContext context) {
    // A construção da UI agora usa os métodos do AppTheme e o _getTextStyle
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackgroundColor(_colorScheme),
      appBar: AppBar(
        title: Text(
          'Configurações',
          style: _getTextStyle(
            20,
            fontWeight: FontWeight.bold,
          ).copyWith(color: Colors.white),
        ),
        backgroundColor: AppTheme.getPrimaryColor(_colorScheme),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Tamanho da Fonte:',
                style: _getTextStyle(18, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _fontScale,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                label: _fontScale.toStringAsFixed(1),
                onChanged: _onFontScaleChanged, // Chama o novo method
                activeColor: AppTheme.getPrimaryColor(_colorScheme),
              ),
              const SizedBox(height: 20),
              Text(
                'Esquema de Cores:',
                style: _getTextStyle(18, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: _colorScheme,
                icon: Icon(
                  Icons.arrow_downward,
                  color: AppTheme.getMessageTextColor(_colorScheme, false),
                ),
                dropdownColor: AppTheme.getScaffoldBackgroundColor(
                  _colorScheme,
                ),
                style: _getTextStyle(16),
                underline: Container(
                  height: 2,
                  color: AppTheme.getPrimaryColor(_colorScheme),
                ),
                onChanged: _onColorSchemeChanged, // Chama o novo method
                items:
                    <String>[
                      'Padrão',
                      'Alto Contraste',
                      'Protanopia',
                      'Deuteranopia',
                      'Tritanopia',
                      'Modo Escuro',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: _getTextStyle(16)),
                      );
                    }).toList(),
              ),
              const Spacer(),

              Center(
                child: ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    'Sair da Conta',
                    style: _getTextStyle(16).copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
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
