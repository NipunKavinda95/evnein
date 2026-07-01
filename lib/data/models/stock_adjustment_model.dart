class StockAdjustmentModel {
  final String id;
  final String productId;
  final String productName;
  final int previousStock;
  final int newStock;
  final int difference;
  final String reason;
  final String? comment;
  final String adjustedBy;
  final DateTime createdAt;

  StockAdjustmentModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.previousStock,
    required this.newStock,
    required this.difference,
    required this.reason,
    this.comment,
    required this.adjustedBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'previousStock': previousStock,
        'newStock': newStock,
        'difference': difference,
        'reason': reason,
        'comment': comment,
        'adjustedBy': adjustedBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StockAdjustmentModel.fromMap(Map<String, dynamic> map) =>
      StockAdjustmentModel(
        id: map['id'] ?? '',
        productId: map['productId'] ?? '',
        productName: map['productName'] ?? '',
        previousStock: map['previousStock'] ?? 0,
        newStock: map['newStock'] ?? 0,
        difference: map['difference'] ?? 0,
        reason: map['reason'] ?? '',
        comment: map['comment'],
        adjustedBy: map['adjustedBy'] ?? '',
        createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String(),
        ),
      );
}
