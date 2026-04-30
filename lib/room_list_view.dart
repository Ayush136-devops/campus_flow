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

  // HELPER: Formats "English (om.kharate24@vit.edu)" to "English (Prof. Om Kharate)"
  String _formatDisplaySubject(String sub) {
    if (!sub.contains('@') || !sub.contains('(')) return sub;
    try {
      final parts = sub.split(' (');
      final subjectName = parts[0];

      // 1. Get the handle and remove numbers (e.g., om.kharate24 -> om.kharate)
      String handle = parts[1].split('@')[0].replaceAll(RegExp(r'\d'), '');

      // 2. Capitalize parts and join (e.g., om.kharate -> Om Kharate)
      final formattedName = handle.split('.').map((str) {
        if (str.isEmpty) return "";
        return str[0].toUpperCase() + str.substring(1).toLowerCase();
      }).join(' ');

      // 3. Return with Prof. prefix
      return "$subjectName (Prof. $formattedName)";
    } catch (e) {
      return sub;
    }
  }

  String _getCurrentTimeColumn(int hour) {
    final now = DateTime.now();
    final days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return "${days[now.weekday - 1]}_${hour.toString().padLeft(2, '0')}:00";
  }

  Future<void> _showCancelConfirmation(String roomID, String hour) async {
    final TextEditingController confirmController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Verify Cancellation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("To cancel the lecture in Room $roomID, please type 'CANCEL' to confirm."),
            const SizedBox(height: 15),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Type CANCEL"),
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

  Future<void> _showScheduleForm(String roomID, String hour) async {
    final TextEditingController subjectController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Schedule Extra Lecture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter the subject name for this extra lecture."),
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
            child: const Text("Schedule"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOverride(String roomID, String hour, String status, String subjectName) async {
    final supabase = Supabase.instance.client;
    final String todayDate = DateTime.now().toIso8601String().split('T')[0];
    final String userEmail = supabase.auth.currentUser?.email ?? "Unknown";

    // FORMATTING THE TEACHER NAME FOR THE DATABASE OVERRIDE
    String handle = userEmail.split('@')[0].replaceAll(RegExp(r'\d'), '');
    String formattedName = handle.split('.').map((str) {
      if (str.isEmpty) return "";
      return str[0].toUpperCase() + str.substring(1).toLowerCase();
    }).join(' ');

    final String teacherDisplayName = "Prof. $formattedName";

    try {
      await supabase.from('overrides').upsert({
        'room_id': roomID,
        'override_date': todayDate,
        'override_hour': hour,
        'status': status,
        'subject_name': subjectName,
        'teacher_name': teacherDisplayName,
        'teacher_id': supabase.auth.currentUser!.id
      }, onConflict: 'room_id,override_date,override_hour');
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final String todayDate = DateTime.now().toIso8601String().split('T')[0];
    final int currentHourInt = DateTime.now().hour;
    final String currentHourString = "${currentHourInt.toString().padLeft(2, '0')}:00";
    final String timeSlotRange = "$currentHourString - ${(currentHourInt + 1).toString().padLeft(2, '0')}:00";
    final String timeColumn = _getCurrentTimeColumn(currentHourInt);
    final bool isClosed = currentHourInt < 8 || currentHourInt >= 18;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("${widget.buildingName} - Floor ${widget.floor}"),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
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
          final String userEmail = supabase.auth.currentUser?.email ?? "";

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final String roomID = room['RoomID'];
              final String roomType = room['Type'] ?? "Classroom";
              final override = overrides.cast<Map?>().firstWhere((o) => o?['room_id'] == roomID, orElse: () => null);

              String subject;
              String? teacherName;
              if (override != null) {
                subject = override['status'] == 'RESERVED' ? "${override['subject_name']} (Extra Lecture)" : 'CANCELLED (Empty)';
                teacherName = override['teacher_name'];
              } else {
                subject = (room[timeColumn] ?? "Empty");
              }

              bool isOccupied = subject != "Empty" && !subject.contains("CANCELLED");
              bool canCancel = subject.contains(userEmail) || (override != null && override['teacher_id'] == supabase.auth.currentUser!.id);

              String displaySubject = _formatDisplaySubject(subject);

              Color statusColor = roomType == "Staffroom" ? Colors.grey : (isOccupied ? Colors.red : Colors.green);
              if (isClosed && roomType != "Staffroom") statusColor = Colors.blueGrey;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(roomType == "Staffroom" ? Icons.lock : Icons.meeting_room, color: statusColor),
                  ),
                  title: Text("Room $roomID", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displaySubject, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                      if (teacherName != null) Text("👤 $teacherName", style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
                      Text("🕒 Time: $timeSlotRange", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Type: $roomType | Dept: ${room['Department'] ?? 'General'}", style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 10),
                          if (roomType == "Staffroom") ...[
                            const Divider(),
                            const Text("⚠️ STAFFROOM: Status locked.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ] else if (userRole == 'teacher' && !isClosed) ...[
                            const Divider(),
                            const SizedBox(height: 5),
                            if (isOccupied && !canCancel)
                              const Text("🔒 Only the assigned Professor can cancel this class.",
                                  style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold))
                            else
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