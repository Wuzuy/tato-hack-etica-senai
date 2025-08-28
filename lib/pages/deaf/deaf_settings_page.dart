import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

const String _fontScaleKey = 'fontScale';
const String _colorSchemeKey = 'colorScheme';

class DeafSettingsPage extends StatefulWidget {
  const DeafSettingsPage({super.key});

  @override
  State<DeafSettingsPage> createState() => _DeafSettingsPageState();
}

class _DeafSettingsPageState extends State<DeafSettingsPage> {
  double _fontScale = 1.0;
  String _colorScheme = 'Padrão';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
      _colorScheme = prefs.getString(_colorSchemeKey) ?? 'Padrão';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, _fontScale);
    await prefs.setString(_colorSchemeKey, _colorScheme);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getScaffoldBackgroundColor(),
      appBar: AppBar(
        title: Text(
          'Configurações',
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Tamanho da Fonte:',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 18 * _fontScale,
                    color: _getTextColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Slider(
                value: _fontScale,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                label: _fontScale.toStringAsFixed(1),
                onChanged: (double value) {
                  setState(() {
                    _fontScale = value;
                  });
                  _saveSettings();
                },
                activeColor: _getPrimaryColor(),
              ),
              const SizedBox(height: 20),
              Text(
                'Esquema de Cores:',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 18 * _fontScale,
                    color: _getTextColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DropdownButton<String>(
                value: _colorScheme,
                icon: Icon(Icons.arrow_downward, color: _getTextColor()),
                dropdownColor: _getScaffoldBackgroundColor(),
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    color: _getTextColor(),
                    fontSize: 16 * _fontScale,
                  ),
                ),
                underline: Container(
                  height: 2,
                  color: _getPrimaryColor(),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _colorScheme = newValue!;
                  });
                  _saveSettings();
                },
                items: <String>[
                  'Padrão',
                  'Alto Contraste',
                  'Protanopia',
                  'Deuteranopia',
                  'Tritanopia',
                  'Modo Escuro'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: GoogleFonts.poppins(textStyle: TextStyle(color: _getTextColor()))),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
