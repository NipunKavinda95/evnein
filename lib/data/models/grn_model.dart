class GrnModel {
  final String id;
  final String productId;
  final String productName;
  final int previousStock;
  final int quantityReceived;
  final int newStock;
  final String? supplierNote;
  final String receivedBy;
  final DateTime createdAt;

  GrnModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.previousStock,
    required this.quantityReceived,
    required this.newStock,
    this.supplierNote,
    required this.receivedBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'previousStock': previousStock,
        'quantityReceived': quantityReceived,
        'newStock': newStock,
        'supplierNote': supplierNote,
        'receivedBy': receivedBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GrnModel.fromMap(Map<String, dynamic> map) => GrnModel(
        id: map['id'] ?? '',
        productId: map['productId'] ?? '',
        productName: map['productName'] ?? '',
        previousStock: map['previousStock'] ?? 0,
        quantityReceived: map['quantityReceived'] ?? 0,
        newStock: map['newStock'] ?? 0,
        supplierNote: map['supplierNote'],
        receivedBy: map['receivedBy'] ?? '',
        createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String(),
        ),
      );
}
