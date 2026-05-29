import 'package:flutter/material.dart';
import 'package:mobile/services/report_service.dart';
import 'package:mobile/services/report_export_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportScreen extends StatefulWidget {
  final int initialTabIndex;
  const ReportScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();
  final _currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan & Penjualan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Ekspor Laporan',
            onPressed: () => _showExportDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // Selected text color
          unselectedLabelColor: Colors.white70, // Unselected text color
          indicatorColor: Colors.white, // Underline color
          tabs: const [
            Tab(text: 'Laba Rugi'),
            Tab(text: 'Terlaris'),
            Tab(text: 'Metode Bayar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfitLossReport(),
          _buildBestSellersReport(),
          _buildPaymentMethodsReport(),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    String selectedPeriod = 'Rentang Aktif';
    String selectedFormat = 'PDF';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ekspor Laporan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Periode Laporan:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedPeriod,
                    items: const [
                      DropdownMenuItem(value: 'Hari Ini', child: Text('Hari Ini')),
                      DropdownMenuItem(value: 'Bulan Ini', child: Text('Bulan Ini')),
                      DropdownMenuItem(value: 'Tahun Ini', child: Text('Tahun Ini')),
                      DropdownMenuItem(value: 'Rentang Aktif', child: Text('Rentang Filter Aktif')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedPeriod = val;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilih Format Berkas:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('PDF'),
                          value: 'PDF',
                          groupValue: selectedFormat,
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedFormat = val;
                              });
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Excel'),
                          value: 'Excel',
                          groupValue: selectedFormat,
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedFormat = val;
                              });
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close selection dialog
                    
                    // Show progress dialog
                    BuildContext? progressCtx;
                    showDialog(
                      context: this.context,
                      barrierDismissible: false,
                      builder: (ctx) {
                        progressCtx = ctx;
                        return const Center(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Membuat berkas laporan...'),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );

                    try {
                      final now = DateTime.now();
                      DateTime start;
                      DateTime end;

                      switch (selectedPeriod) {
                        case 'Hari Ini':
                          start = DateTime(now.year, now.month, now.day);
                          end = DateTime(now.year, now.month, now.day, 23, 59, 59);
                          break;
                        case 'Bulan Ini':
                          start = DateTime(now.year, now.month, 1);
                          end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                          break;
                        case 'Tahun Ini':
                          start = DateTime(now.year, 1, 1);
                          end = DateTime(now.year, 12, 31, 23, 59, 59);
                          break;
                        case 'Rentang Aktif':
                        default:
                          start = _startDate;
                          end = _endDate;
                          break;
                      }

                      if (selectedFormat == 'PDF') {
                        await ReportExportService.exportToPdf(start, end, selectedPeriod);
                      } else {
                        await ReportExportService.exportToExcel(start, end, selectedPeriod);
                      }

                      if (progressCtx != null && progressCtx!.mounted) {
                        Navigator.pop(progressCtx!);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Laporan $selectedFormat berhasil diekspor!')),
                        );
                      }
                    } catch (e) {
                      if (progressCtx != null && progressCtx!.mounted) {
                        Navigator.pop(progressCtx!);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal mengekspor laporan: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Ekspor'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProfitLossReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () => _pickDate(true), child: Text(DateFormat('dd/MM/yyyy').format(_startDate)))),
              const SizedBox(width: 8),
              const Text('s/d'),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(onPressed: () => _pickDate(false), child: Text(DateFormat('dd/MM/yyyy').format(_endDate)))),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<Map<String, double>>(
            future: _reportService.getProfitLoss(_startDate, _endDate),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final data = snapshot.data!;
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildRow('Total Penjualan', data['revenue']!, Colors.blue),
                      const SizedBox(height: 12),
                      _buildRow('Total Modal (HPP)', data['cogs']!, Colors.orange),
                      const SizedBox(height: 12),
                      _buildRow('Laba Kotor', data['grossProfit']!, Colors.teal),
                      const SizedBox(height: 12),
                      _buildRow('Pengeluaran', data['expenses']!, Colors.red),
                      const Divider(height: 32),
                      _buildRow('Laba Bersih', data['netProfit']!, Colors.green[800]!, isBold: true, fontSize: 20),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Grafik Keuntungan Harian',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDailyProfitChart(),
          const SizedBox(height: 24),
          const Text('*HPP dihitung berdasarkan harga modal saat transaksi terjadi.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDailyProfitChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(8, 24, 24, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportService.getDailyProfitLoss(_startDate, _endDate),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          if (data.isEmpty) return const Center(child: Text('Tidak ada data untuk grafik'));

          return LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        DateTime date = DateTime.parse(data[index]['date']);
                        return Text(DateFormat('dd').format(date), style: const TextStyle(fontSize: 10));
                      }
                      return const Text('');
                    },
                    reservedSize: 22,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value['profit'] as double);
                  }).toList(),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, double value, Color color, {bool isBold = false, double fontSize = 16}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(_currencyFormatter.format(value), style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
      ],
    );
  }

  Widget _buildBestSellersReport() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reportService.getBestSellers(_startDate, _endDate),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        
        if (data.isEmpty) return const Center(child: Text('Belum ada data penjualan.'));

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Proporsi Penjualan Barang',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            _buildBestSellersChart(data),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Daftar Barang Terlaris',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ...data.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getPieColor(index),
                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Terjual: ${item['total_qty']}'),
                trailing: Text(_currencyFormatter.format(item['total_sales']), style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildBestSellersChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final qty = (item['total_qty'] as num).toDouble();
            
            return PieChartSectionData(
              color: _getPieColor(index),
              value: qty,
              title: qty > 0 ? '${qty.toInt()}' : '',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getPieColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildPaymentMethodsReport() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () => _pickDate(true), child: Text(DateFormat('dd/MM/yyyy').format(_startDate)))),
              const SizedBox(width: 8),
              const Text('s/d'),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(onPressed: () => _pickDate(false), child: Text(DateFormat('dd/MM/yyyy').format(_endDate)))),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _reportService.getPaymentMethodsReport(_startDate, _endDate),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Belum ada transaksi pada periode ini.'));
              }

              final data = snapshot.data!;
              final double grandTotal = data.fold(0.0, (sum, item) => sum + ((item['total_amount'] as num?)?.toDouble() ?? 0.0));

              // Find the payment method with the highest transaction count
              String popularMethodName = '-';
              int popularMethodCount = 0;
              if (data.isNotEmpty) {
                final mostUsedMethod = data.reduce((a, b) =>
                    (a['transaction_count'] as int) > (b['transaction_count'] as int) ? a : b);
                popularMethodName = mostUsedMethod['payment_method'] ?? 'Tunai';
                popularMethodCount = mostUsedMethod['transaction_count'] as int;
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text('Total Uang Masuk', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _currencyFormatter.format(grandTotal),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text('Metode Terpopuler', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$popularMethodName (${popularMethodCount}x)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Rincian per Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...data.map((item) {
                    final String method = item['payment_method'] ?? 'Tunai';
                    final int count = item['transaction_count'] as int;
                    final double amount = (item['total_amount'] as num).toDouble();
                    
                    IconData icon;
                    Color color;
                    switch (method.toLowerCase()) {
                      case 'qris':
                        icon = Icons.qr_code_scanner;
                        color = Colors.blue;
                        break;
                      case 'kartu debit':
                      case 'kartu kredit':
                        icon = Icons.credit_card;
                        color = Colors.purple;
                        break;
                      case 'hutang / tempo':
                        icon = Icons.history;
                        color = Colors.orange;
                        break;
                      case 'tunai':
                      default:
                        icon = Icons.money;
                        color = Colors.green;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(method, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$count Transaksi'),
                        trailing: Text(
                          _currencyFormatter.format(amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
