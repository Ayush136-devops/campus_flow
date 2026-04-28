import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoomListView extends StatefulWidget {
  final String buildingName;
  final int floor;
  final Color color;

  const RoomListView({super.key, required this.buildingName, required this.floor, required this.color});

  @override
  State<RoomListView> createState() => _RoomListViewState();
}

class _RoomListViewState extends State<RoomListView> {
  String _getCurrentTimeColumn() {
    final now = DateTime.now();
    final days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return "${days[now.weekday - 1]}_${now.hour.toString().padLeft(2, '0')}:00";
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final String todayDate = DateTime.now().toIso8601String().split('T')[0];
    final String currentHour = "${DateTime.now().hour.toString().padLeft(2, '0')}:00";
    final String timeColumn = _getCurrentTimeColumn();
    final bool isClosed = DateTime.now().hour < 8 || DateTime.now().hour >= 18;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.buildingName} - Floor ${widget.floor}"),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: Future.wait([
          // FIXED: Explicitly added ascending: true for RoomID sorting
          supabase.from('timetables').select().eq('Building', widget.buildingName).eq('Floor', widget.floor).order('RoomID', ascending: true),
          supabase.from('overrides').select().eq('override_date', todayDate).eq('override_hour', currentHour),
          supabase.from('profiles').select('role').eq('id', supabase.auth.currentUser?.id ?? '').maybeSingle(),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final List rooms = snapshot.data![0];
          final List overrides = snapshot.data![1];
          final String userRole = snapshot.data![2]?['role'] ?? 'student';

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final String roomID = room['RoomID'];
              final String roomType = room['Type'] ?? "Classroom";

              final overrideList = overrides.where((o) => o['room_id'] == roomID).toList();
              final override = overrideList.isNotEmpty ? overrideList.first : null;

              String subject = override != null ? "CANCELLED (Empty)" : (room[timeColumn] ?? "Empty");
              bool isOccupied = subject != "Empty" && !subject.contains("CANCELLED") && subject != "RESERVED";

              Color statusColor = roomType == "Staffroom" ? Colors.grey : (isOccupied ? Colors.red : Colors.green);
              if (isClosed && roomType != "Staffroom") statusColor = Colors.blueGrey;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.2),
                    child: Icon(roomType == "Staffroom" ? Icons.lock : Icons.meeting_room, color: statusColor),
                  ),
                  title: Text("Room $roomID", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      roomType == "Staffroom" ? "Staffroom - Restricted" : (isClosed ? "College Closed" : subject),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📍 Type: $roomType", style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 10),

                          // STAFFROOM PROTECTION: Explicit restriction message
                          if (roomType == "Staffroom") ...[
                            const Divider(),
                            const Text(
                              "⚠️ RESTRICTED ACCESS",
                              style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              "You cannot modify the status of a staffroom.",
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ]
                          else if (userRole == 'teacher' && isOccupied && !isClosed) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await supabase.from('overrides').insert({
                                    'room_id': roomID,
                                    'override_hour': currentHour,
                                    'teacher_id': supabase.auth.currentUser!.id
                                  });
                                  setState(() {});
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Success: Class reported as Cancelled!"))
                                    );
                                  }
                                },
                                icon: const Icon(Icons.edit_notifications),
                                label: const Text("Report Cancellation"),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[50],
                                    foregroundColor: Colors.red
                                ),
                              ),
                            ),
                          ],
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