// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill_model.dart';
import '../../core/services/firebase_service.dart';

class BillRepository {
  static final _collection = FirebaseService.firestore.collection('bills');

  static Future<void> saveBill(BillModel bill) async {
    await _collection.doc(bill.id).set(bill.toMap());
  }

  static Stream<List<BillModel>> getTodaysBillsStream() {
    return FirebaseService.auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value([]);
      return _collection.snapshots().map((snap) {
        final today = DateTime.now();
        return snap.docs
            .map((d) => BillModel.fromMap(d.data()))
            .where((bill) =>
                bill.createdAt.year == today.year &&
                bill.createdAt.month == today.month &&
                bill.createdAt.day == today.day)
            .toList();
      }).handleError((e) => <BillModel>[]);
    });
  }
}
