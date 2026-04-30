import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoaded = true);
      }
    });
  }

  // format email handles into Full Names
  String _formatDisplayName(String email) {
    if (email == 'Guest') return 'Guest';

    String handle = email.split('@')[0];
    String cleanHandle = handle.replaceAll(RegExp(r'\d'), '');

    return cleanHandle.split('.').map((str) {
      if (str.isEmpty) return "";
      return str[0].toUpperCase() + str.substring(1).toLowerCase();
    }).join(' ');
  }

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

                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoomListView(
                      buildingName: parts[0],
                      floor: int.parse(parts[1]),
                      color: Colors.indigo,
                    ),
                  ),
                );
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

    final userEmail = supabase.auth.currentUser?.email ?? 'Guest';

    final displayName = _formatDisplayName(userEmail);

    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.qr_code_scanner,
            color: Colors.white,
          ),
          onPressed: _openQRScanner,
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: () async {
              await supabase.auth.signOut();

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginView(),
                  ),
                );
              }
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              bottom: 30,
              left: 20,
              right: 20,
              top: 10,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CAMPUS FLOW",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Welcome, $displayName",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(20),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildingCard("Building 1", Icons.business, Colors.blue),
                _buildingCard("Building 2", Icons.apartment, Colors.orange),
                _buildingCard("Building 3", Icons.corporate_fare, Colors.green),
                _buildingCard("Building 4", Icons.foundation, Colors.purple),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchView(),
            ),
          );
        },
        label: const Text("Find Any Room"),
        icon: const Icon(Icons.search),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildingCard(String name, IconData icon, Color color) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 600),
      closedElevation: 2,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      closedBuilder: (context, action) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      openBuilder: (context, action) => BuildingFloorsView(
        buildingName: name,
        themeColor: color,
      ),
    );
  }
}