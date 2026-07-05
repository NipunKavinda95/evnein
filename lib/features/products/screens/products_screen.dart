import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../product_provider.dart';
import 'add_edit_product_screen.dart';
import 'stock_history_screen.dart';
import 'category_screen.dart';
import '../category_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/grn_model.dart';
import '../../../data/repositories/grn_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../features/auth/user_provider.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.cardDark,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.category, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.document_text, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StockHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.add_circle, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          if (products.isEmpty) {
            return _buildEmptyState(context);
          }

          final categoriesAsync = ref.watch(categoriesStreamProvider);

          return categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const SizedBox(),
            data: (categories) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...categories.map((cat) {
                    final catProducts =
                        products.where((p) => p.category == cat.name).toList();
                    if (catProducts.isEmpty) return const SizedBox();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryHeader(
                            '${cat.emoji} ${cat.name}', catProducts.length),
                        const SizedBox(height: 8),
                        ...catProducts
                            .map((p) => _buildProductCard(context, ref, p)),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                  // Uncategorized products
                  ...() {
                    final categoryNames = categories.map((c) => c.name).toSet();
                    final uncategorized = products
                        .where((p) => !categoryNames.contains(p.category))
                        .toList();
                    if (uncategorized.isEmpty) return <Widget>[];
                    return [
                      _buildCategoryHeader('📦 Other', uncategorized.length),
                      const SizedBox(height: 8),
                      ...uncategorized
                          .map((p) => _buildProductCard(context, ref, p)),
                    ];
                  }(),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddEditProductScreen(),
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: const Text(
          'Add Product',
          style:
              TextStyle(color: AppTheme.cardDark, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.box, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No products yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first juice or cake',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddEditProductScreen(),
              ),
            ),
            icon: const Icon(Iconsax.add),
            label: const Text('Add Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count items',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(
      BuildContext context, WidgetRef ref, ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: product.category == 'juice'
                ? AppTheme.primaryColor.withOpacity(0.1)
                : AppTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            product.category == 'juice' ? Iconsax.cup : Iconsax.cake,
            color: product.category == 'juice'
                ? AppTheme.primaryColor
                : AppTheme.secondaryColor,
            size: 24,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '₹${product.price.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: product.stockQuantity <= 5
                    ? AppTheme.errorColor.withOpacity(0.1)
                    : AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Stock: ${product.stockQuantity}',
                style: TextStyle(
                  fontSize: 11,
                  color: product.stockQuantity <= 5
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add Stock Button
            GestureDetector(
              onTap: () => _showAddStockDialog(context, ref, product),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.add,
                      size: 14,
                      color: AppTheme.successColor,
                    ),
                    SizedBox(width: 2),
                    Text(
                      'Stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Iconsax.edit, size: 18, color: Colors.grey),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditProductScreen(product: product),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Iconsax.trash,
                  size: 18, color: AppTheme.errorColor),
              onPressed: () => _confirmDelete(context, ref, product),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStockDialog(
      BuildContext context, WidgetRef ref, ProductModel product) {
    final qtyController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Stock',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            Text(
              product.name,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Stock',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${product.stockQuantity}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Quantity Received',
                prefixIcon: Icon(Iconsax.add_circle),
                hintText: 'How many received?',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Supplier Note (optional)',
                prefixIcon: Icon(Iconsax.document_text),
                hintText: 'e.g. Supplier name, invoice no.',
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
              final qty = int.tryParse(qtyController.text);
              if (qty == null || qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid quantity'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              await _addStock(
                context: context,
                ref: ref,
                product: product,
                qty: qty,
                note: noteController.text.trim(),
              );
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }

  Future<void> _addStock({
    required BuildContext context,
    required WidgetRef ref,
    required ProductModel product,
    required int qty,
    required String note,
  }) async {
    try {
      final previousStock = product.stockQuantity;
      final newStock = previousStock + qty;

      // Update product stock
      await ProductRepository.updateStock(product.id, qty);

      // Save GRN record
      final userAsync = ref.read(currentUserProvider);
      final receivedBy = userAsync.valueOrNull?.name ?? 'Admin';

      final grn = GrnModel(
        id: const Uuid().v4(),
        productId: product.id,
        productName: product.name,
        previousStock: previousStock,
        quantityReceived: qty,
        newStock: newStock,
        supplierNote: note.isEmpty ? null : note,
        receivedBy: receivedBy,
        createdAt: DateTime.now(),
      );

      await GrnRepository.saveGrn(grn);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added $qty units to ${product.name}. New stock: $newStock',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add stock'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ProductModel product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(productNotifierProvider.notifier)
                  .deleteProduct(product.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
