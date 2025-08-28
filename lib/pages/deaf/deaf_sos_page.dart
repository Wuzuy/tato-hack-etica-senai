import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Importe para usar GoogleFonts
import 'package:shared_preferences/shared_preferences.dart';

import 'deaf_settings_page.dart';

const String _fontScaleKey = 'fontScale';
const String _colorSchemeKey = 'colorScheme';

class DeafSosPage extends StatefulWidget {
  const DeafSosPage({super.key});

  @override
  State<DeafSosPage> createState() => _DeafSosPageState();
}

class _DeafSosPageState extends State<DeafSosPage> {
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
        _colorScheme = prefs.getString(_colorSchemeKey) ?? 'Padrão';
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

  Future<void> _sendSosAlert() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Simula uma requisição de rede
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alerta de Socorro enviado com sucesso!',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontSize: 16 * _fontScale,
              ),
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
      backgroundColor: _getScaffoldBackgroundColor(),
      appBar: AppBar(
        backgroundColor: _getPrimaryColor(),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DeafSettingsPage(),
                ),
              );
              _loadSettings();
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
                    color: _getTextColor(),
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
                  onPressed: _isLoading ? null : () => _sendSosAlert(),
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
