import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TATOStartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TATOStartScreen extends StatelessWidget {
  const TATOStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE40000), // Cor vermelha vibrante
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Círculo com o ícone do boneco e o texto "TATO"
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Esta é uma representação simplificada do círculo de texto.
                        // Para replicar o texto curvo, você precisaria de um widget de terceiros
                        // ou de um Canvas personalizado. Aqui usamos um CircleAvatar para
                        // o ícone do boneco e o texto "TATO" abaixo.
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 70,
                            color: Color(0xFFE40000),
                          ),
                        ),
                        // O texto curvo pode ser simulado com uma imagem
                        // ou um widget customizado, mas para simplificar,
                        // focamos no layout central.
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TATO',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Call-to-action
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: Text(
                'DIGA: "AVANÇAR" PARA COMEÇAR A EXPERIÊNCIA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Ícones na parte inferior
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BottomIcon(
                    imagePath: 'assets/images/user_icon.png', // Substitua pelo seu ícone
                    label: 'User Profile...',
                  ),
                  _BottomIcon(
                    imagePath: 'assets/images/app_icon.png', // Substitua pelo seu ícone
                    label: 'Aplicativo...',
                  ),
                  _BottomIcon(
                    imagePath: 'assets/images/chrome_icon.png', // Substitua pelo seu ícone
                    label: 'WEBC',
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

// Widget auxiliar para os ícones e legendas da parte inferior
class _BottomIcon extends StatelessWidget {
  final String imagePath;
  final String label;

  const _BottomIcon({
    required this.imagePath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          imagePath,
          width: 50,
          height: 50,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
