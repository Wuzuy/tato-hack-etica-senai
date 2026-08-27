# TATO — Acessibilidade

Aplicativo de acessibilidade em **Flutter** para auxiliar pessoas com **deficiência visual e auditiva**. Desenvolvido durante o Hackathon Ética SENAI.

## Funcionalidades

- **Navegação assistida** — mapa com rotas acessíveis e orientação por voz
- **Chat assistido** — comunicação adaptada para pessoas com deficiência auditiva
- **Transcrição de voz** — conversão de fala em texto em tempo real
- **Botão SOS** — acionamento rápido de emergência
- **Assistente por comando de voz** — interpretação de comandos via Gemini AI
- **Modo empresa** — versão adaptada para estabelecimentos
- **Guia de uso** — tutoriais integrados de cada funcionalidade
- **Suporte a smartwatch** — integração com tela de smartwatch (Kotlin)

## Tecnologias

- Flutter / Dart
- Firebase (Auth, Firestore, Storage)
- Google Gemini API
- OpenRouteService API
- Kotlin (companion para smartwatch)

## Configuração

1. Clone o repositório:
   ```bash
   git clone https://github.com/Wuzuy/tato-hack-etica-senai.git
   cd tato-hack-etica-senai
   ```

2. Crie o arquivo `tokens.env` na raiz com as chaves de API:
   ```env
   GEMINI_API_KEY=sua_chave_gemini
   OPEN_ROUTE_SERVICE_API_KEY=sua_chave_ors
   ```

3. Configure o Firebase (`google-services.json` / `firebase_options.dart`) para o seu projeto.

4. Execute:
   ```bash
   flutter pub get
   flutter run
   ```

## Estrutura do projeto

```
lib/
├── models/       # Modelos de dados
├── pages/        # Telas (blind/, deaf/ e gerais)
├── services/     # Auth, chat, mapas, Gemini, comandos, etc.
├── smartwatch/   # Suporte a smartwatch
└── utils/        # Temas e utilitários
```

## Licença

Distribuído sob a licença MIT.