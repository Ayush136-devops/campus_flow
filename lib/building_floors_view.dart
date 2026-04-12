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
      appBar: AppBar(
        title: Text("$buildingName: Floors"),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          int floorNum = 4 - index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: OpenContainer(
              transitionDuration: const Duration(milliseconds: 600),
              closedElevation: 0,
              closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              closedBuilder: (context, action) => Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Floor $floorNum", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor)),
                    const Icon(Icons.layers),
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
    );
  }
}