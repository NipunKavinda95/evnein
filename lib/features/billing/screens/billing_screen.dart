import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../../../features/products/product_provider.dart';
import '../billing_provider.dart';
import '../widgets/bill_summary_sheet.dart';
import '../../../data/models/bill_model.dart';
import '../../../features/products/category_provider.dart';
import '../../../data/repositories/settings_repository.dart';

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
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text(
          'New Bill',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.cardDark,
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
          final categoriesAsync = ref.watch(categoriesStreamProvider);

          return categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const SizedBox(),
            data: (categories) {
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ...categories.map((cat) {
                          final catProducts = products
                              .where((p) =>
                                  p.category == cat.name && p.isAvailable)
                              .toList();
                          if (catProducts.isEmpty) return const SizedBox();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCategoryLabel('${cat.emoji} ${cat.name}'),
                              const SizedBox(height: 10),
                              _buildProductGrid(context, catProducts,
                                  billingNotifier, billItems),
                              const SizedBox(height: 16),
                            ],
                          );
                        }),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              );
            },
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
        color: AppTheme.textPrimary,
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
        childAspectRatio: 0.8,
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
                color: qty > 0 ? AppTheme.primaryColor : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: qty > 0 ? AppTheme.primaryColor : AppTheme.borderColor,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Iconsax.box,
                    size: 28,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      product.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: qty > 0 ? Colors.black : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: qty > 0 ? Colors.black : AppTheme.primaryColor,
                    ),
                  ),
                  if (qty > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _showDeductPinDialog(
                            context,
                            notifier,
                            product.id,
                          ),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.remove,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '$qty',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => notifier.addItem(product),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
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
        color: AppTheme.cardDark,
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
                      color: AppTheme.textPrimary,
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

  void _showDeductPinDialog(
    BuildContext context,
    BillingNotifier notifier,
    String productId,
  ) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: const Row(
          children: [
            Icon(Iconsax.lock, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text(
              'Admin PIN Required',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter admin PIN to remove item',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              autofocus: true,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                letterSpacing: 8,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                counterText: '',
                hintText: '••••',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Get PIN from Firestore
              final settings = await SettingsRepository.getSettings();
              if (!context.mounted) return;
              if (pinController.text == settings.adminPin) {
                Navigator.pop(context);
                notifier.decreaseQty(productId);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wrong PIN!'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
