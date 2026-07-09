import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/bill_model.dart';
import '../../../data/repositories/bill_repository.dart';

final todayBillsProvider = StreamProvider<List<BillModel>>((ref) {
  return BillRepository.getTodaysBillsStream();
});

final allBillsProvider = StreamProvider<List<BillModel>>((ref) {
  return BillRepository.getAllBillsStream();
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<BillModel> _filterBills(List<BillModel> bills, String period) {
    final now = DateTime.now();
    switch (period) {
      case 'today':
        return bills
            .where((b) =>
                b.createdAt.year == now.year &&
                b.createdAt.month == now.month &&
                b.createdAt.day == now.day)
            .toList();
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return bills.where((b) => b.createdAt.isAfter(weekAgo)).toList();
      case 'all':
      default:
        return bills;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black.withOpacity(0.7), size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, double total) {
    final percent = total > 0 ? (amount / total) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: AppTheme.surfaceDark,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildReportTab({required String period}) {
    final allBillsAsync = ref.watch(allBillsProvider);

    return allBillsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allBills) {
        final bills = _filterBills(allBills, period);
        final totalRevenue = bills.fold(0.0, (sum, b) => sum + b.grandTotal);
        final totalOrders = bills.length;
        final totalDiscount = bills.fold(0.0, (sum, b) => sum + b.discount);
        final avgOrder = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

        final cashTotal = bills
            .where((b) => b.paymentMethod == 'cash')
            .fold(0.0, (sum, b) => sum + b.grandTotal);
        final upiTotal = bills
            .where((b) => b.paymentMethod == 'upi')
            .fold(0.0, (sum, b) => sum + b.grandTotal);
        final cardTotal = bills
            .where((b) => b.paymentMethod == 'card')
            .fold(0.0, (sum, b) => sum + b.grandTotal);

        final itemMap = <String, int>{};
        for (final bill in bills) {
          for (final item in bill.items) {
            itemMap[item.productName] =
                (itemMap[item.productName] ?? 0) + item.quantity;
          }
        }
        final sortedItems = itemMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Revenue',
                      '₹${totalRevenue.toStringAsFixed(0)}',
                      Iconsax.money,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Orders',
                      '$totalOrders',
                      Iconsax.receipt,
                      AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Avg Order',
                      '₹${avgOrder.toStringAsFixed(0)}',
                      Iconsax.chart,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Discounts',
                      '₹${totalDiscount.toStringAsFixed(0)}',
                      Iconsax.discount_shape,
                      AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Payment Breakdown'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _buildPaymentRow('💵 Cash', cashTotal, totalRevenue),
                    const SizedBox(height: 12),
                    _buildPaymentRow('📱 UPI', upiTotal, totalRevenue),
                    const SizedBox(height: 12),
                    _buildPaymentRow('💳 Card', cardTotal, totalRevenue),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Best Selling Items'),
              const SizedBox(height: 12),
              if (sortedItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Center(
                    child: Text(
                      'No sales data yet',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    children: sortedItems
                        .take(10)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final rank = entry.key + 1;
                      final item = entry.value;
                      final isLast =
                          entry.key == sortedItems.take(10).length - 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: isLast
                                ? BorderSide.none
                                : const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: rank == 1
                                    ? AppTheme.primaryColor
                                    : AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '$rank',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: rank == 1
                                        ? Colors.black
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.key,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.value} sold',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 24),
              _buildSectionTitle('Recent Bills'),
              const SizedBox(height: 12),
              if (bills.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Center(
                    child: Text(
                      'No bills yet',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ...bills.take(20).map((bill) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Iconsax.receipt,
                              color: AppTheme.primaryColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bill #${bill.id.substring(0, 8)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${bill.items.length} items • ${bill.paymentMethod.toUpperCase()} • ${_formatDate(bill.createdAt)}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${bill.grandTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'This Week'),
            Tab(text: 'All Time'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportTab(period: 'today'),
          _buildReportTab(period: 'week'),
          _buildReportTab(period: 'all'),
        ],
      ),
    );
  }
}
