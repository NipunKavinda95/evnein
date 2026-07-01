import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/bill_model.dart';
import '../billing_provider.dart';

class BillSummarySheet extends ConsumerStatefulWidget {
  final List<BillItem> billItems;
  final double subtotal;

  const BillSummarySheet({
    super.key,
    required this.billItems,
    required this.subtotal,
  });

  @override
  ConsumerState<BillSummarySheet> createState() => _BillSummarySheetState();
}

class _BillSummarySheetState extends ConsumerState<BillSummarySheet> {
  final _discountController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerNameController = TextEditingController();

  @override
  void dispose() {
    _discountController.dispose();
    _customerPhoneController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  Future<void> _confirmBill() async {
    final discount = ref.read(discountProvider);
    final paymentMethod = ref.read(paymentMethodProvider);
    final billingNotifier = ref.read(billingProvider.notifier);
    final saveBillNotifier = ref.read(saveBillProvider.notifier);

    final billId = await saveBillNotifier.saveBill(
      items: widget.billItems,
      discount: discount,
      paymentMethod: paymentMethod,
      customerPhone: _customerPhoneController.text.trim().isEmpty
          ? null
          : _customerPhoneController.text.trim(),
      customerName: _customerNameController.text.trim().isEmpty
          ? null
          : _customerNameController.text.trim(),
    );

    if (mounted) {
      if (billId != null) {
        billingNotifier.clearBill();
        ref.read(discountProvider.notifier).state = 0;
        ref.read(paymentMethodProvider.notifier).state = 'cash';
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.tick_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Bill #${billId.substring(0, 8)} saved!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Show stock error
        final error = ref.read(saveBillProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error?.toString() ?? 'Failed to save bill'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final discount = ref.watch(discountProvider);
    final paymentMethod = ref.watch(paymentMethodProvider);
    final grandTotal = widget.subtotal - discount;
    final isSaving = ref.watch(saveBillProvider).isLoading;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Bill Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Items list
            ...widget.billItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} x${item.quantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '₹${item.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )),

            const Divider(height: 24),

            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('₹${widget.subtotal.toStringAsFixed(0)}'),
              ],
            ),

            const SizedBox(height: 16),

            // Discount
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Discount (₹)',
                prefixIcon: const Icon(
                  Iconsax.discount_shape,
                  color: AppTheme.primaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (val) {
                ref.read(discountProvider.notifier).state =
                    double.tryParse(val) ?? 0;
              },
            ),

            const SizedBox(height: 16),

            // Customer Info (optional)
            TextField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Customer Phone (optional)',
                prefixIcon: const Icon(
                  Iconsax.call,
                  color: AppTheme.primaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Payment Method
            const Text(
              'Payment Method',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPaymentOption(ref, 'cash', '💵 Cash', paymentMethod),
                const SizedBox(width: 8),
                _buildPaymentOption(ref, 'upi', '📱 UPI', paymentMethod),
                const SizedBox(width: 8),
                _buildPaymentOption(ref, 'card', '💳 Card', paymentMethod),
              ],
            ),

            const SizedBox(height: 20),

            // Grand Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grand Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '₹${grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _confirmBill,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Iconsax.tick_circle),
                label: Text(
                  isSaving ? 'Saving...' : 'Confirm Bill',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    WidgetRef ref,
    String value,
    String label,
    String selected,
  ) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(paymentMethodProvider.notifier).state = value,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
