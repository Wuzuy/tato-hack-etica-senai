import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tato/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Criar usuário no banco de dados
  Future<void> createUserInDatabase(
    String companyId,
    User user,
    String name,
  ) async {
    final userModel = UserModel(
      uid: user.uid,
      name: name,
      email: user.email ?? '',
      role: 'funcionário',
    );

    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('users')
        .doc(user.uid)
        .set(userModel.toMap());
  }

  // Buscar dados do usuário
  Future<UserModel?> getUserData(String companyId, String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .doc(uid)
          .get();
      if (docSnapshot.exists) {
        return UserModel.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      print("Erro ao buscar dados do usuário: $e");
      return null;
    }
  }
}
