import 'package:flutter/material.dart';
import 'package:mobile/screens/pos_screen.dart';
import 'package:mobile/screens/master_data_screen.dart';
import 'package:mobile/screens/report_screen.dart';
import 'package:mobile/screens/dashboard_screen.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';

class _NavTab {
  final Widget screen;
  final IconData icon;
  final String label;
  final String? permission;

  _NavTab({required this.screen, required this.icon, required this.label, this.permission});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<_NavTab> _allTabs = [
    _NavTab(screen: const DashboardScreen(), icon: Icons.dashboard_outlined, label: 'Dashboard'), // Owner Only
    _NavTab(screen: const MasterDataScreen(), icon: Icons.inventory_2_outlined, label: 'Produk', permission: 'Manajemen Produk'),
    _NavTab(screen: const POSScreen(), icon: Icons.credit_card_outlined, label: 'Kasir'), // Always
    _NavTab(screen: const ReportScreen(), icon: Icons.bar_chart_outlined, label: 'Laporan', permission: 'Laporan Penjualan'),
    _NavTab(screen: const ProfileScreen(), icon: Icons.store_outlined, label: 'Toko'), // Owner Only
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    // Filter tabs based on role and permissions
    final List<_NavTab> activeTabs = _allTabs.where((tab) {
      if (auth.isOwner) return true;
      if (tab.label == 'Dashboard' || tab.label == 'Toko') return false; // Owners only, non-owners filtered out here
      if (tab.permission == null) return true; // Always visible (e.g. Kasir)
      return auth.hasPermission(tab.permission!);
    }).toList();

    // Ensure _currentIndex is valid
    if (_currentIndex >= activeTabs.length) {
      _currentIndex = activeTabs.isNotEmpty ? activeTabs.length - 1 : 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
        final isMobile = constraints.maxWidth < 600 || isPortrait;

        if (isMobile) {
          return Scaffold(
            body: activeTabs.isEmpty ? const Center(child: Text('Tidak ada akses')) : activeTabs[_currentIndex].screen,
            bottomNavigationBar: activeTabs.isEmpty ? null : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.green,
              unselectedItemColor: Colors.grey,
              items: activeTabs.map((tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              )).toList(),
            ),
          );
        }

        // Tablet/Desktop Layout with Sidebar
        return Scaffold(
          body: Row(
            children: [
              if (activeTabs.isNotEmpty)
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) => setState(() => _currentIndex = index),
                  labelType: NavigationRailLabelType.all,
                  extended: false,
                  selectedIconTheme: const IconThemeData(color: Colors.green),
                  selectedLabelTextStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  destinations: activeTabs.map((tab) => NavigationRailDestination(
                    icon: Icon(tab.icon),
                    label: Text(tab.label),
                  )).toList(),
                ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: activeTabs.isEmpty 
                  ? const Center(child: Text('Tidak ada akses')) 
                  : activeTabs[_currentIndex].screen
              ),
            ],
          ),
        );
      },
    );
  }
}
