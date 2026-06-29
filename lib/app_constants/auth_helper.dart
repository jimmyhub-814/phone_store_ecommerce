import 'package:firebase_auth/firebase_auth.dart';

class AuthHelper {
  AuthHelper._();

  static String? get userId => FirebaseAuth.instance.currentUser?.uid;

  static User? get currentUser => FirebaseAuth.instance.currentUser;

  static bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;
}
