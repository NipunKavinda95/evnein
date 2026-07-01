import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../core/services/firebase_service.dart';

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final firebaseUser = FirebaseService.currentUser;
  if (firebaseUser == null) return null;

  try {
    // Wait for token to be ready
    await firebaseUser.getIdToken();

    // Query by email to avoid UID mismatch issues
    final snapshot = await FirebaseService.firestore.collection('users').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['email'] == firebaseUser.email) {
        return UserModel.fromMap(data);
      }
    }
  } catch (e) {
    // ignore
  }

  // Fallback — use email prefix
  return UserModel(
    uid: firebaseUser.uid,
    name: firebaseUser.email?.split('@')[0] ?? 'User',
    email: firebaseUser.email ?? '',
    role: 'admin',
    createdAt: DateTime.now(),
  );
});
