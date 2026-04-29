import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'room_list_view.dart';

class BuildingFloorsView extends StatelessWidget {
  final String buildingName;
  final Color themeColor;

  const BuildingFloorsView({super.key, required this.buildingName, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(buildingName, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Text(
              "Select Floor",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 4,
              itemBuilder: (context, index) {
                int floorNum = index + 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: OpenContainer(
                    transitionDuration: const Duration(milliseconds: 600),
                    closedElevation: 2,
                    closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    closedBuilder: (context, action) => Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.layers_outlined, color: themeColor, size: 28),
                              const SizedBox(width: 15),
                              Text("Floor $floorNum",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                    openBuilder: (context, action) => RoomListView(
                      buildingName: buildingName,
                      floor: floorNum,
                      color: themeColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}