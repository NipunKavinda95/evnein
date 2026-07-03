import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/stock_adjustment_model.dart';
import '../../../data/repositories/stock_adjustment_repository.dart';
import '../../../core/services/firebase_service.dart';
import '../../../features/auth/user_provider.dart';
import '../product_provider.dart';
import '../category_provider.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final ProductModel? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  String? _selectedCategory;
  bool _isAvailable = true;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = ''; // Empty for deduct mode
      _selectedCategory = widget.product!.category;
      _isAvailable = widget.product!.isAvailable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_isEditing) {
      final deductQty = int.tryParse(_stockController.text) ?? 0;
      final previousStock = widget.product!.stockQuantity;
      final newStock = previousStock - deductQty;

      if (deductQty < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deduction cannot be negative')),
        );
        return;
      }

      if (newStock < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot deduct $deductQty. Only $previousStock in stock.',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      if (deductQty > 0) {
        final reasonData = await _showReasonDialog(deductQty);
        if (reasonData == null) return;
        await _saveProduct(newStock);
        await _logStockAdjustment(
          previousStock: previousStock,
          newStock: newStock,
          difference: deductQty,
          reason: reasonData['reason']!,
          comment: reasonData['comment'],
        );
        return;
      }

      // No deduction — just update other fields
      await _saveProduct(previousStock);
      return;
    }

    // New product
    if (_stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter stock quantity')),
      );
      return;
    }
    await _saveProduct(int.parse(_stockController.text));
  }

  Future<void> _saveProduct(int stockQty) async {
    final notifier = ref.read(productNotifierProvider.notifier);
    bool success;

    if (_isEditing) {
      final updated = widget.product!.copyWith(
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        price: double.parse(_priceController.text),
        stockQuantity: stockQty,
        isAvailable: _isAvailable,
      );
      success = await notifier.updateProduct(updated);
    } else {
      success = await notifier.addProduct(
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        price: double.parse(_priceController.text),
        stockQuantity: stockQty,
      );
    }

    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Product updated!' : 'Product added!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else if (mounted && !success) {
      final error = ref.read(productNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error?.toString() ?? 'Failed to save product',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _logStockAdjustment({
    required int previousStock,
    required int newStock,
    required int difference,
    required String reason,
    String? comment,
  }) async {
    final userAsync = ref.read(currentUserProvider);
    final adjustedBy = userAsync.valueOrNull?.name ??
        FirebaseService.currentUser?.email ??
        'Unknown';

    final adjustment = StockAdjustmentModel(
      id: const Uuid().v4(),
      productId: widget.product!.id,
      productName: widget.product!.name,
      previousStock: previousStock,
      newStock: newStock,
      difference: difference,
      reason: reason,
      comment: comment,
      adjustedBy: adjustedBy,
      createdAt: DateTime.now(),
    );

    await StockAdjustmentRepository.saveAdjustment(adjustment);
  }

  Future<Map<String, String>?> _showReasonDialog(int difference) async {
    String selectedReason = 'Damaged';
    final commentController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          title: Row(
            children: [
              const Icon(Iconsax.warning_2, color: AppTheme.errorColor),
              const SizedBox(width: 8),
              Text(
                'Deduct $difference units',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why is stock being reduced?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Damaged', 'Expired', 'Wastage', 'Other']
                    .map((reason) => ChoiceChip(
                          label: Text(reason),
                          selected: selectedReason == reason,
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: selectedReason == reason
                                ? Colors.black
                                : AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          onSelected: (_) {
                            setDialogState(() => selectedReason = reason);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Additional comment (optional)',
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
              onPressed: () {
                Navigator.pop(context, {
                  'reason': selectedReason,
                  'comment': commentController.text.trim(),
                });
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final isLoading = ref.watch(productNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Product' : 'Add Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Category Selector
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  categoriesAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => const Text('Error loading categories'),
                    data: (categories) {
                      if (categories.isEmpty) {
                        return const Text(
                          'No categories found. Add categories first.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        );
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final isSelected = _selectedCategory == cat.name;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat.name),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.borderColor,
                                ),
                              ),
                              child: Text(
                                '${cat.emoji} ${cat.name}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.black
                                      : AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Product Details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      prefixIcon: Icon(Iconsax.tag),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Price (₹)',
                      prefixIcon: Icon(Iconsax.money),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText:
                          _isEditing ? 'Deduct Quantity' : 'Stock Quantity',
                      hintText: _isEditing
                          ? 'How many to deduct? (0 = no change)'
                          : 'Enter stock',
                      prefixIcon: const Icon(Iconsax.box),
                      helperText: _isEditing
                          ? 'Current stock: ${widget.product!.stockQuantity}'
                          : null,
                      helperStyle:
                          const TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available for Sale',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Switch(
                        value: _isAvailable,
                        onChanged: (val) => setState(() => _isAvailable = val),
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _save,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        _isEditing ? 'Update Product' : 'Add Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
