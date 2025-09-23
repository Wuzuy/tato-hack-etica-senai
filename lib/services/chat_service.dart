import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tato/services/user_service.dart';
import 'package:tato/services/session_service.dart'; // 1. Importa o SessionService

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  final SessionService _sessionService =
      SessionService(); // 2. Cria uma instância dele

  /// Retorna um "fluxo" de mensagens em tempo real do canal da empresa logada.
  Stream<QuerySnapshot> getMessagesStream() {
    // 3. Pega o companyId da sessão atual
    final companyId = _sessionService.currentCompanyId;

    // Se não houver empresa logada, retorna um fluxo vazio para evitar erros.
    if (companyId == null) {
      return const Stream.empty();
    }

    // 4. Constrói o caminho dinâmico para o chat da empresa
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chats')
        .doc('main_channel') // Assumindo que cada empresa tem um 'main_channel'
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Envia uma nova mensagem para o chat em grupo da empresa logada.
  Future<void> sendMessage(String text) async {
    // 5. Pega o companyId e o usuário da sessão atual
    final companyId = _sessionService.currentCompanyId;
    final currentUser = _sessionService.currentUser;

    if (currentUser == null || companyId == null || text.trim().isEmpty) return;

    // Busca os dados do usuário para pegar o nome real
    final userData = await _userService.getUserData(companyId, currentUser.uid);
    final senderName = userData?.name ?? currentUser.email ?? 'Anônimo';

    // 6. Constrói o caminho dinâmico para escrever a mensagem
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chats')
        .doc('main_channel')
        .collection('messages')
        .add({
          'text': text.trim(),
          'senderId': currentUser.uid,
          'senderName': senderName,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }
}
