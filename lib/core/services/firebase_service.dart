import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static Future<void> updateDisplayName(String name) async {
    await auth.currentUser?.updateDisplayName(name);
  }

  // Current logged in user
  static User? get currentUser => auth.currentUser;

  // Auth state stream
  static Stream<User?> get authStateChanges => auth.authStateChanges();

  // Sign in
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  static Future<void> signOut() async {
    await auth.signOut();
  }
}
