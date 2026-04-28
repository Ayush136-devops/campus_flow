import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _isOutsideHours = false;

  @override
  void initState() {
    super.initState();
    _checkCollegeHours();
  }

  // Check if current time is outside 8 AM - 6 PM
  void _checkCollegeHours() {
    final now = DateTime.now();
    if (now.hour < 8 || now.hour >= 18) {
      setState(() => _isOutsideHours = true);
    }
  }

  // Helper to match your Supabase column naming: Day_HH:00
  String _getCurrentTimeColumn() {
    final now = DateTime.now();
    final days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    final dayName = days[now.weekday - 1];

    // For testing tonight (Sat 9:40 PM), you can temporarily change this to "10:00"
    final hourString = "${now.hour.toString().padLeft(2, '0')}:00";
    return "${dayName}_$hourString";
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    // Safety: Don't query if the column doesn't exist in the CSV
    if (_isOutsideHours) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("College is closed. Try searching tomorrow after 8 AM!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final timeColumn = _getCurrentTimeColumn();
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('timetables')
          .select()
          .ilike(timeColumn, '%$query%') // Finds partial matches like "Math" for "Maths"
          .order('Building', ascending: true);

      setState(() {
        _searchResults = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Search Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Search failed: Column for this hour not found.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search subject",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onSubmitted: _performSearch,
        ),
        backgroundColor: Colors.indigo[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _isOutsideHours
          ? _buildClosedMessage()
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
          ? _buildEmptyState()
          : _buildResultsList(),
    );
  }

  Widget _buildClosedMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.nightlight_round, size: 80, color: Colors.indigo[200]),
          const SizedBox(height: 20),
          const Text(
            "College is currently closed",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text("Live search resumes at 8:00 AM"),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text("Type 'Empty' to find free rooms across campus"),
    );
  }

  Widget _buildResultsList() {
    final timeColumn = _getCurrentTimeColumn();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final room = _searchResults[index];
        final subject = room[timeColumn] ?? "Empty";
        final bool isEmpty = subject == "Empty";

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (isEmpty ? Colors.green : Colors.red).withValues(alpha: 0.1),
              child: Icon(
                isEmpty ? Icons.check_circle : Icons.block,
                color: isEmpty ? Colors.green : Colors.red,
              ),
            ),
            title: Text("Room ${room['RoomID']}"),
            subtitle: Text("${room['Building']} - Floor ${room['Floor']}"),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                    subject,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isEmpty ? Colors.green : Colors.indigo[900]
                    )
                ),
                Text(room['Department'] ?? "", style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }
}