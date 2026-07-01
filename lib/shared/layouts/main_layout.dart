import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../app/theme/app_theme.dart';
import '../../features/billing/screens/billing_screen.dart';
import '../../features/customers/screens/customers_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/reports/screens/reports_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    final screens = [
      const DashboardScreen(),
      const BillingScreen(),
      const ProductsScreen(),
      const CustomersScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      body: screens[currentTab],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentTab,
          onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Iconsax.home),
              activeIcon: Icon(Iconsax.home_15),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Iconsax.receipt),
              activeIcon: Icon(Iconsax.receipt5),
              label: 'Billing',
            ),
            BottomNavigationBarItem(
              icon: Icon(Iconsax.box),
              activeIcon: Icon(Iconsax.box5),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Iconsax.people),
              activeIcon: Icon(Iconsax.people5),
              label: 'Customers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Iconsax.chart),
              activeIcon: Icon(Iconsax.chart5),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}
