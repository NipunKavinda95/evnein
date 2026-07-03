import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  return CategoryRepository.getCategoriesStream();
});

class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  CategoryNotifier() : super(const AsyncValue.data(null));

  Future<bool> addCategory({
    required String name,
    required String emoji,
    required int sortOrder,
  }) async {
    state = const AsyncValue.loading();
    try {
      final category = CategoryModel(
        id: const Uuid().v4(),
        name: name,
        emoji: emoji,
        sortOrder: sortOrder,
        createdAt: DateTime.now(),
      );
      await CategoryRepository.addCategory(category);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    state = const AsyncValue.loading();
    try {
      await CategoryRepository.deleteCategory(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<void>>((ref) {
  return CategoryNotifier();
});
