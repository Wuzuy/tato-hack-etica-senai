import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tato/services/auth_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Stream<QuerySnapshot> getMessagesStream() {
    return _firestore
        .collection('group_chat')
        .doc('main_channel')
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendMessage(String text) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || text.trim().isEmpty) return;

    final senderName = currentUser.displayName ?? currentUser.email ?? 'Usuário Anônimo';

    await _firestore.collection('group_chat').doc('main_channel').collection('messages').add({
      'text': text.trim(),
      'senderId': currentUser.uid,
      'senderName': senderName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}