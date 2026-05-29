import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/withdraw_commission_screen.dart';
import 'package:intl/intl.dart';

class ReferralManagementScreen extends StatefulWidget {
  const ReferralManagementScreen({super.key});

  @override
  State<ReferralManagementScreen> createState() => _ReferralManagementScreenState();
}

class _ReferralManagementScreenState extends State<ReferralManagementScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _error;
  
  double _balance = 0;
  int _referredCount = 0;
  List<dynamic> _referredStores = [];
  List<dynamic> _rewards = [];
  String? _slug;
  String? _licenseKey;

  @override
  void initState() {
    super.initState();
    _fetchReferrals();
  }

  Future<void> _fetchReferrals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final storeId = auth.storeInfo['storeId'] ?? '';
      _licenseKey = auth.storeInfo['licenseKey'] ?? '';

      if (storeId.isEmpty || storeId == 'DEMO-STORE-ID') {
        setState(() {
          _error = 'Fitur referral hanya tersedia untuk akun terdaftar dengan lisensi aktif.';
          _isLoading = false;
        });
        return;
      }

      final actResult = await _api.activateSeller(storeId);
      _slug = actResult['slug'];
      if (_slug == null || _slug!.isEmpty) {
        setState(() {
          _error = 'Tidak dapat mengaktifkan toko. Silakan coba lagi.';
          _isLoading = false;
        });
        return;
      }
      final refResult = await _api.getSellerReferrals(_slug!);
      setState(() {
        _balance = (refResult['balance'] ?? 0).toDouble();
        _referredCount = refResult['referred_count'] ?? 0;
        _referredStores = refResult['referred_stores'] ?? [];
        _rewards = refResult['rewards'] ?? [];
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatRupiah(dynamic n) {
    final double value = n is double ? n : (n is int ? n.toDouble() : double.tryParse(n.toString()) ?? 0.0);
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  void _copyReferralCode() {
    if (_licenseKey != null && _licenseKey!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _licenseKey!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎁 Kode referral disalin! Bagikan ke teman Anda.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Program Affiliate & Referral')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Program Affiliate & Referral')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard, size: 72, color: Colors.grey),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _fetchReferrals,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Affiliate & Referral'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReferrals,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 💳 Bonus Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Color(0xFF1b4332)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Saldo Komisi',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatRupiah(_balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Teman Bergabung: $_referredCount toko',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const WithdrawCommissionScreen()),
                              ).then((_) => _fetchReferrals());
                            },
                            icon: const Icon(Icons.wallet, size: 14),
                            label: const Text('Tarik Komisi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.green.shade900,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🎁 Referral Code Section
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bagikan Kode Referral Anda',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Dapatkan komisi saldo Rp 5.000 setiap ada teman yang mendaftar dan membeli lisensi Cashiro menggunakan kode Anda.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SelectableText(
                                _licenseKey ?? '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: primaryColor,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _copyReferralCode,
                                icon: const Icon(Icons.copy, size: 14),
                                label: const Text('Salin'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 📜 History Tabs
                const Text(
                  'Histori Reward',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (_rewards.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          const Text(
                            'Belum ada bonus rujukan masuk.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _rewards.length,
                    itemBuilder: (context, index) {
                      final reward = _rewards[index];
                      final amount = reward['amount'];
                      final date = reward['created_at'] != null
                          ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(reward['created_at']).toLocal())
                          : '-';
                      final referredName = reward['referred']?['store_name'] ?? 'Toko Baru';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.greenAccent,
                            child: Icon(Icons.arrow_downward, color: Colors.green),
                          ),
                          title: Text(
                            'Bonus Referral - $referredName',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            date,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          trailing: Text(
                            '+ ${_formatRupiah(amount)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
