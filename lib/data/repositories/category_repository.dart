import '../models/category_model.dart';
import '../../core/services/firebase_service.dart';

class CategoryRepository {
  static final _collection = FirebaseService.firestore.collection('categories');

  static Stream<List<CategoryModel>> getCategoriesStream() {
    return FirebaseService.auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value([]);
      return _collection.snapshots().map((snap) {
        final list = snap.docs
            .map((d) => CategoryModel.fromMap(d.data()))
            .where((c) => c.isActive)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return list;
      }).handleError((e) => <CategoryModel>[]);
    });
  }

  static Future<void> addCategory(CategoryModel category) async {
    await _collection.doc(category.id).set(category.toMap());
  }

  static Future<void> updateCategory(CategoryModel category) async {
    await _collection.doc(category.id).update(category.toMap());
  }

  static Future<void> deleteCategory(String id) async {
    await _collection.doc(id).update({'isActive': false});
  }
}
