import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../../core/services/firebase_service.dart';

class ProductRepository {
  static final _collection = FirebaseService.firestore.collection('products');

  // Get all products stream
  static Stream<List<ProductModel>> getProductsStream() {
    return FirebaseService.auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value([]);
      return _collection
          .orderBy('category')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data()))
              .toList())
          .handleError((e) => <ProductModel>[]);
    });
  }

  // Add product
  static Future<void> addProduct(ProductModel product) async {
    await _collection.doc(product.id).set(product.toMap());
  }

  // Update product
  static Future<void> updateProduct(ProductModel product) async {
    await _collection.doc(product.id).update(product.toMap());
  }

  // Delete product
  static Future<void> deleteProduct(String productId) async {
    await _collection.doc(productId).delete();
  }

  // Update stock quantity (pass negative value to deduct)
  static Future<void> updateStock(String productId, int changeAmount) async {
    await _collection.doc(productId).update({
      'stockQuantity': FieldValue.increment(changeAmount),
    });
  }
}
