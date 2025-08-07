import 'package:flutter/material.dart';
import 'blind/blind_map_page.dart';
import 'deaf/deaf_map_page.dart'; // Importação corrigida para a nova página

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 69, 118, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: const Color.fromRGBO(0, 69, 118, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'images/tato_logo.png',
                height: 300,
              ),
              const SizedBox(height: 24), // Espaçamento reduzido
              const Text(
                'Qual versão do aplicativo mais se\naplica à sua necessidade?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold, // Adicionado negrito
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DeafMapPage(), // Navegação corrigida para DeafMapPage
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(16.0), // Espaçamento interno reduzido
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hearing,
                              size: 40, color: Color.fromRGBO(0, 69, 118, 1)),
                          SizedBox(width: 16), // Espaçamento reduzido
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sem Audição',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(0, 69, 118, 1),
                                ),
                              ),
                              SizedBox(height: 2), // Espaçamento reduzido
                              Text(
                                'Interface visual otimizada',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold, // Adicionado negrito
                                  color: Color.fromRGBO(0, 69, 118, 1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Espaçamento reduzido
              SizedBox(
                width: double.infinity,
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BlindMapPage(),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(16.0), // Espaçamento interno reduzido
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility,
                              size: 40, color: Color.fromRGBO(0, 69, 118, 1)),
                          SizedBox(width: 16), // Espaçamento reduzido
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Baixa Visão',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(0, 69, 118, 1),
                                ),
                              ),
                              SizedBox(height: 2), // Espaçamento reduzido
                              Text(
                                'Interface com áudio e vibração',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold, // Adicionado negrito
                                  color: Color.fromRGBO(0, 69, 118, 1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
