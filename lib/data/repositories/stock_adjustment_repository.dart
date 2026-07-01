import '../models/stock_adjustment_model.dart';
import '../../core/services/firebase_service.dart';

class StockAdjustmentRepository {
  static final _collection =
      FirebaseService.firestore.collection('stock_adjustments');

  static Future<void> saveAdjustment(StockAdjustmentModel adjustment) async {
    await _collection.doc(adjustment.id).set(adjustment.toMap());
  }

  static Stream<List<StockAdjustmentModel>> getAdjustmentsStream() {
    return _collection.snapshots().map((snap) =>
        snap.docs.map((d) => StockAdjustmentModel.fromMap(d.data())).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  static Stream<List<StockAdjustmentModel>> getProductAdjustmentsStream(
      String productId) {
    return _collection.where('productId', isEqualTo: productId).snapshots().map(
        (snap) => snap.docs
            .map((d) => StockAdjustmentModel.fromMap(d.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }
}
