import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/services/firebase_service.dart';

// Current bill items state
class BillingNotifier extends StateNotifier<List<BillItem>> {
  BillingNotifier() : super([]);

  // Add product to bill
  void addItem(ProductModel product) {
    final existing = state.where((i) => i.productId == product.id).toList();

    if (existing.isNotEmpty) {
      final currentQty = existing.first.quantity;
      // Check if adding more would exceed stock
      if (currentQty >= product.stockQuantity) {
        return; // Silently block — UI already shows stock count
      }
      state = state.map((item) {
        if (item.productId == product.id) {
          item.quantity++;
        }
        return item;
      }).toList();
    } else {
      state = [
        ...state,
        BillItem(
          productId: product.id,
          productName: product.name,
          price: product.price,
        ),
      ];
    }
  }

  // Increase quantity
  void increaseQty(String productId) {
    state = state.map((item) {
      if (item.productId == productId) item.quantity++;
      return item;
    }).toList();
  }

  // Decrease quantity
  void decreaseQty(String productId) {
    state = state.map((item) {
      if (item.productId == productId && item.quantity > 1) {
        item.quantity--;
      }
      return item;
    }).toList();
    // Remove if quantity reaches 0
    state = state.where((item) => item.quantity > 0).toList();
  }

  // Remove item
  void removeItem(String productId) {
    state = state.where((i) => i.productId != productId).toList();
  }

  // Clear bill
  void clearBill() {
    state = [];
  }

  // Calculate subtotal
  double get subtotal => state.fold(0, (sum, item) => sum + item.total);
}

final billingProvider =
    StateNotifierProvider<BillingNotifier, List<BillItem>>((ref) {
  return BillingNotifier();
});

// Discount provider
final discountProvider = StateProvider<double>((ref) => 0);

// Payment method provider
final paymentMethodProvider = StateProvider<String>((ref) => 'cash');

// Save bill notifier
class SaveBillNotifier extends StateNotifier<AsyncValue<void>> {
  SaveBillNotifier() : super(const AsyncValue.data(null));

  Future<String?> saveBill({
    required List<BillItem> items,
    required double discount,
    required String paymentMethod,
    String? customerPhone,
    String? customerName,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Validate stock for each item before saving
      for (final item in items) {
        final productDoc = await FirebaseService.firestore
            .collection('products')
            .doc(item.productId)
            .get();

        if (productDoc.exists) {
          final currentStock = productDoc.data()?['stockQuantity'] ?? 0;
          if (currentStock < item.quantity) {
            state = AsyncValue.error(
              'Insufficient stock for ${item.productName}. Available: $currentStock',
              StackTrace.current,
            );
            return null;
          }
        }
      }

      final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
      final grandTotal = subtotal - discount;
      final billId = const Uuid().v4();

      final bill = BillModel(
        id: billId,
        items: items,
        subtotal: subtotal,
        discount: discount,
        grandTotal: grandTotal,
        paymentMethod: paymentMethod,
        customerPhone: customerPhone,
        customerName: customerName,
        createdAt: DateTime.now(),
      );

      await BillRepository.saveBill(bill);

      // Deduct stock for each item
      for (final item in items) {
        await ProductRepository.updateStock(
          item.productId,
          -item.quantity,
        );
      }

      state = const AsyncValue.data(null);
      return billId;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }
}

final saveBillProvider =
    StateNotifierProvider<SaveBillNotifier, AsyncValue<void>>((ref) {
  return SaveBillNotifier();
});
