import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/models/cart_item.dart';
import 'package:intl/intl.dart';
import 'package:mobile/services/receipt_service.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/shift_provider.dart';

class CartScreen extends StatefulWidget {
  final bool isEmbedded;

  const CartScreen({super.key, this.isEmbedded = false});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 🛑 Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Keranjang Belanja',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 🛒 Items List
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text('Keranjang kosong'))
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            // 🖼️ Small Icon/Image
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: (item.product.imagePath != null && item.product.imagePath!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: (item.product.imagePath!.startsWith('http://') || item.product.imagePath!.startsWith('https://')
                                          ? Image.network(
                                              item.product.imagePath!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                                            )
                                          : Image.file(
                                              File(item.product.imagePath!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                                            )),
                                    )
                                  : const Icon(Icons.inventory_2, size: 20, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            // 📝 Info
                            Expanded(
                              child: InkWell(
                                onTap: () => _showItemDiscountDialog(context, cart, item),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.variation != null ? '${item.product.name} (${item.variation!.name})' : item.product.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      if (item.discount > 0) ...[
                                        Row(
                                          children: [
                                            Text(
                                              currencyFormatter.format(item.price),
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              currencyFormatter.format(item.price - item.discount),
                                              style: TextStyle(
                                                color: Theme.of(context).primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Diskon: -${currencyFormatter.format(item.discount)}',
                                          style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w500),
                                        ),
                                      ] else ...[
                                        Text(
                                          currencyFormatter.format(item.price),
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // ➕ Controls
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 14),
                                    onPressed: () => cart.decrementQuantity(item),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32),
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 14),
                                    onPressed: () => cart.incrementQuantity(item),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => cart.removeItem(item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 📊 Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Total Item:', '${cart.items.fold(0, (sum, i) => sum + i.quantity)} item'),
                _buildSummaryRow('Subtotal:', currencyFormatter.format(cart.subtotal)),
                InkWell(
                  onTap: () => _showDiscountDialog(context, cart),
                  child: _buildSummaryRow('Diskon:', '- ${currencyFormatter.format(cart.discount)}', 
                    valueColor: Colors.red),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Harga:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(currencyFormatter.format(cart.totalAmount), 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: cart.items.isEmpty ? null : () => cart.clearCart(),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: cart.items.isEmpty ? null : () => _showPaymentSelection(context, cart),
                        icon: const Icon(Icons.credit_card),
                        label: const Text('Bayar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor)),
        ],
      ),
    );
  }

  Future<void> _showDiscountDialog(BuildContext context, CartProvider cart) async {
    final controller = TextEditingController(text: cart.discount.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atur Diskon'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Jumlah Diskon (Rp)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              cart.setDiscount(double.tryParse(controller.text) ?? 0.0);
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showItemDiscountDialog(BuildContext context, CartProvider cart, CartItem item) async {
    final controller = TextEditingController(text: item.discount == 0.0 ? '' : item.discount.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Atur Diskon - ${item.product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Jumlah Diskon per Item (Rp)',
            hintText: 'Masukkan nominal potongan harga',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final discountVal = double.tryParse(controller.text) ?? 0.0;
              cart.setItemDiscount(item, discountVal);
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSelection(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            
            // 💰 Summary Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50], 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Total Belanja', NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(cart.totalAmount), valueColor: Theme.of(context).primaryColor),
                  _buildSummaryRow('Jumlah Item', '${cart.items.fold(0, (sum, i) => sum + i.quantity)} item'),
                  _buildSummaryRow('Diskon', '- Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(cart.discount)}', valueColor: Colors.red),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            const Text('Informasi Pelanggan (Opsional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Nama Pelanggan',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'No. Telepon',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Pilih Metode Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            _buildPaymentOption(context, 'Tunai', Icons.money, cart),
            _buildPaymentOption(context, 'QRIS', Icons.qr_code_scanner, cart),
            _buildPaymentOption(context, 'Kartu Debit', Icons.credit_card, cart),
            _buildPaymentOption(context, 'Kartu Kredit', Icons.credit_card, cart),
            _buildPaymentOption(context, 'Hutang / Tempo', Icons.history, cart),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, size: 18),
                    SizedBox(width: 8),
                    Text('Kembali ke Keranjang'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(BuildContext context, String label, IconData icon, CartProvider cart) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: primaryColor),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () async {
          Navigator.pop(context); // Close selection
          if (label == 'Tunai') {
            await _showCheckoutDialog(context, cart);
          } else {
            // For non-cash, assume paid in full
            await _processPayment(context, cart, cart.totalAmount, label);
          }
        },
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, CartProvider cart, double paidAmount, String method) async {
    try {
      int? customerId;
      if (_nameController.text.isNotEmpty) {
        final db = await DatabaseService().database;
        customerId = await db.insert('customers', {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Capture Details before checkout clears cart
      final items = cart.items.map((e) => {
        'name': e.variation != null ? '${e.product.name} (${e.variation!.name})' : e.product.name,
        'quantity': e.quantity,
        'total': e.total,
      }).toList();
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final storeInfo = auth.storeInfo;
      final total = cart.totalAmount;

      final shiftId = Provider.of<ShiftProvider>(context, listen: false).activeShift?['id'] as int?;
      final transactionId = await cart.checkout(paidAmount, customerId: customerId, paymentMethod: method, shiftId: shiftId);
      if (context.mounted && transactionId != null) {
        // Show success / receipt flow
        _showReceiptDialog(context, transactionId, total, paidAmount, paidAmount - total, items, storeInfo, paymentMethod: method);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }


  Future<void> _showCheckoutDialog(BuildContext context, CartProvider cart) async {
    final paidController = TextEditingController();
    
    // Custom Numeric Keyboard Widget
    Widget buildNumericKeyboard(StateSetter setState) {
      void onKeyPressed(String val) {
        if (val == 'C') {
          paidController.clear();
        } else if (val == '<') {
          if (paidController.text.isNotEmpty) {
            paidController.text = paidController.text.substring(0, paidController.text.length - 1);
          }
        } else {
          paidController.text += val;
        }
        setState(() {}); // Update dialog state
      }

      return Container(
        height: 250,
        color: Colors.grey[100],
        child: Column(
          children: [
             Expanded(child: Row(
               children: ['1','2','3'].map((e) => Expanded(child: _buildNumBtn(e, onKeyPressed))).toList()
             )),
             Expanded(child: Row(
               children: ['4','5','6'].map((e) => Expanded(child: _buildNumBtn(e, onKeyPressed))).toList()
             )),
             Expanded(child: Row(
               children: ['7','8','9'].map((e) => Expanded(child: _buildNumBtn(e, onKeyPressed))).toList()
             )),
             Expanded(child: Row(
               children: [
                 Expanded(child: _buildNumBtn('C', onKeyPressed, color: Colors.red[100])),
                 Expanded(child: _buildNumBtn('0', onKeyPressed)),
                 Expanded(child: _buildNumBtn('<', onKeyPressed, icon: Icons.backspace)),
               ].toList()
             )),
          ],
        ),
      );
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final paid = double.tryParse(paidController.text) ?? 0;
          final kembalian = paid - cart.totalAmount;
          final primaryColor = Theme.of(context).primaryColor;
          
          return AlertDialog(
            title: const Text('Pembayaran'),
            content: SizedBox(
               width: 400, // Fixed width for tablet consistency
               child: SingleChildScrollView(
                 child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: paidController,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Uang Diterima',
                        filled: true,
                        fillColor: Colors.white,
                        border: const OutlineInputBorder(),
                        errorText: (paid > 0 && paid < cart.totalAmount) ? 'Kurang Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(cart.totalAmount - paid)}' : null,
                      ),
                      keyboardType: TextInputType.none, // Disable system keyboard
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 10),
                    if (paid >= cart.totalAmount)
                       Text('Kembalian: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(kembalian)}',
                        style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    buildNumericKeyboard(setState),
                  ],
                 ),
               ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  if (paid < cart.totalAmount) {
                     ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Uang pembayaran kurang!'), backgroundColor: Colors.red),
                     );
                     return;
                  }

                  try {
                    // Save Customer if needed
                    int? customerId;
                    if (_nameController.text.isNotEmpty) {
                      final db = await DatabaseService().database;
                       // Simple check: insert new customer
                      customerId = await db.insert('customers', {
                        'name': _nameController.text,
                        'phone': _phoneController.text,
                        'created_at': DateTime.now().toIso8601String(),
                      });
                    }

                    // Capture Details
                    final items = cart.items.map((e) => {
                      'name': e.variation != null ? '${e.product.name} (${e.variation!.name})' : e.product.name,
                      'quantity': e.quantity,
                      'price': e.price,
                      'discount': e.discount,
                      'total': e.total,
                    }).toList();
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final storeInfo = auth.storeInfo;
                    final total = cart.totalAmount;

                    // Process Checkout
                    final shiftId = Provider.of<ShiftProvider>(context, listen: false).activeShift?['id'] as int?;
                    final transactionId = await cart.checkout(paid, customerId: customerId, paymentMethod: 'Tunai', shiftId: shiftId);
                    
                    if (ctx.mounted) {
                      Navigator.pop(ctx); 
                      
                      if (transactionId != null) {
                        _showReceiptDialog(context, transactionId, total, paid, kembalian, items, storeInfo);
                      } else {
                         if (!widget.isEmbedded) Navigator.pop(context);
                      }
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Proses Bayar'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildNumBtn(String label, Function(String) onTap, {Color? color, IconData? icon}) {
    return Container(
      margin: const EdgeInsets.all(2),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        onPressed: () => onTap(label),
        child: icon != null ? Icon(icon, size: 20) : Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showReceiptDialog(BuildContext context, int transactionId, double total, double paid, double kembalian, List<Map<String, dynamic>> items, Map<String, dynamic> storeInfo, {String paymentMethod = 'Tunai'}) {
      final primaryColor = Theme.of(context).primaryColor;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Transaksi Berhasil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: primaryColor, size: 60),
              const SizedBox(height: 10),
              Text('Kembalian: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(kembalian)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _nameController.clear(); // Clear customer input
                _phoneController.clear();
                Navigator.pop(context); 
                if (!widget.isEmbedded) {
                  Navigator.pop(context); 
                }
              },
              child: const Text('Tutup'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final receiptService = ReceiptService();
                await receiptService.shareReceipt(
                  storeInfo,
                  transactionId,
                  total,
                  paid,
                  kembalian,
                  items,
                  paymentMethod: paymentMethod,
                );
              },
              icon: const Icon(Icons.share_rounded),
              label: const Text('Bagikan'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final receiptService = ReceiptService();
                await receiptService.printReceipt(
                  storeInfo,
                  transactionId,
                  total,
                  paid,
                  kembalian,
                  items,
                  paymentMethod: paymentMethod,
                );
              },
              icon: const Icon(Icons.print),
              label: const Text('Cetak Struk'),
            ),
          ],
        ),
      );
  }
}
