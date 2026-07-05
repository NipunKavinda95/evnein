import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../app/config/app_config.dart';

final customersStreamProvider = StreamProvider<List<CustomerModel>>((ref) {
  return CustomerRepository.getCustomersStream();
});

// Selected customer during billing
final selectedCustomerProvider = StateProvider<CustomerModel?>((ref) => null);

class CustomerNotifier extends StateNotifier<AsyncValue<void>> {
  CustomerNotifier() : super(const AsyncValue.data(null));

  Future<CustomerModel?> findOrCreateCustomer({
    required String phone,
    String? name,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Check if customer exists
      var customer = await CustomerRepository.getCustomerByPhone(phone);

      if (customer == null) {
        // Create new customer
        customer = CustomerModel(
          id: const Uuid().v4(),
          name: name ?? 'Customer',
          phone: phone,
          createdAt: DateTime.now(),
        );
        await CustomerRepository.saveCustomer(customer);
      }

      state = const AsyncValue.data(null);
      return customer;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }

  Future<void> updateAfterBill({
    required String customerId,
    required double billAmount,
  }) async {
    // Calculate points: 1 point per ₹100 spent
    final pointsEarned = (billAmount / AppConfig.pointsPerHundred).floor();
    await CustomerRepository.updateAfterBill(
      customerId: customerId,
      billAmount: billAmount,
      pointsEarned: pointsEarned,
    );
  }
}

final customerNotifierProvider =
    StateNotifierProvider<CustomerNotifier, AsyncValue<void>>((ref) {
  return CustomerNotifier();
});
