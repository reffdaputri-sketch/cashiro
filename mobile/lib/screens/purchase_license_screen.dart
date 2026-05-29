import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/screens/register_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PurchaseLicenseScreen extends StatefulWidget {
  const PurchaseLicenseScreen({super.key});

  @override
  State<PurchaseLicenseScreen> createState() => _PurchaseLicenseScreenState();
}

class _PurchaseLicenseScreenState extends State<PurchaseLicenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  String? _generatedLicense;
  String? _paymentUrl;
  String? _orderId;

  Future<void> _inquiryPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _generatedLicense = null;
      _paymentUrl = null;
      _orderId = null;
    });

    try {
      // 1. Inquiry payment from Next.js server proxying Duitku
      final result = await _apiService.buyLicense(
        _emailController.text.trim(),
        _storeNameController.text.trim(),
      );

      setState(() {
        _paymentUrl = result['payment_url'];
        _orderId = result['order_id'];
      });

      // Launch WebView directly
      if (mounted && _paymentUrl != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DuitkuWebViewScreen(
              paymentUrl: _paymentUrl!,
              returnUrl: 'https://cashiro.vercel.app/payment-success',
              onPaymentSuccess: () {
                _checkGeneratedLicense();
              },
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  // Fetches the newly generated license key from the server API securely
  Future<void> _checkGeneratedLicense() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final key = await _apiService.checkLicenseStatus(_emailController.text.trim());
      if (key != null) {
        setState(() {
          _generatedLicense = key;
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Pembayaran Berhasil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lisensi baru Anda telah terbit:'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SelectableText(
                          key,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: key));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lisensi disalin!')),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Selesai'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('Pembayaran belum diterima / lisensi belum diterbitkan.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembelian Lisensi Cashiro'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.verified_user, size: 60, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Mulai Bisnis Anda Bersama Cashiro',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masukkan email aktif dan nama toko Anda. Kami bekerja sama dengan Duitku untuk pembayaran otomatis.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Store Name
                    TextFormField(
                      controller: _storeNameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Toko',
                        prefixIcon: const Icon(Icons.store),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Nama toko wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Alamat Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Email wajib diisi';
                        if (!val.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Buy button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _inquiryPayment,
                        child: const Text('Beli Lisensi (Duitku Rp 25.000)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_generatedLicense != null) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RegisterScreen(
                                  prefilledLicenseKey: _generatedLicense,
                                  prefilledEmail: _emailController.text.trim(),
                                  prefilledStoreName: _storeNameController.text.trim(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_business),
                          label: const Text(
                            'Lanjutkan ke Pendaftaran',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Lisensi Aktif Anda:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SelectableText(
                        _generatedLicense!,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

class DuitkuWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String returnUrl;
  final VoidCallback onPaymentSuccess;

  const DuitkuWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.returnUrl,
    required this.onPaymentSuccess,
  });

  @override
  State<DuitkuWebViewScreen> createState() => _DuitkuWebViewScreenState();
}

class _DuitkuWebViewScreenState extends State<DuitkuWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            debugPrint('Loaded URL: $url');
            // If the user lands on the success returnUrl, trigger success callback and exit
            if (url.startsWith(widget.returnUrl) || url.contains('/payment-success')) {
              widget.onPaymentSuccess();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pembayaran Berhasil Dideteksi!')),
              );
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigating to: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Duitku'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
