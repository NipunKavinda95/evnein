import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../../../features/products/product_provider.dart';
import '../billing_provider.dart';
import '../widgets/bill_summary_sheet.dart';
import '../../../data/models/bill_model.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final billItems = ref.watch(billingProvider);
    final billingNotifier = ref.read(billingProvider.notifier);

    final subtotal = billItems.fold(
      0.0,
      (sum, item) => sum + item.total,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'New Bill',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          if (billItems.isNotEmpty)
            IconButton(
              icon: const Icon(Iconsax.trash, color: Colors.white),
              onPressed: () {
                ref.read(billingProvider.notifier).clearBill();
                ref.read(discountProvider.notifier).state = 0;
              },
            ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          final juices = products
              .where((p) => p.category == 'juice' && p.isAvailable)
              .toList();
          final cakes = products
              .where((p) => p.category == 'cake' && p.isAvailable)
              .toList();

          return Column(
            children: [
              // Products Grid
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (juices.isNotEmpty) ...[
                      _buildCategoryLabel('🍹 Juices'),
                      const SizedBox(height: 10),
                      _buildProductGrid(
                          context, juices, billingNotifier, billItems),
                      const SizedBox(height: 16),
                    ],
                    if (cakes.isNotEmpty) ...[
                      _buildCategoryLabel('🎂 Cakes'),
                      const SizedBox(height: 10),
                      _buildProductGrid(
                          context, cakes, billingNotifier, billItems),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      // Bottom Bill Summary
      bottomSheet: billItems.isEmpty
          ? null
          : _buildBottomBar(context, ref, billItems, subtotal),
    );
  }

  Widget _buildCategoryLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildProductGrid(
    BuildContext context,
    List<ProductModel> products,
    BillingNotifier notifier,
    List<BillItem> billItems,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final inBill =
            billItems.where((i) => i.productId == product.id).toList();
        final qty = inBill.isNotEmpty ? inBill.first.quantity : 0;

        return Opacity(
          opacity: product.stockQuantity <= 0 ? 0.4 : 1.0,
          child: GestureDetector(
            onTap: () {
              if (product.stockQuantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Iconsax.warning_2, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('${product.name} is out of stock!'),
                      ],
                    ),
                    backgroundColor: AppTheme.errorColor,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }
              notifier.addItem(product);
            },
            child: Container(
              decoration: BoxDecoration(
                color: qty > 0 ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    product.category == 'juice' ? Iconsax.cup : Iconsax.cake,
                    size: 32,
                    color: qty > 0 ? Colors.white : AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: qty > 0 ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: qty > 0 ? Colors.white : AppTheme.primaryColor,
                    ),
                  ),
                  if (qty > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'x$qty',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    List<BillItem> billItems,
    double subtotal,
  ) {
    final discount = ref.watch(discountProvider);
    final grandTotal = subtotal - discount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${billItems.length} item(s)',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '₹${grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => BillSummarySheet(
                    billItems: billItems,
                    subtotal: subtotal,
                  ),
                );
              },
              icon: const Icon(Iconsax.receipt_add),
              label: const Text(
                'Checkout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
