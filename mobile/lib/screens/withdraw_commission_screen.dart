import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/services/api_service.dart';

class WithdrawCommissionScreen extends StatefulWidget {
  const WithdrawCommissionScreen({Key? key}) : super(key: key);

  @override
  State<WithdrawCommissionScreen> createState() => _WithdrawCommissionScreenState();
}

class _WithdrawCommissionScreenState extends State<WithdrawCommissionScreen> {
  final ApiService _api = ApiService();
  double? _commissionBalance;
  bool _isLoading = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchCommissionBalance();
  }

  Future<void> _fetchCommissionBalance() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final storeId = auth.storeInfo['storeId'] ?? '';
      if (storeId.isNotEmpty) {
        final actResult = await _api.activateSeller(storeId);
        final slug = actResult['slug'];
        if (slug != null) {
          final refResult = await _api.getSellerReferrals(slug);
          if (mounted) {
            setState(() {
              _commissionBalance = (refResult['balance'] ?? 0).toDouble();
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ambil saldo komisi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _withdraw() async {
    if (_commissionBalance == null || _commissionBalance! < 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saldo minimal Rp 50.000 untuk penarikan')),
      );
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final storeId = auth.storeInfo['storeId'] ?? '';
      final actResult = await _api.activateSeller(storeId);
      final slug = actResult['slug'];
      await _api.withdrawCommission(slug, _commissionBalance!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penarikan komisi berhasil')),
        );
        _fetchCommissionBalance();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Penarikan gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penarikan Komisi Referral'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Komisi Anda',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                        .format(_commissionBalance ?? 0),
                    style: const TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _withdraw,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Tarik Komisi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
