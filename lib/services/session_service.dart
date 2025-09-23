import 'package:firebase_auth/firebase_auth.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();

  factory SessionService() {
    return _instance;
  }

  SessionService._internal();

  User? currentUser;
  String? currentCompanyId;

  void startSession(User user, String companyId) {
    currentUser = user;
    currentCompanyId = companyId;
  }

  void endSession() {
    currentUser = null;
    currentCompanyId = null;
  }
}
