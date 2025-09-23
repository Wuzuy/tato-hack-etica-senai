import 'package:flutter/material.dart';
import 'package:tato/services/auth_service.dart';
import 'package:tato/services/session_service.dart';
import 'package:tato/services/user_service.dart';
import 'package:tato/services/settings_service.dart';
import 'package:tato/utils/app_theme.dart';
import 'second_page.dart';

/// Tela de login e cadastro para o aplicativo, com suporte a múltiplas empresas.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // --- Serviços ---
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final SettingsService _settingsService = SettingsService();
  final SessionService _sessionService = SessionService();

  // --- Controladores e Estado da UI ---
  final TextEditingController _companyIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;
  String _colorScheme = 'Padrão';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  @override
  void dispose() {
    _companyIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Carrega as configurações de tema salvas.
  Future<void> _loadTheme() async {
    _colorScheme = await _settingsService.loadColorScheme();
    if (mounted) setState(() {});
  }

  /// Lida com o envio do formulário para login ou cadastro multi-empresa.
  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final companyId = _companyIdController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (companyId.isEmpty) {
      _showAuthFailedMessage("Por favor, insira o Código da Empresa.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (_isLoginMode) {
        final userCredential = await _authService.signInWithEmailPassword(
          email,
          password,
        );
        if (userCredential?.user != null) {
          final userData = await _userService.getUserData(
            companyId,
            userCredential!.user!.uid,
          );
          if (userData != null && mounted) {
            _sessionService.startSession(userCredential.user!, companyId);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SecondPage()),
            );
          } else {
            _showAuthFailedMessage("Usuário não encontrado nesta empresa.");
            await _authService.signOut();
          }
        } else {
          _showAuthFailedMessage(
            "Falha no login. Verifique seu e-mail e senha.",
          );
        }
      } else {
        final user = await _authService.signUpWithEmailPassword(
          companyId,
          name,
          email,
          password,
        );
        if (user != null && mounted) {
          _sessionService.startSession(user, companyId);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SecondPage()),
          );
        } else {
          _showAuthFailedMessage(
            "Falha no cadastro. O e-mail pode já estar em uso.",
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Exibe uma mensagem de erro na parte inferior da tela.
  void _showAuthFailedMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.getPrimaryColor(_colorScheme);
    final buttonTextColor = _colorScheme == 'Modo Escuro'
        ? Colors.white
        : primaryColor;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text(
          _isLoginMode ? 'Login' : 'Cadastro',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person, size: 100, color: Colors.white),
                const SizedBox(height: 30),

                // Campo para Código da Empresa
                TextField(
                  controller: _companyIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Código da Empresa',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white54),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (!_isLoginMode) // Campo de Nome (apenas no cadastro)
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white54),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                if (!_isLoginMode) const SizedBox(height: 20),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white54),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white54),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: primaryColor)
                      : Text(
                          _isLoginMode ? 'ENTRAR' : 'CADASTRAR',
                          style: TextStyle(
                            color: buttonTextColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                TextButton(
                  onPressed: () {
                    if (_isLoading) return;
                    setState(() => _isLoginMode = !_isLoginMode);
                  },
                  child: Text(
                    _isLoginMode ? 'Criar uma conta' : 'Já tenho uma conta',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
