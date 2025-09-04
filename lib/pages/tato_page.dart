import 'package:flutter/material.dart';
import 'package:tato/login_page.dart';

class TATOPage extends StatelessWidget {
  const TATOPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 69, 118, 1),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Você deve ter a imagem 'tato_logo.png' em 'assets/images/'
              // e ter a pasta 'assets/images' declarada no pubspec.yaml.
              Image.asset(
                'images/tato_logo.png',
                height: 300,
                width: 300,
              ),
              const SizedBox(height: 100),
              ElevatedButton(
                onPressed: () {
                  // Navega para a LoginPage em vez de ir direto para a SecondPage.
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'INICIAR',
                  style: TextStyle(
                    color: Color.fromRGBO(0, 69, 118, 1),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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
