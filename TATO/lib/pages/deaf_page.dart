import 'package:flutter/material.dart';

class DeafPage extends StatelessWidget {
  const DeafPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Versão para Surdos'),
        backgroundColor: const Color.fromRGBO(0, 69, 118, 1),
      ),
      backgroundColor: Colors.white,
      body: const Center(
        child: Text(
          'Conteúdo da Versão para Surdos',
          style: TextStyle(
            color: Color.fromRGBO(0, 69, 118, 1),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}