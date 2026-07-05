import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../../core/services/firebase_service.dart';

class CustomerRepository {
  static final _collection = FirebaseService.firestore.collection('customers');

  static Stream<List<CustomerModel>> getCustomersStream() {
    return FirebaseService.auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value([]);
      return _collection
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => CustomerModel.fromMap(d.data())).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
          .handleError((e) => <CustomerModel>[]);
    });
  }

  static Future<CustomerModel?> getCustomerByPhone(String phone) async {
    final query = await _collection
        .where('phone', isEqualTo: phone.trim())
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return CustomerModel.fromMap(query.docs.first.data());
    }
    return null;
  }

  static Future<void> saveCustomer(CustomerModel customer) async {
    await _collection.doc(customer.id).set(customer.toMap());
  }

  static Future<void> updateCustomer(CustomerModel customer) async {
    await _collection.doc(customer.id).update(customer.toMap());
  }

  static Future<void> updateAfterBill({
    required String customerId,
    required double billAmount,
    required int pointsEarned,
  }) async {
    await _collection.doc(customerId).update({
      'totalSpent': FieldValue.increment(billAmount),
      'totalOrders': FieldValue.increment(1),
      'totalPoints': FieldValue.increment(pointsEarned),
      'lastVisit': DateTime.now().toIso8601String(),
    });
  }
}
