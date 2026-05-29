import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/register_screen.dart';
import 'package:mobile/screens/purchase_license_screen.dart';
import 'package:mobile/screens/connect_device_screen.dart';
import 'package:mobile/widgets/auth_form_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();

  void _login() async {
    final pin = _pinController.text;
    final success =
        await Provider.of<AuthProvider>(context, listen: false).login(pin);
    if (!success && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PIN Salah')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // ── Unregistered: Show onboarding options ──
    if (!auth.isRegistered) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: Stack(
          children: [
            // Subtle gradient accent at the top
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.indigo.withOpacity(0.12),
                      Colors.indigo.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: -100,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.blue.withOpacity(0.08),
                      Colors.blue.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Main content
            AuthFormCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo icon with soft background
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.store_rounded,
                        size: 44, color: Color(0xFF3F51B5)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Selamat Datang',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'di Cashiro',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3F51B5),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Kasir Pintar Offline & Sinkronisasi Online',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Purchase License ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PurchaseLicenseScreen()),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_rounded, size: 20),
                      label: const Text('Beli Lisensi Baru',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F51B5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Register Store ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        );
                      },
                      icon: const Icon(Icons.add_business_rounded, size: 20),
                      label: const Text('Daftar & Aktifkan Lisensi',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3F51B5),
                        side: BorderSide(
                            color: Colors.indigo.withOpacity(0.3), width: 1.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Connect Existing Device ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ConnectDeviceScreen()),
                        );
                      },
                      icon: const Icon(Icons.sync_rounded, size: 20),
                      label: const Text('Hubungkan Device (Login)',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Registered: PIN entry screen ──
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          // Subtle gradient accent
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.indigo.withOpacity(0.10),
                    Colors.indigo.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          AuthFormCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Store avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      size: 36, color: Color(0xFF3F51B5)),
                ),
                const SizedBox(height: 20),
                Text(
                  auth.storeInfo['storeName'] ?? 'Toko',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan PIN untuk masuk',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _pinController,
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    labelStyle: TextStyle(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFF3F51B5), width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.lock_outline_rounded,
                        color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F51B5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Masuk',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                  ),
                  child: const Text('Reset / Daftar Baru',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
