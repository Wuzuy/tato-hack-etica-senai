import 'package:flutter/material.dart';
import 'package:tato/pages/login_page.dart';
import 'package:tato/services/auth_service.dart';
import 'package:tato/pages/second_page.dart';

/// Tela de boas-vindas que direciona o usuário para o login ou para a home.
class TATOPage extends StatefulWidget {
  const TATOPage({super.key});

  @override
  State<TATOPage> createState() => _TATOPageState();
}

class _TATOPageState extends State<TATOPage> {
  // 1. Instanciamos o serviço de autenticação para usá-lo.
  final AuthService _authService = AuthService();

  /// 2. Esta função verifica se há um usuário logado e navega para a tela correta.
  void _checkAuthAndNavigate() {
    final currentUser = _authService.currentUser;

    if (currentUser != null) {
      // Se há um usuário, vai direto para a página principal, substituindo a atual.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SecondPage()),
      );
    } else {
      // Se não há usuário, vai para a página de login.
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }

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
              Image.asset('images/tato_logo.png', height: 300, width: 300),
              const SizedBox(height: 100),
              ElevatedButton(
                onPressed: _checkAuthAndNavigate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 80,
                    vertical: 20,
                  ),
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
