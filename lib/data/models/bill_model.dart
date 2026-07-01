class BillItem {
  final String productId;
  final String productName;
  final double price;
  int quantity;

  BillItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'price': price,
        'quantity': quantity,
        'total': total,
      };
}

class BillModel {
  final String id;
  final List<BillItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final String paymentMethod;
  final String? customerPhone;
  final String? customerName;
  final DateTime createdAt;
  final String status;

  BillModel({
    required this.id,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.tax = 0,
    required this.grandTotal,
    required this.paymentMethod,
    this.customerPhone,
    this.customerName,
    required this.createdAt,
    this.status = 'completed',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'grandTotal': grandTotal,
        'paymentMethod': paymentMethod,
        'customerPhone': customerPhone,
        'customerName': customerName,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };

  factory BillModel.fromMap(Map<String, dynamic> map) => BillModel(
        id: map['id'] ?? '',
        items: (map['items'] as List<dynamic>? ?? [])
            .map((i) => BillItem(
                  productId: i['productId'],
                  productName: i['productName'],
                  price: (i['price'] as num).toDouble(),
                  quantity: i['quantity'],
                ))
            .toList(),
        subtotal: (map['subtotal'] as num).toDouble(),
        discount: (map['discount'] as num? ?? 0).toDouble(),
        tax: (map['tax'] as num? ?? 0).toDouble(),
        grandTotal: (map['grandTotal'] as num).toDouble(),
        paymentMethod: map['paymentMethod'] ?? 'cash',
        customerPhone: map['customerPhone'],
        customerName: map['customerName'],
        createdAt: DateTime.parse(map['createdAt']),
        status: map['status'] ?? 'completed',
      );
}
