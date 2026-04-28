import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState(); // FIXED: Mapped to correct class name
}

class _SearchViewState extends State<SearchView> { // FIXED: Changed from _SearchViewController
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  // =========================================================================
  // 🛠️ TESTING MODE:
  // Change '11' to 'DateTime.now().hour' for normal mode
  final int testHour = 11;
  // =========================================================================

  String _getCurrentTimeColumn() {
    final now = DateTime.now();
    final days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return "${days[now.weekday - 1]}_${testHour.toString().padLeft(2, '0')}:00";
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    if (testHour < 8 || testHour >= 18) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("College is closed in Test Mode.")));
      return;
    }

    setState(() => _isLoading = true);
    final timeColumn = _getCurrentTimeColumn();
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.from('timetables').select()
          .ilike(timeColumn, '%$query%')
          .order('Building', ascending: true);
      setState(() { _searchResults = response; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Search failed. Check your connection.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isClosed = testHour < 8 || testHour >= 18;
    final String timeSlotRange = "${testHour.toString().padLeft(2, '0')}:00 - ${(testHour + 1).toString().padLeft(2, '0')}:00";

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Search 'Empty' (Hour: $testHour:00)",
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onSubmitted: _performSearch,
        ),
        backgroundColor: Colors.indigo[900],
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
          const Text("Type 'Empty' to find free rooms"),
          const SizedBox(height: 10),
          ActionChip(
            label: const Text("Find Free Rooms Now"),
            onPressed: () { _searchController.text = "Empty"; _performSearch("Empty"); },
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
        final subject = room[timeColumn] ?? "Empty";
        final bool isEmpty = subject == "Empty";

        return Card(
          child: ListTile(
            leading: Icon(Icons.circle, color: isEmpty ? Colors.green : Colors.red),
            title: Text("Room ${room['RoomID']} - ${room['Building']}"),
            subtitle: Text("🕒 Time: $timeSlot"), //
            trailing: Text(subject, style: TextStyle(fontWeight: FontWeight.bold, color: isEmpty ? Colors.green : Colors.indigo[900])),
          ),
        );
      },
    );
  }

  Widget _buildClosedMessage() {
    return const Center(child: Text("College is closed. Search resumes at 8 AM."));
  }
}