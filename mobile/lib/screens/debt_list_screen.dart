import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/debt_provider.dart';
import 'package:intl/intl.dart';

class DebtListScreen extends StatefulWidget {
  final bool showAppBar;
  const DebtListScreen({super.key, this.showAppBar = true});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<DebtProvider>(context, listen: false).fetchDebtCustomers());
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Manajemen Hutang'),
      ) : null,
      body: Consumer<DebtProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredCustomers = provider.debtCustomers.where((c) {
            final name = (c['name'] as String).toLowerCase();
            return name.contains(_searchQuery.toLowerCase());
          }).toList();

          final double totalOutstanding = provider.debtCustomers.fold(
              0.0,
              (sum, item) =>
                  sum + ((item['total_debt'] as num?)?.toDouble() ?? 0.0));

          return Column(
            children: [
              // Total debt card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[400]!, Colors.red[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Piutang Belum Terbayar',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormatter.format(totalOutstanding),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari nama pelanggan...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Customers List
              Expanded(
                child: filteredCustomers.isEmpty
                    ? const Center(child: Text('Tidak ada data piutang.'))
                    : ListView.builder(
                        itemCount: filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          final name = customer['name'] as String;
                          final phone = customer['phone'] as String;
                          final double debt =
                              (customer['total_debt'] as num).toDouble();

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFEBEE),
                                child: Icon(Icons.person, color: Colors.red),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Telp: $phone'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormatter.format(debt),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Text(
                                    'Belum Lunas',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CustomerDebtDetailScreen(
                                      customerId: customer['id'] as int,
                                      customerName: name,
                                    ),
                                  ),
                                ).then((_) {
                                  // Refresh data after returning
                                  provider.fetchDebtCustomers();
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}



class CustomerDebtDetailScreen extends StatefulWidget {
  final int customerId;
  final String customerName;

  const CustomerDebtDetailScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerDebtDetailScreen> createState() =>
      _CustomerDebtDetailScreenState();
}

class _CustomerDebtDetailScreenState extends State<CustomerDebtDetailScreen> {
  List<Map<String, dynamic>> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() {
      _isLoading = true;
    });
    final debts = await Provider.of<DebtProvider>(context, listen: false)
        .getCustomerDebts(widget.customerId);
    setState(() {
      _debts = debts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('Hutang: ${widget.customerName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debts.isEmpty
              ? const Center(child: Text('Semua hutang telah dilunasi!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _debts.length,
                  itemBuilder: (context, index) {
                    final debt = _debts[index];
                    final double total = (debt['total_amount'] as num).toDouble();
                    final double paid = (debt['paid_amount'] as num).toDouble();
                    final double remaining =
                        (debt['remaining_debt'] as num).toDouble();
                    final DateTime date = DateTime.parse(debt['created_at'] as String);
                    final transactionId = debt['id'] as int;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Transaksi #${debt['id']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  dateFormatter.format(date),
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoRow('Total Transaksi',
                                currencyFormatter.format(total)),
                            _buildInfoRow(
                                'Sudah Dibayar', currencyFormatter.format(paid)),
                            _buildInfoRow('Sisa Hutang',
                                currencyFormatter.format(remaining),
                                valueColor: Colors.red, isBold: true),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () =>
                                      _showHistoryDialog(transactionId),
                                  child: const Text('Riwayat Bayar'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _showPaymentDialog(
                                      transactionId, remaining),
                                  child: const Text('Bayar Cicilan'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(int transactionId) async {
    final history = await Provider.of<DebtProvider>(context, listen: false)
        .getDebtPaymentsHistory(transactionId);
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Riwayat Pembayaran'),
          content: history.isEmpty
              ? const Text('Belum ada pembayaran cicilan.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final double amount = (item['amount'] as num).toDouble();
                      final DateTime date = DateTime.parse(item['date'] as String);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(currencyFormatter.format(amount),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(dateFormatter.format(date)),
                        leading: const Icon(Icons.check_circle,
                            color: Colors.green),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDialog(int transactionId, double maxAmount) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pembayaran Hutang'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sisa Hutang: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(maxAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Pembayaran',
                    prefixText: 'Rp ',
                  ),
                  autofocus: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    final amt = double.tryParse(v);
                    if (amt == null || amt <= 0) return 'Jumlah tidak valid';
                    if (amt > maxAmount) {
                      return 'Pembayaran melebihi sisa hutang';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(controller.text);
                  await Provider.of<DebtProvider>(context, listen: false)
                      .payDebt(transactionId, amount);
                  Navigator.pop(context);
                  _loadDebts();
                }
              },
              child: const Text('Bayar'),
            ),
          ],
        );
      },
    );
  }
}
