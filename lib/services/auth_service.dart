import 'package:firebase_auth/firebase_auth.dart';
import 'package:tato/services/user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  User? get currentUser => _auth.currentUser;

  // signup function
  Future<User?> signUpWithEmailPassword(
    String companyId,
    String name,
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _userService.createUserInDatabase(
          companyId,
          userCredential.user!,
          name,
        );
        return userCredential.user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print("Erro no Cadastro: $e");
      return null;
    }
  }

  // login function
  Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print("Erro no Login: $e");
      return null;
    }
  }

  // logout function
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      print("Erro no Logout: $e");
    }
  }
}
