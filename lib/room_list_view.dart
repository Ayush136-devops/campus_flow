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

  String _getCurrentTimeColumn(int hour) {
    final now = DateTime.now();
    final days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return "${days[now.weekday - 1]}_${hour.toString().padLeft(2, '0')}:00";
  }

  // Double Factor Confirmation Dialog
  Future<void> _showCancelConfirmation(String roomID, String hour) async {
    final TextEditingController confirmController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Cancellation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("To cancel Room $roomID at $hour, type 'CANCEL'."),
            const SizedBox(height: 15),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "CANCEL"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Go Back")),
          ElevatedButton(
            onPressed: () {
              if (confirmController.text.trim().toUpperCase() == "CANCEL") {
                _handleOverride(roomID, hour, 'CANCELLED', 'Empty');
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  // Extra Lecture Form
  Future<void> _showScheduleForm(String roomID, String hour) async {
    final TextEditingController subjectController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Schedule Extra Lecture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Reserving Room $roomID for the $hour slot."),
            const SizedBox(height: 15),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Subject Name"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (subjectController.text.isNotEmpty) {
                _handleOverride(roomID, hour, 'RESERVED', subjectController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Save & Schedule"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOverride(String roomID, String hour, String status, String subjectName) async {
    final supabase = Supabase.instance.client;
    final String todayDate = DateTime.now().toIso8601String().split('T')[0];

    try {
      // Logic: Use upsert to handle both first-time and repeated overrides
      await supabase.from('overrides').upsert({
        'room_id': roomID,
        'override_date': todayDate,
        'override_hour': hour,
        'status': status,
        'subject_name': subjectName,
        'teacher_id': supabase.auth.currentUser!.id
      }, onConflict: 'room_id,override_date,override_hour');

      setState(() {});
    } catch (e) {
      // Error catch for Moto G73 debugging
      print("OVERRIDE ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Action failed. Check permissions or internet."))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final String todayDate = DateTime.now().toIso8601String().split('T')[0];

    // TESTING MODE
    final int currentHourInt = 10;

    final String currentHourString = "${currentHourInt.toString().padLeft(2, '0')}:00";
    final String nextHourString = "${(currentHourInt + 1).toString().padLeft(2, '0')}:00";
    final String timeSlotRange = "$currentHourString - $nextHourString";
    final String timeColumn = _getCurrentTimeColumn(currentHourInt);
    final bool isClosed = currentHourInt < 8 || currentHourInt >= 18;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.buildingName} - Floor ${widget.floor}"),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: Future.wait([
          supabase.from('timetables').select().eq('Building', widget.buildingName).eq('Floor', widget.floor).order('RoomID', ascending: true),
          supabase.from('overrides').select().eq('override_date', todayDate).eq('override_hour', currentHourString),
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

              final override = overrides.cast<Map?>().firstWhere((o) => o?['room_id'] == roomID, orElse: () => null);

              String subject;
              if (override != null) {
                subject = override['status'] == 'RESERVED'
                    ? "${override['subject_name']} (Extra Lecture)"
                    : 'CANCELLED (Empty)';
              } else {
                subject = (room[timeColumn] ?? "Empty");
              }

              bool isOccupied = subject != "Empty" && !subject.contains("CANCELLED");
              Color statusColor = roomType == "Staffroom" ? Colors.grey : (isOccupied ? Colors.red : Colors.green);

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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                      Text("🕒 Time Slot: $timeSlotRange", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (roomType == "Staffroom")
                            const Text("⚠️ Staffroom: Modifications locked.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                          else if (userRole == 'teacher' && !isClosed) ...[
                            SizedBox(
                              width: double.infinity,
                              child: isOccupied
                                  ? ElevatedButton.icon(
                                onPressed: () => _showCancelConfirmation(roomID, currentHourString),
                                icon: const Icon(Icons.cancel),
                                label: const Text("Confirm & Cancel Lecture"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              )
                                  : ElevatedButton.icon(
                                onPressed: () => _showScheduleForm(roomID, currentHourString),
                                icon: const Icon(Icons.add_circle),
                                label: const Text("Schedule Extra Lecture"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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