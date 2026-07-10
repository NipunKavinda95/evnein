class AppSettingsModel {
  final String adminPin;
  final String shopName;
  final String? shopPhone;
  final String? shopAddress;
  final int lowStockThreshold;

  AppSettingsModel({
    this.adminPin = '1234',
    this.shopName = 'EVNEIN',
    this.shopPhone,
    this.shopAddress,
    this.lowStockThreshold = 5,
  });

  Map<String, dynamic> toMap() => {
        'adminPin': adminPin,
        'shopName': shopName,
        'shopPhone': shopPhone,
        'shopAddress': shopAddress,
        'lowStockThreshold': lowStockThreshold,
      };

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) =>
      AppSettingsModel(
        adminPin: map['adminPin'] ?? '1234',
        shopName: map['shopName'] ?? 'EVNEIN',
        shopPhone: map['shopPhone'],
        shopAddress: map['shopAddress'],
        lowStockThreshold: map['lowStockThreshold'] ?? 5,
      );

  AppSettingsModel copyWith({
    String? adminPin,
    String? shopName,
    String? shopPhone,
    String? shopAddress,
    int? lowStockThreshold,
  }) =>
      AppSettingsModel(
        adminPin: adminPin ?? this.adminPin,
        shopName: shopName ?? this.shopName,
        shopPhone: shopPhone ?? this.shopPhone,
        shopAddress: shopAddress ?? this.shopAddress,
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      );
}
