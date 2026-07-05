class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final int totalPoints;
  final double totalSpent;
  final int totalOrders;
  final DateTime createdAt;
  final DateTime? lastVisit;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.totalPoints = 0,
    this.totalSpent = 0,
    this.totalOrders = 0,
    required this.createdAt,
    this.lastVisit,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'totalPoints': totalPoints,
        'totalSpent': totalSpent,
        'totalOrders': totalOrders,
        'createdAt': createdAt.toIso8601String(),
        'lastVisit': lastVisit?.toIso8601String(),
      };

  factory CustomerModel.fromMap(Map<String, dynamic> map) => CustomerModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        totalPoints: map['totalPoints'] ?? 0,
        totalSpent: (map['totalSpent'] ?? 0).toDouble(),
        totalOrders: map['totalOrders'] ?? 0,
        createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String(),
        ),
        lastVisit:
            map['lastVisit'] != null ? DateTime.parse(map['lastVisit']) : null,
      );

  CustomerModel copyWith({
    String? name,
    String? phone,
    int? totalPoints,
    double? totalSpent,
    int? totalOrders,
    DateTime? lastVisit,
  }) =>
      CustomerModel(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        totalPoints: totalPoints ?? this.totalPoints,
        totalSpent: totalSpent ?? this.totalSpent,
        totalOrders: totalOrders ?? this.totalOrders,
        createdAt: createdAt,
        lastVisit: lastVisit ?? this.lastVisit,
      );
}
