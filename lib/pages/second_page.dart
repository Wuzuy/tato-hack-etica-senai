import 'package:flutter/material.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/utils/app_theme.dart';

// Importa as páginas de destino
import 'blind/blind_map_page.dart';
import 'deaf/deaf_map_page.dart';

/// Página de seleção de modo de uso do aplicativo (Blind/Deaf).
class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  // --- Serviços ---
  final SettingsService _settingsService = SettingsService();

  // --- Estado da UI ---
  // A página não precisa mais de _fontScale ou _colorScheme,
  // pois o tema será gerenciado em cada página de destino.
  // No entanto, se você quisesse que esta página também mudasse de cor,
  // manteríamos as variáveis e o _initializePage().

  // Helper para construir os cartões de seleção
  Widget _buildSelectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    // Usamos uma cor fixa, pois esta tela é parte do fluxo de entrada
    const Color primaryColor = Color.fromRGBO(0, 69, 118, 1);

    return SizedBox(
      width: double.infinity,
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: primaryColor),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color.fromRGBO(0, 69, 118, 1);

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        // O botão de voltar é removido automaticamente se não houver tela anterior na pilha.
        // Para forçar a remoção, podemos fazer isso:
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'images/tato_logo.png', // Caminho corrigido
                height: 300,
              ),
              const SizedBox(height: 24),
              const Text(
                'Qual versão do aplicativo mais se aplica à sua necessidade?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildSelectionCard(
                context: context,
                icon: Icons.hearing,
                title: 'Sem Audição',
                subtitle: 'Interface visual otimizada',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DeafMapPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSelectionCard(
                context: context,
                icon: Icons.visibility,
                title: 'Baixa Visão',
                subtitle: 'Interface com áudio e vibração',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BlindMapPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
