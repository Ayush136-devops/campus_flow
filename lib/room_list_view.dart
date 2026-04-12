import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoomListView extends StatelessWidget {
  final String buildingName;
  final int floor;
  final Color color;

  const RoomListView({
    super.key,
    required this.buildingName,
    required this.floor,
    required this.color
  });

  String _getCurrentTimeColumn() {
    final now = DateTime.now();
    final days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    final dayName = days[now.weekday - 1];
    final hourString = "${now.hour.toString().padLeft(2, '0')}:00";
    return "${dayName}_$hourString";
  }

  String nextHour() {
    final next = DateTime.now().hour + 1;
    return "${next.toString().padLeft(2, '0')}:00";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Logic for College Hours: 8 AM (8) to 6 PM (18)
    final bool isClosed = now.hour < 8 || now.hour >= 18;
    final String timeColumn = _getCurrentTimeColumn();
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: Text("$buildingName - Floor $floor"),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: supabase
            .from('timetables')
            .select()
            .eq('Building', buildingName)
            .eq('Floor', floor)
            .order('RoomID', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final List<dynamic> rooms = snapshot.data as List<dynamic>;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final String roomID = room['RoomID'] ?? "Unknown";
              final String roomType = room['Type'] ?? "Classroom"; // Grabbed from dataset
              final String subjectName = room[timeColumn] ?? "Empty";

              String statusText;
              Color statusColor;
              IconData statusIcon = Icons.meeting_room;

              // Priority Logic: 1. Staffroom, 2. Closed, 3. Occupied, 4. Available
              if (roomType == "Staffroom") {
                statusText = "Staffroom - Restricted Access";
                statusColor = Colors.grey;
                statusIcon = Icons.lock;
              } else if (isClosed) {
                statusText = "College Closed (Opens at 8 AM)";
                statusColor = Colors.blueGrey;
                statusIcon = Icons.bedtime;
              } else if (subjectName != "Empty" && subjectName != "RESERVED") {
                statusText = "Ongoing: $subjectName";
                statusColor = Colors.red;
              } else {
                statusText = "Available Now";
                statusColor = Colors.green;
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    // Using withValues to avoid the deprecation warning
                    backgroundColor: statusColor.withValues(alpha: 0.2),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  title: Text("Room $roomID", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📍 Room Type: $roomType", style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          if (!isClosed && roomType != "Staffroom") ...[
                            Text(
                              "⏳ Session ends at: ${nextHour()}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                          if (roomType == "Staffroom")
                            const Text("This is a faculty-only zone. No classes scheduled here."),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}