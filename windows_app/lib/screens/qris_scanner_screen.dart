import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrisScannerScreen extends StatefulWidget {
  const QrisScannerScreen({super.key});

  @override
  State<QrisScannerScreen> createState() => _QrisScannerScreenState();
}

class _QrisScannerScreenState extends State<QrisScannerScreen> {
  final MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QRIS Statis Toko')),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                  // Usually a valid QRIS starts with 000201
                  if (barcode.rawValue!.startsWith("000201")) {
                    controller.stop();
                    Navigator.pop(context, barcode.rawValue);
                    return;
                  }
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              'Arahkan kamera ke stiker QRIS Statis Anda',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, backgroundColor: Colors.black54),
            ),
          )
        ],
      ),
    );
  }
}
