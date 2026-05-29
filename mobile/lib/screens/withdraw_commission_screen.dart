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
  final _formKey = GlobalKey<FormState>();

  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankAccountNameController = TextEditingController();

  double? _commissionBalance;
  List<dynamic> _history = [];
  bool _isLoading = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchCommissionBalance();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankAccountNameController.dispose();
    super.dispose();
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
          final sellerDetails = await _api.getSellerInfo(slug);
          final seller = sellerDetails['seller'] ?? {};
          final history = await _api.getReferralWithdrawalHistory(slug);

          if (mounted) {
            setState(() {
              _commissionBalance = (refResult['balance'] ?? 0).toDouble();
              _history = history;
              _bankNameController.text = seller['bank_name'] ?? '';
              _bankAccountController.text = seller['bank_account'] ?? '';
              _bankAccountNameController.text = seller['bank_account_name'] ?? '';
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

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

      await _api.withdrawCommission(
        slug: slug,
        amount: _commissionBalance!,
        bankName: _bankNameController.text.trim(),
        bankAccount: _bankAccountController.text.trim(),
        bankAccountName: _bankAccountNameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penarikan komisi berhasil diajukan')),
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

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'approved':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = 'Disetujui';
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = 'Ditolak';
        break;
      default:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, py: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penarikan Komisi Referral'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Saldo Komisi
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [Colors.green.shade600, Colors.green.shade400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Saldo Komisi Anda',
                              style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                                  .format(_commissionBalance ?? 0),
                              style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '* Minimum penarikan adalah Rp 50.000',
                              style: TextStyle(fontSize: 11, color: Colors.white60, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Formulir Informasi Rekening Bank
                    const Text(
                      'Informasi Rekening Tujuan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _bankNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Bank (misal: BCA, Mandiri, BRI)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.account_balance),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nama Bank wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bankAccountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Nomor Rekening',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.credit_card),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nomor rekening wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bankAccountNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Pemilik Rekening (Atas Nama)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nama pemilik rekening wajib diisi';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _withdraw,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Tarik Komisi Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Riwayat Penarikan
                    const Text(
                      'Riwayat Penarikan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _history.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.history, color: Colors.grey.shade400, size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada riwayat penarikan',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _history.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _history[index];
                              final amount = double.tryParse(item['amount'].toString()) ?? 0.0;
                              final dateStr = item['created_at'] != null
                                  ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(item['created_at']))
                                  : '-';
                              final status = item['status'] ?? 'pending';
                              final note = item['note'];

                              return Card(
                                margin: EdgeInsets.zero,
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.between,
                                        children: [
                                          Text(
                                            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                                                .format(amount),
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          _buildStatusBadge(status),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.between,
                                        children: [
                                          Text(
                                            dateStr,
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                          ),
                                          if (note != null && note.toString().isNotEmpty)
                                            Expanded(
                                              child: Text(
                                                'Catatan: $note',
                                                textAlign: TextAlign.end,
                                                style: TextStyle(color: Colors.red.shade600, fontSize: 11, fontStyle: FontStyle.italic),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
