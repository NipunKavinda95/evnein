import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grn_model.dart';
import '../../core/services/firebase_service.dart';

class GrnRepository {
  static final _collection =
      FirebaseService.firestore.collection('grn_records');

  static Future<void> saveGrn(GrnModel grn) async {
    await _collection.doc(grn.id).set(grn.toMap());
  }

  static Stream<List<GrnModel>> getGrnStream() {
    return FirebaseService.auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value([]);
      return _collection
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => GrnModel.fromMap(d.data())).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
          .handleError((e) => <GrnModel>[]);
    });
  }
}
