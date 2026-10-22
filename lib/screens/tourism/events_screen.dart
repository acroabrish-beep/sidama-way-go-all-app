import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/tourism_models.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthProvider>(context, listen: false).userModel?.role;
    final bool isAdmin = role == UserRole.superAdmin || role == UserRole.tourismAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Events & Festivals"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Upcoming Events"),
            Tab(text: "Add Event (Admin)"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingEventsTab(),
          isAdmin ? _buildAddEventTab() : const Center(child: Text("Admin Access Required")),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('events').orderBy('date').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("🎪", style: TextStyle(fontSize: 80)),
                const SizedBox(height: 16),
                const Text("No upcoming events or festivals at the moment.", style: TextStyle(color: Colors.grey)),
                const Text("Check back later for exciting cultural celebrations!"),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final event = TouristEvent.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
            return _buildEventCard(event);
          },
        );
      },
    );
  }

  Widget _buildEventCard(TouristEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: const BoxDecoration(border: Border(left: BorderSide(color: Colors.orange, width: 6))),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(event.location, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 16),
                  const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(_formatDate(event.date), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text(event.description, maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(onPressed: () {}, icon: const Icon(Icons.favorite_border), label: const Text("Interested")),
                  const SizedBox(width: 8),
                  TextButton.icon(onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event details copied!")));
                  }, icon: const Icon(Icons.share), label: const Text("Share")),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Widget _buildAddEventTab() {
    final titleC = TextEditingController();
    final locC = TextEditingController(text: "Hawassa");
    final dateC = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final descC = TextEditingController();
    String cat = 'Festival';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(controller: titleC, decoration: const InputDecoration(labelText: "Event Title")),
          const SizedBox(height: 12),
          TextField(controller: locC, decoration: const InputDecoration(labelText: "Location")),
          const SizedBox(height: 12),
          TextField(controller: dateC, decoration: const InputDecoration(labelText: "Date (YYYY-MM-DD)")),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: cat,
            decoration: const InputDecoration(labelText: "Category"),
            items: ['Festival', 'Conference', 'Sports', 'Cultural', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => cat = v!,
          ),
          const SizedBox(height: 12),
          TextField(controller: descC, decoration: const InputDecoration(labelText: "Description"), maxLines: 4),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await _firestore.collection('events').add({
                    'title': titleC.text,
                    'location': locC.text,
                    'date': Timestamp.fromDate(DateTime.parse(dateC.text)),
                    'description': descC.text,
                    'category': cat,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event added successfully!")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
              child: const Text("Add Event"),
            ),
          ),
        ],
      ),
    );
  }
}
