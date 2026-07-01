import '../models/user_model.dart';
import '../../core/services/firebase_service.dart';

class UserRepository {
  static final _collection = FirebaseService.firestore.collection('users');

  static Future<void> saveUser(UserModel user) async {
    await _collection.doc(user.uid).set(user.toMap());
  }

  static Future<UserModel?> getUser(String uid) async {
    try {
      // First try by document ID
      final doc = await _collection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }

      // Fallback — query by uid field
      final query =
          await _collection.where('uid', isEqualTo: uid).limit(1).get();
      if (query.docs.isNotEmpty) {
        return UserModel.fromMap(query.docs.first.data());
      }

      // Last fallback — query by email
      final email = FirebaseService.currentUser?.email;
      if (email != null) {
        final emailQuery =
            await _collection.where('email', isEqualTo: email).limit(1).get();
        if (emailQuery.docs.isNotEmpty) {
          return UserModel.fromMap(emailQuery.docs.first.data());
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Stream<UserModel?> getUserStream(String uid) {
    return _collection.doc(uid).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromMap(doc.data()!);
      return null;
    });
  }
}
