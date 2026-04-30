import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'room_list_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  List _searchResults = [];
  bool _isLoading = false;

  final int testHour = DateTime.now().hour;

  String _getCurrentTimeColumn() {
    final now = DateTime.now();
    final days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return "${days[now.weekday - 1]}_${testHour.toString().padLeft(2, '0')}:00";
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    if (testHour < 8 || testHour >= 18) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("College is closed.")));
      return;
    }

    setState(() => _isLoading = true);
    final timeColumn = _getCurrentTimeColumn();
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('timetables')
          .select()
          .ilike('"$timeColumn"', '%$query%')
          .order('Building', ascending: true);

      setState(() {
        _searchResults = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isClosed = testHour < 8 || testHour >= 18;
    final String timeSlotRange = "${testHour.toString().padLeft(2, '0')}:00 - ${(testHour + 1).toString().padLeft(2, '0')}:00";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: "Search 'Empty' or 'Subject'...",
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.white70)
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onSubmitted: _performSearch,
        ),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: isClosed
          ? _buildClosedMessage()
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
          ? _buildEmptyState()
          : _buildResultsList(timeSlotRange),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Type 'Empty' to find free rooms", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          ActionChip(
            backgroundColor: Colors.indigo[50],
            label: const Text("Find Free Rooms Now", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
            onPressed: () {
              _searchController.text = "Empty";
              _performSearch("Empty");
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(String timeSlot) {
    final timeColumn = _getCurrentTimeColumn();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final room = _searchResults[index];
        final String subject = room[timeColumn] ?? "Empty";
        final bool isEmpty = subject == "Empty" || subject.contains("CANCELLED");

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoomListView(
                    buildingName: room['Building'].toString(),
                    floor: room['Floor'] ?? 1,
                    // FIXED: Passed the required color parameter[cite: 3]
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              );
            },
            leading: Icon(Icons.circle, color: isEmpty ? Colors.green : Colors.red),
            title: Text("Room ${room['RoomID']} - ${room['Building']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("🕒 Slot: $timeSlot"),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                    isEmpty ? "FREE" : "BUSY",
                    style: TextStyle(fontWeight: FontWeight.bold, color: isEmpty ? Colors.green : Colors.red)
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClosedMessage() => const Center(
      child: Text("College is closed. Search resumes at 8 AM.", style: TextStyle(fontWeight: FontWeight.bold))
  );
}