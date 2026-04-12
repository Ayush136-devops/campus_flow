import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'dart:async';
import 'building_floors_view.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // The Building Grid
          AnimatedOpacity(
            opacity: _isLoaded ? 1.0 : 0.0,
            duration: const Duration(seconds: 1),
            child: Column(
              children: [
                const SizedBox(height: 120),
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
          // The Animating Title
          AnimatedAlign(
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOutBack,
            alignment: _isLoaded ? Alignment.topCenter : Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 60.0),
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
    );
  }

  Widget _buildingCard(String name, IconData icon, Color color) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 800),
      openColor: Colors.white,
      closedElevation: 0,
      closedColor: Colors.transparent,
      closedBuilder: (context, action) => Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.1))),
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