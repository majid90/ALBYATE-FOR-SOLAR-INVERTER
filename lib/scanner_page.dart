import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool done = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan serial barcode')),
      body: Stack(children: [
        MobileScanner(onDetect: (capture) {
          if (done) return;
          final codes = capture.barcodes;
          for (final code in codes) {
            final value = code.rawValue;
            if (value != null && value.trim().isNotEmpty) {
              done = true;
              Navigator.of(context).pop(value.trim());
              break;
            }
          }
        }),
        Align(alignment: Alignment.center, child: Container(width: 290, height: 150, decoration: BoxDecoration(border: Border.all(color: Colors.pinkAccent, width: 3), borderRadius: BorderRadius.circular(16)))),
        const Align(alignment: Alignment.bottomCenter, child: Padding(padding: EdgeInsets.all(24), child: Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Place the barcode inside the frame'))))),
      ]),
    );
  }
}
