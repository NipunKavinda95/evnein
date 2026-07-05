import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/bill_model.dart';
import '../../../data/repositories/customer_repository.dart';
import '../billing_provider.dart';
import '../../../features/customers/customer_provider.dart';

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

  bool _isLookingUp = false;
  bool _customerFound = false;
  String? _foundCustomerId;

  @override
  void dispose() {
    _discountController.dispose();
    _customerPhoneController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  Future<void> _lookupCustomer(String phone) async {
    if (phone.length < 10) {
      setState(() {
        _customerFound = false;
        _foundCustomerId = null;
      });
      return;
    }

    setState(() => _isLookingUp = true);

    try {
      final customer =
          await CustomerRepository.getCustomerByPhone(phone.trim());
      if (mounted) {
        if (customer != null) {
          setState(() {
            _customerFound = true;
            _foundCustomerId = customer.id;
            _isLookingUp = false;
          });
          _customerNameController.text = customer.name;
        } else {
          setState(() {
            _customerFound = false;
            _foundCustomerId = null;
            _isLookingUp = false;
          });
          _customerNameController.clear();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLookingUp = false);
    }
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
        final phone = _customerPhoneController.text.trim();
        if (phone.isNotEmpty) {
          final customerNotifier = ref.read(customerNotifierProvider.notifier);

          if (_customerFound && _foundCustomerId != null) {
            // Existing customer — just update stats
            await customerNotifier.updateAfterBill(
              customerId: _foundCustomerId!,
              billAmount: widget.subtotal - discount,
            );
          } else {
            // New customer — create then update
            final customer = await customerNotifier.findOrCreateCustomer(
              phone: phone,
              name: _customerNameController.text.trim().isEmpty
                  ? null
                  : _customerNameController.text.trim(),
            );
            if (customer != null) {
              await customerNotifier.updateAfterBill(
                customerId: customer.id,
                billAmount: widget.subtotal - discount,
              );
            }
          }
        }

        billingNotifier.clearBill();
        ref.read(discountProvider.notifier).state = 0;
        ref.read(paymentMethodProvider.notifier).state = 'cash';
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        // ignore: use_build_context_synchronously
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
        color: AppTheme.cardDark,
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
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
                color: AppTheme.textPrimary,
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '₹${item.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                )),

            const Divider(height: 24, color: AppTheme.borderColor),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                Text(
                  '₹${widget.subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Discount
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Discount (₹)',
                prefixIcon: Icon(Iconsax.discount_shape),
              ),
              onChanged: (val) {
                ref.read(discountProvider.notifier).state =
                    double.tryParse(val) ?? 0;
              },
            ),

            const SizedBox(height: 16),

            // Customer Phone with auto-lookup
            TextField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Customer Phone (optional)',
                prefixIcon: const Icon(Iconsax.call),
                suffixIcon: _isLookingUp
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      )
                    : _customerFound
                        ? const Icon(
                            Iconsax.tick_circle,
                            color: AppTheme.successColor,
                          )
                        : null,
                helperText: _customerFound ? 'Existing customer found ✓' : null,
                helperStyle: const TextStyle(color: AppTheme.successColor),
              ),
              onChanged: _lookupCustomer,
            ),

            const SizedBox(height: 12),

            // Customer Name — auto-filled or manual
            TextField(
              controller: _customerNameController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Customer Name (optional)',
                prefixIcon: const Icon(Iconsax.user),
                helperText: _customerFound
                    ? 'Auto-filled from existing customer'
                    : null,
                helperStyle: const TextStyle(color: AppTheme.textSecondary),
              ),
              readOnly: _customerFound,
            ),

            const SizedBox(height: 16),

            const Text(
              'Payment Method',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textPrimary,
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
                      color: AppTheme.textPrimary,
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
                          color: Colors.black,
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
            color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
