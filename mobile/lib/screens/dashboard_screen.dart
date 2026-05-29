import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/staff_list_screen.dart';
import 'package:mobile/screens/edit_store_screen.dart';
import 'package:mobile/screens/report_screen.dart';
import 'package:mobile/screens/theme_settings_screen.dart';
import 'package:mobile/screens/referral_management_screen.dart';
import 'package:mobile/screens/history_screen.dart';
import 'package:mobile/screens/cash_flow_screen.dart';
import 'package:mobile/screens/expense_screen.dart';

import 'package:mobile/screens/category_list_screen.dart';
import 'package:mobile/screens/customer_list_screen.dart';
import 'package:mobile/screens/stock_report_screen.dart';
import 'package:mobile/screens/printer_settings_screen.dart';
import 'package:mobile/screens/master_data_screen.dart';
import 'dart:async';
import 'package:mobile/services/sync_service.dart';
import 'package:mobile/screens/online_store_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  List<Map<String, dynamic>> _getBannerData(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return [
      {
        'title': 'Kelola Toko Lebih Mudah',
        'subtitle': 'Pantau stok & penjualan secara realtime',
        'color': primaryColor,
        'icon': Icons.insights,
      },
      {
        'title': 'Laporan Otomatis',
        'subtitle': 'Cetak laporan laba rugi dalam satu klik',
        'color': Colors.blue[800],
        'icon': Icons.description,
      },
      {
        'title': 'Bantuan Cashiro',
        'subtitle': 'Butuh panduan? Hubungi tim support kami',
        'color': Colors.orange[800],
        'icon': Icons.support_agent,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      final bannerCount = 3; // Fixed for now
      if (_currentPage < bannerCount - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerData = _getBannerData(context);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Utama'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷️ Banner Slider (Carousel)
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: bannerData.length,
                itemBuilder: (context, index) {
                  final banner = bannerData[index];
                  return Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [banner['color'], (banner['color'] as Color).withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(banner['icon'], size: 120, color: Colors.white12),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                banner['title'],
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                banner['subtitle'],
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 🟢 Page Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: bannerData.asMap().entries.map((entry) {
                return Container(
                  width: _currentPage == entry.key ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == entry.key ? primaryColor : Colors.grey[300],
                  ),
                );
              }).toList(),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                'Menu Utama',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // 📱 4x2 Grid Menu (9 items now, but we keep 8 by removing one or just allowing it to flow)
            // Let's replace 'Akun' or just add it to the list.
            // Actually user wants 4x2 style but 8 or 9 is fine. 
            // I'll add "Tema" as the 9th item and let it flow to next row.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4, // 4 columns across
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75, // Taller for 4 columns
                children: [
                  _buildGridItem(
                    context,
                    icon: Icons.inventory_2_outlined,
                    color: Colors.indigo,
                    title: 'Master Data',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MasterDataScreen())),
                  ),
                  _buildGridItem(
                    context,
                    icon: Icons.category_outlined,
                    color: Colors.purple,
                    title: 'Kategori',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryListScreen())),
                  ),
                  _buildGridItem(
                    context,
                    icon: Icons.person_search_outlined,
                    color: Colors.green,
                    title: 'Pelanggan',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen())),
                  ),
                  _buildGridItem(
                    context,
                    icon: Icons.storefront_outlined,
                    color: const Color(0xFF006d77),
                    title: 'Toko Online',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnlineStoreScreen())),
                  ),
                  _buildGridItem(
                    context,
                    icon: Icons.bar_chart_outlined,
                    color: Colors.blue,
                    title: 'Laba Rugi',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen(initialTabIndex: 0))),
                  ),
                  _buildGridItem(
                    context,
                    icon: Icons.trending_up,
                    color: Colors.amber,
                    title: 'Terlaris',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen(initialTabIndex: 1))),
                  ),
                  _buildGridItem(
                    context,
                    icon: Icons.assessment_outlined,
                    color: Colors.teal,
                    title: 'Stok',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockReportScreen())),
                  ),
                  _buildGridItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    color: Colors.blueGrey,
                    title: 'Riwayat',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                  ),
                  _buildGridItem(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.teal,
                    title: 'Arus Kas',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashFlowScreen())),
                  ),
                  _buildGridItem(
                    context,
                    icon: Icons.trending_down_outlined,
                    color: Colors.red,
                    title: 'Pengeluaran',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen())),
                  ),
                  _buildGridItem(
                    context,
                    icon: Icons.people_alt_outlined,
                    color: Colors.blue,
                    title: 'Staf',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffListScreen())),
                  ),
                    _buildGridItem(
                      context,
                      icon: Icons.group_outlined,
                      color: Colors.deepPurple,
                      title: 'Referral',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralManagementScreen())),
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.settings_outlined,
                      color: Colors.orange,
                      title: 'Pengaturan',
                      onTap: () => _showSettingsBottomSheet(context),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengaturan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.store_outlined, color: Colors.teal),
                    title: const Text('Info Toko'),
                    subtitle: const Text('Ubah profil dan informasi toko'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditStoreScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined, color: Colors.pink),
                    title: const Text('Tema'),
                    subtitle: const Text('Ubah warna tema aplikasi'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: Colors.orange),
                    title: const Text('Keamanan'),
                    subtitle: const Text('Ubah PIN keamanan transaksi'),
                    onTap: () {
                      Navigator.pop(context);
                      _showPinUpdateDialog(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.print_outlined, color: Colors.blue),
                    title: const Text('Koneksi Printer'),
                    subtitle: const Text('Hubungkan printer bluetooth untuk cetak struk'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.cloud_sync, color: Colors.blue),
                        title: const Text('Sinkronisasi Cloud'),
                        subtitle: Text(
                          auth.cloudSyncEnabled 
                              ? 'Otomatis aktif (Tiap 30 dtk)' 
                              : 'Nonaktif. Ketuk ikon untuk sync manual.',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: auth.cloudSyncEnabled,
                              onChanged: (bool value) {
                                auth.updateCloudSyncEnabled(value);
                              },
                            ),
                            if (!auth.cloudSyncEnabled)
                              IconButton(
                                icon: const Icon(Icons.sync_outlined, color: Colors.green),
                                tooltip: 'Sync Sekarang',
                                onPressed: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Memulai sinkronisasi data ke cloud...')),
                                  );
                                  try {
                                    await SyncService().uploadLocalChanges();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Sinkronisasi cloud berhasil diselesaikan!')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Sinkronisasi gagal: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridItem(BuildContext context, {required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showPinUpdateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ubah PIN Keamanan'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'PIN Baru',
            hintText: 'Min. 4 digit angka',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.length >= 4) {
                Provider.of<AuthProvider>(context, listen: false).updatePin(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN berhasil diperbarui')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN minimal 4 digit')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
