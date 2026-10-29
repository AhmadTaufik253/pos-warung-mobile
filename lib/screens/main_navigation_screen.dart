import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/constants.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'kasbon_screen.dart';
import 'master_product_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // 4 Menu Utama sesuai versi Web
  final List<Widget> _screens = const [
    HomeScreen(),            // Menu 1: Kasir
    MasterProductScreen(),   // Menu 2: Master Barang
    HistoryScreen(),         // Menu 3: Riwayat Transaksi
    KasbonScreen(),          // Menu 4: Buku Kasbon
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppConstants.borderGrey, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppConstants.primaryGreen,
          unselectedItemColor: AppConstants.textMuted,
          showSelectedLabels: false,   // Sembunyikan label teks saat dipilih
          showUnselectedLabels: false, // Sembunyikan label teks saat tidak dipilih
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.shoppingBag, size: 22),
              activeIcon: Icon(LucideIcons.shoppingBag, size: 24, color: AppConstants.primaryGreen),
              label: '',
              tooltip: 'Kasir',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.boxes, size: 22),
              activeIcon: Icon(LucideIcons.boxes, size: 24, color: AppConstants.primaryGreen),
              label: '',
              tooltip: 'Master Barang',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.receipt, size: 22),
              activeIcon: Icon(LucideIcons.receipt, size: 24, color: AppConstants.primaryGreen),
              label: '',
              tooltip: 'Riwayat Transaksi',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.bookOpen, size: 22),
              activeIcon: Icon(LucideIcons.bookOpen, size: 24, color: AppConstants.primaryGreen),
              label: '',
              tooltip: 'Buku Kasbon',
            ),
          ],
        ),
      ),
    );
  }
}