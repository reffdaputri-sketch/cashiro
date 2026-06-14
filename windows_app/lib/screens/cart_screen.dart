import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cashiro/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:cashiro/providers/cart_provider.dart';
import 'package:cashiro/models/cart_item.dart';
import 'package:intl/intl.dart';
import 'package:cashiro/services/receipt_service.dart';
import 'package:cashiro/providers/auth_provider.dart';
import 'package:cashiro/providers/shift_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cashiro/utils/qris_helper.dart';
import 'package:cashiro/services/sync_service.dart';

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
                                      if (item.notes != null && item.notes!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text('Catatan: ${item.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.orange)),
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
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              currencyFormatter.format(item.price),
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.local_offer_outlined, size: 11, color: Colors.blue[600]),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '+ Diskon',
                                                  style: TextStyle(color: Colors.blue[600], fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // ➕ Controls
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.note_alt_outlined, color: Colors.blue, size: 20),
                                      onPressed: () => _showNotesDialog(context, cart, item),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () => cart.removeItem(item),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 32,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
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
                              ],
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
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text('Diskon, Pajak & Biaya Tambahan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                    children: [
                      InkWell(
                        onTap: () => _showDiscountDialog(context, cart),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text('Diskon Transaksi:', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Icon(Icons.edit_note, size: 16, color: Colors.blue[600]),
                                  Text(
                                    cart.discount > 0 ? ' Ubah' : ' + Tambah',
                                    style: TextStyle(color: Colors.blue[600], fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                '- ${currencyFormatter.format(cart.discount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: cart.discount > 0 ? Colors.red : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showTaxDialog(context, cart),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(cart.taxEnabled && cart.manualTax < 0 ? 'Pajak (${cart.taxPercentage.toStringAsFixed(1)}%):' : 'Pajak (PPN):', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Icon(Icons.edit_note, size: 16, color: Colors.blue[600]),
                                  Text(
                                    cart.taxAmount > 0 ? ' Ubah' : ' + Tambah',
                                    style: TextStyle(color: Colors.blue[600], fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                '+ ${currencyFormatter.format(cart.taxAmount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: cart.taxAmount > 0 ? Colors.orange[700] : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showOtherFeeDialog(context, cart),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(cart.serviceChargeEnabled && cart.manualOtherFee < 0 ? 'Biaya Lainnya (${cart.serviceChargePercentage.toStringAsFixed(1)}%):' : 'Biaya Lainnya:', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Icon(Icons.edit_note, size: 16, color: Colors.blue[600]),
                                  Text(
                                    cart.serviceChargeAmount > 0 ? ' Ubah' : ' + Tambah',
                                    style: TextStyle(color: Colors.blue[600], fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                '+ ${currencyFormatter.format(cart.serviceChargeAmount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: cart.serviceChargeAmount > 0 ? Colors.orange[700] : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]
                  ),
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
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: cart.items.isEmpty ? null : () => cart.clearCart(),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Batal'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (Provider.of<AuthProvider>(context).isFnbMode) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: ElevatedButton.icon(
                          onPressed: cart.items.isEmpty ? null : () async {
                             final auth = Provider.of<AuthProvider>(context, listen: false);
                             final shiftId = Provider.of<ShiftProvider>(context, listen: false).activeShift?['id'] as int?;
                             final cashierName = auth.currentStaff?.name ?? auth.storeInfo['ownerName'] ?? 'Kasir';
                             final tId = await cart.saveDraftOrder(shiftId: shiftId, cashierName: cashierName, taxPercentage: cart.appliedTaxPercentage);
                             if (tId != null && context.mounted) {
                                SyncService().uploadLocalChanges();
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan dikirim ke dapur / disimpan!'), backgroundColor: Colors.green));
                                if (!widget.isEmbedded) Navigator.pop(context);
                             }
                          },
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Simpan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: cart.items.isEmpty ? null : () => _showPaymentSelection(context, cart),
                        icon: const Icon(Icons.credit_card, size: 18),
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
                const SizedBox(height: 24),
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

  Future<void> _showTaxDialog(BuildContext context, CartProvider cart) async {
    final controller = TextEditingController(text: cart.manualTax >= 0 ? (cart.manualTax == cart.manualTax.toInt() ? cart.manualTax.toInt().toString() : cart.manualTax.toString()) : '');
    bool isPercent = cart.manualTaxIsPercent;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Atur Pajak (PPN)'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Rp'),
                        value: false,
                        groupValue: isPercent,
                        onChanged: (val) => setState(() => isPercent = val!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('%'),
                        value: true,
                        groupValue: isPercent,
                        onChanged: (val) => setState(() => isPercent = val!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Jumlah Pajak'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(controller.text);
                  if (val != null) {
                    cart.setManualTax(val, isPercent: isPercent);
                  } else if (controller.text.isEmpty) {
                    cart.setManualTax(-1.0, isPercent: false);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _showOtherFeeDialog(BuildContext context, CartProvider cart) async {
    final controller = TextEditingController(text: cart.manualOtherFee >= 0 ? (cart.manualOtherFee == cart.manualOtherFee.toInt() ? cart.manualOtherFee.toInt().toString() : cart.manualOtherFee.toString()) : '');
    bool isPercent = cart.manualOtherFeeIsPercent;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Atur Biaya Lainnya'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Rp'),
                        value: false,
                        groupValue: isPercent,
                        onChanged: (val) => setState(() => isPercent = val!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('%'),
                        value: true,
                        groupValue: isPercent,
                        onChanged: (val) => setState(() => isPercent = val!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Jumlah Biaya'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(controller.text);
                  if (val != null) {
                    cart.setManualOtherFee(val, isPercent: isPercent);
                  } else if (controller.text.isEmpty) {
                    cart.setManualOtherFee(-1.0, isPercent: false);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _showNotesDialog(BuildContext context, CartProvider cart, CartItem item) async {
    final controller = TextEditingController(text: item.notes ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catatan Dapur'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Misal: Pedas, Tanpa Sayur',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              cart.setItemNotes(item, controller.text);
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
    bool sendToKitchen = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setState) => Container(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
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
            
            if (Provider.of<AuthProvider>(context, listen: false).isFnbMode)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SwitchListTile(
                  title: const Text('Kirim ke Dapur', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Tandai pesanan untuk masuk ke dapur'),
                  value: sendToKitchen,
                  onChanged: (val) {
                    setState(() => sendToKitchen = val);
                  },
                ),
              ),
            
            _buildPaymentOption(context, 'Tunai', Icons.money, cart, sendToKitchen),
            _buildPaymentOption(context, 'QRIS', Icons.qr_code_scanner, cart, sendToKitchen),
            _buildPaymentOption(context, 'E-Wallet (Dana, OVO, dll)', Icons.account_balance_wallet, cart, sendToKitchen),
            _buildPaymentOption(context, 'Hutang / Tempo', Icons.history, cart, sendToKitchen),
            
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
      ),
      ),
    );
  }

  Widget _buildPaymentOption(BuildContext sheetContext, String label, IconData icon, CartProvider cart, bool sendToKitchen) {
    final primaryColor = Theme.of(this.context).primaryColor;
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
          if (label == 'Hutang / Tempo') {
            if (_nameController.text.trim().isEmpty) {
               ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Nama Pelanggan wajib diisi untuk Hutang/Tempo!'), backgroundColor: Colors.red));
               return; // Don't close bottom sheet, force user to type name
            }
            Navigator.pop(sheetContext);
            await _processPayment(this.context, cart, 0, label, sendToKitchen);
          } else if (label == 'QRIS') {
            final auth = Provider.of<AuthProvider>(this.context, listen: false);
            final qrisPayload = auth.storeInfo['qrisPayload'];
            if (qrisPayload != null && qrisPayload.isNotEmpty) {
              Navigator.pop(sheetContext);
              await _showQrisDialog(this.context, cart, qrisPayload, sendToKitchen);
            } else {
              Navigator.pop(sheetContext);
              await _processPayment(this.context, cart, cart.totalAmount, label, sendToKitchen);
            }
          } else {
            Navigator.pop(sheetContext); // Close selection
            if (label == 'Tunai') {
              await _showCheckoutDialog(this.context, cart, initialSendToKitchen: sendToKitchen);
            } else {
              // For non-cash, assume paid in full
              await _processPayment(this.context, cart, cart.totalAmount, label, sendToKitchen);
            }
          }
        },
      ),
    );
  }

  Future<void> _showQrisDialog(BuildContext context, CartProvider cart, String staticQris, bool sendToKitchen) async {
    final dynamicQris = QrisHelper.generateDynamicQris(staticQris, cart.totalAmount);
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Scan QRIS untuk Membayar', textAlign: TextAlign.center),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  width: 250,
                  height: 250,
                  alignment: Alignment.center,
                  child: QrImageView(
                    data: dynamicQris,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    errorStateBuilder: (cxt, err) => const Center(
                      child: Text('Gagal menampilkan QRIS', textAlign: TextAlign.center),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(cart.totalAmount),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Minta pelanggan scan QRIS ini dengan aplikasi E-Wallet atau M-Banking mereka.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _processPayment(context, cart, cart.totalAmount, 'QRIS', sendToKitchen);
            },
            child: const Text('Sudah Dibayar'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, CartProvider cart, double paidAmount, String method, bool sendToKitchen) async {
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
        'price': e.price,
        'discount': e.discount,
        'total': e.total,
      }).toList();
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final storeInfo = auth.storeInfo;
      final total = cart.totalAmount;
      final tax = cart.taxAmount;
      final svc = cart.serviceChargeAmount;
      final taxPct = cart.appliedTaxPercentage;
      final cashierName = auth.currentStaff?.name ?? storeInfo['ownerName'] ?? 'Kasir';

      final shiftId = Provider.of<ShiftProvider>(context, listen: false).activeShift?['id'] as int?;
      final transactionId = await cart.checkout(paidAmount, customerId: customerId, paymentMethod: method, shiftId: shiftId, cashierName: cashierName, taxPercentage: taxPct, sendToKitchen: sendToKitchen);
      if (context.mounted && transactionId != null) {
        SyncService().uploadLocalChanges();
        if (method == 'Belum Bayar') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan berhasil disimpan (Belum Bayar)!'), backgroundColor: Colors.orange));
          if (!widget.isEmbedded) Navigator.pop(context);
        } else {
          // Show success / receipt flow
          _showReceiptDialog(context, transactionId, total, paidAmount, paidAmount - total, items, storeInfo, paymentMethod: method, taxAmount: tax, serviceChargeAmount: svc, taxPercentage: taxPct, cashierName: cashierName);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }


  Future<void> _showCheckoutDialog(BuildContext context, CartProvider cart, {bool initialSendToKitchen = false}) async {
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

    bool sendToKitchen = initialSendToKitchen;

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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          paidController.text = cart.totalAmount.toInt().toString();
                          setState(() {});
                        },
                        icon: const Icon(Icons.money),
                        label: const Text('Uang Pas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[50],
                          foregroundColor: Colors.green[700],
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [5000, 10000, 20000, 50000, 100000].map((nominal) => ActionChip(
                        label: Text('Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(nominal)}'),
                        onPressed: () {
                          paidController.text = nominal.toString();
                          setState(() {});
                        },
                      )).toList(),
                    ),
                    const SizedBox(height: 10),
                    buildNumericKeyboard(setState),
                    const SizedBox(height: 10),
                    if (Provider.of<AuthProvider>(context, listen: false).isFnbMode)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SwitchListTile(
                          title: const Text('Kirim ke Dapur', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Tandai pesanan untuk masuk ke dapur'),
                          value: sendToKitchen,
                          onChanged: (val) {
                            setState(() => sendToKitchen = val);
                          },
                        ),
                      ),
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
                    final tax = cart.taxAmount;
                    final svc = cart.serviceChargeAmount;
                    final taxPct = cart.appliedTaxPercentage;
                    final cashierName = auth.currentStaff?.name ?? storeInfo['ownerName'] ?? 'Kasir';

                    // Process Checkout
                    final shiftId = Provider.of<ShiftProvider>(context, listen: false).activeShift?['id'] as int?;
                    final transactionId = await cart.checkout(paid, customerId: customerId, paymentMethod: 'Tunai', shiftId: shiftId, cashierName: cashierName, taxPercentage: taxPct, sendToKitchen: sendToKitchen);
                    
                    if (ctx.mounted) {
                      Navigator.pop(ctx); 
                      
                      if (transactionId != null) {
                        SyncService().uploadLocalChanges();
                        _showReceiptDialog(context, transactionId, total, paid, kembalian, items, storeInfo, taxAmount: tax, serviceChargeAmount: svc, taxPercentage: taxPct, cashierName: cashierName);
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

  void _showReceiptDialog(BuildContext context, int transactionId, double total, double paid, double kembalian, List<Map<String, dynamic>> items, Map<String, dynamic> storeInfo, {String paymentMethod = 'Tunai', double taxAmount = 0.0, double serviceChargeAmount = 0.0, double? taxPercentage, String? cashierName}) {
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
              if (kembalian < 0)
                Text('Sisa Tagihan (Hutang): Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(kembalian.abs())}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
              else
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
                  taxAmount: taxAmount,
                  serviceChargeAmount: serviceChargeAmount,
                  taxPercentage: taxPercentage,
                  cashierName: cashierName,
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
                  taxAmount: taxAmount,
                  serviceChargeAmount: serviceChargeAmount,
                  taxPercentage: taxPercentage,
                  cashierName: cashierName,
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
