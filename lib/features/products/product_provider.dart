import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

// Stream provider for all products
final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  return ProductRepository.getProductsStream();
});

// Filtered by category
final juiceProductsProvider = Provider<List<ProductModel>>((ref) {
  final products = ref.watch(productsStreamProvider).valueOrNull ?? [];
  return products.where((p) => p.category == 'juice').toList();
});

final cakeProductsProvider = Provider<List<ProductModel>>((ref) {
  final products = ref.watch(productsStreamProvider).valueOrNull ?? [];
  return products.where((p) => p.category == 'cake').toList();
});

// Product actions notifier
class ProductNotifier extends StateNotifier<AsyncValue<void>> {
  ProductNotifier() : super(const AsyncValue.data(null));

  Future<bool> addProduct({
    required String name,
    required String category,
    required double price,
    required int stockQuantity,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Check for duplicate name
      final allProducts = await ProductRepository.getAllProducts();
      final duplicate = allProducts.any(
        (p) => p.name.trim().toLowerCase() == name.trim().toLowerCase(),
      );

      if (duplicate) {
        state = AsyncValue.error(
          'Product "$name" already exists!',
          StackTrace.current,
        );
        return false;
      }

      final product = ProductModel(
        id: const Uuid().v4(),
        name: name,
        category: category,
        price: price,
        stockQuantity: stockQuantity,
        createdAt: DateTime.now(),
      );
      await ProductRepository.addProduct(product);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    state = const AsyncValue.loading();
    try {
      await ProductRepository.updateProduct(product);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    state = const AsyncValue.loading();
    try {
      await ProductRepository.deleteProduct(productId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<void>>((ref) {
  return ProductNotifier();
});
