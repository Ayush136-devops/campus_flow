import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; //
import 'building_floors_view.dart';
import 'room_list_view.dart';
import 'search_view.dart';
import 'login_view.dart';

class CampusHome extends StatefulWidget {
  const CampusHome({super.key});

  @override
  State<CampusHome> createState() => _CampusHomeState();
}

class _CampusHomeState extends State<CampusHome> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isLoaded = true);
    });
  }

  // QR Logic: Parse scanned string like "Building 1,2"
  void _openQRScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String code = barcode.rawValue ?? "";
              if (code.contains(",")) {
                final parts = code.split(",");
                Navigator.pop(context); // Close scanner
                // Navigate directly to the floor
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => RoomListView(
                    buildingName: parts[0],
                    floor: int.parse(parts[1]),
                    color: Colors.indigo,
                  ),
                ));
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          // NEW: QR SCANNER BUTTON
          icon: const Icon(Icons.qr_code_scanner, color: Colors.indigo),
          onPressed: _openQRScanner,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginView()));
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedOpacity(
            opacity: _isLoaded ? 1.0 : 0.0,
            duration: const Duration(seconds: 1),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildingCard("Building 1", Icons.business, Colors.blue)),
                      Expanded(child: _buildingCard("Building 2", Icons.apartment, Colors.orange)),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildingCard("Building 3", Icons.corporate_fare, Colors.green)),
                      Expanded(child: _buildingCard("Building 4", Icons.foundation, Colors.purple)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AnimatedAlign(
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOutBack,
            alignment: _isLoaded ? Alignment.topCenter : Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Text(
                "CAMPUS FLOW",
                style: TextStyle(
                  fontSize: _isLoaded ? 26 : 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: Colors.indigo[900],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _isLoaded ? 1.0 : 0.0,
        duration: const Duration(seconds: 1),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchView()));
          },
          label: const Text("Find Any Room"),
          icon: const Icon(Icons.search),
          backgroundColor: Colors.indigo[900],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildingCard(String name, IconData icon, Color color) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 800),
      openColor: Colors.white,
      closedElevation: 0,
      closedColor: Colors.transparent,
      closedBuilder: (context, action) => Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.1))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 70, color: color),
            const SizedBox(height: 15),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      openBuilder: (context, action) => BuildingFloorsView(buildingName: name, themeColor: color),
    );
  }
}