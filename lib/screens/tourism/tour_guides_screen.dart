import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/city_os_models.dart';
import 'tour_guide_registration_screen.dart';

class TourGuidesScreen extends StatefulWidget {
  const TourGuidesScreen({super.key});

  @override
  State<TourGuidesScreen> createState() => _TourGuidesScreenState();
}

class _TourGuidesScreenState extends State<TourGuidesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedLang = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tour Guides"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Find a Guide"),
            Tab(text: "My Applications"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFindGuideTab(),
          _buildMyApplicationsTab(),
        ],
      ),
    );
  }

  Widget _buildFindGuideTab() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: ['All', 'English', 'Amharic', 'Sidama', 'French', 'German'].map((lang) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(lang),
                  selected: _selectedLang == lang,
                  onSelected: (s) => setState(() => _selectedLang = lang),
                  selectedColor: Colors.teal.withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('tour_guides').where('status', isEqualTo: 'approved').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var docs = snapshot.data!.docs;

              if (_selectedLang != 'All') {
                docs = docs.where((d) => (List.from((d.data() as Map)['languages'] ?? [])).contains(_selectedLang)).toList();
              }

              if (docs.isEmpty) return const Center(child: Text("No guides found for the selected language."));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final guide = TourGuide.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
                  return _buildGuideCard(guide);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard(TourGuide guide) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 35)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guide.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("${guide.experience} Experience", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(" ${guide.rating}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: guide.languages.map((l) => Chip(label: Text(l, style: const TextStyle(fontSize: 10)), padding: EdgeInsets.zero)).toList(),
            ),
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showHireDialog(guide),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                child: const Text("Hire Guide (200 ETB/hr)"),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showHireDialog(TourGuide guide) {
    final dateC = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final destC = TextEditingController();
    int hours = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: Text("Hire ${guide.fullName}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: dateC, decoration: const InputDecoration(labelText: "Select Date")),
              TextField(controller: destC, decoration: const InputDecoration(labelText: "Tour Destination")),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Number of hours:"),
                  Row(
                    children: [
                      IconButton(onPressed: () => setS(() => hours = hours > 1 ? hours - 1 : 1), icon: const Icon(Icons.remove_circle_outline)),
                      Text("$hours", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => setS(() => hours = hours < 8 ? hours + 1 : 8), icon: const Icon(Icons.add_circle_outline)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),
              Text("Total Price: ${hours * 200} ETB", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (destC.text.isEmpty) return;
                try {
                  await _firestore.collection('tourist_bookings').add({
                    'type': "guide",
                    'guideId': guide.id,
                    'guideName': guide.fullName,
                    'userId': FirebaseAuth.instance.currentUser?.uid,
                    'userName': FirebaseAuth.instance.currentUser?.displayName ?? 'Tourist',
                    'date': dateC.text,
                    'hours': hours,
                    'totalPrice': hours * 200,
                    'destination': destC.text,
                    'status': "pending",
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guide request sent!")));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Confirm"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMyApplicationsTab() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('tour_guides').where('userId', isEqualTo: user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("You haven't applied to be a guide yet."),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TourGuideRegistrationScreen())), child: const Text("Apply Now"))
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['fullName'] ?? 'Guide Application'),
                subtitle: Text("Experience: ${data['experience']}"),
                trailing: Chip(label: Text(data['status']?.toString().toUpperCase() ?? 'PENDING')),
              ),
            );
          },
        );
      },
    );
  }
}
