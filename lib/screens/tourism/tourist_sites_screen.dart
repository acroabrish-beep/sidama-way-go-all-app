import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../models/city_os_models.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../book_ride_screen.dart';

class TouristSitesScreen extends StatefulWidget {
  const TouristSitesScreen({super.key});

  @override
  State<TouristSitesScreen> createState() => _TouristSitesScreenState();
}

class _TouristSitesScreenState extends State<TouristSitesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
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
        title: const Text("Tourist Sites"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "All Sites"),
            Tab(text: "Add Site (Admin)"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllSitesTab(),
          isAdmin ? _buildAddSiteTab() : const Center(child: Text("Admin Access Required")),
        ],
      ),
    );
  }

  Widget _buildAllSitesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search sites...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() {}),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['All', 'Nature', 'Adventure', 'Culture', 'Food', 'Luxury'].map((cat) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (s) => setState(() => _selectedCategory = cat),
                  selectedColor: Colors.green.withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('tourist_sites').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              var docs = snapshot.data!.docs;

              if (_selectedCategory != 'All') {
                docs = docs.where((d) => (d.data() as Map)['category'] == _selectedCategory).toList();
              }

              if (_searchController.text.isNotEmpty) {
                docs = docs.where((d) => (d.data() as Map)['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase())).toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final site = TouristSite.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
                  return _buildSiteCard(site);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSiteCard(TouristSite site) {
    String emoji;
    switch(site.category) {
      case "Nature": emoji = "🌿"; break;
      case "Adventure": emoji = "⛰️"; break;
      case "Culture": emoji = "🎭"; break;
      case "Food": emoji = "🍽️"; break;
      case "Luxury": emoji = "🏨"; break;
      default: emoji = "📍";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(backgroundColor: Colors.green.withValues(alpha: 0.1), child: Text(emoji)),
            title: Text(site.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text(site.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text(" ${site.rating} | ", style: const TextStyle(fontSize: 12)),
                const Icon(Icons.access_time, color: Colors.grey, size: 16),
                Text(" ${site.openingHours} | ", style: const TextStyle(fontSize: 12)),
                const Icon(Icons.payments, color: Colors.green, size: 16),
                Text(" ${site.entryFee}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _actionButton(Icons.map, "Navigate", () => _showNavDialog(site)),
                  _actionButton(Icons.photo_library, "Gallery", () => _showGalleryDialog()),
                  _actionButton(Icons.local_taxi, "Book Ride", () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookRideScreen(preselectedDestination: site.name)))),
                  _actionButton(Icons.rate_review, "Review", () => _showReviewDialog(site)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1B5E20),
          side: const BorderSide(color: Color(0xFF1B5E20)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  void _showNavDialog(TouristSite site) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text("Navigate to ${site.name}"),
      content: Text("GPS Coordinates:\nLat: ${site.lat}\nLng: ${site.lng}"),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
    ));
  }

  void _showGalleryDialog() {
    showDialog(context: context, builder: (_) => const AlertDialog(
      content: Text("Gallery images will be available soon!"),
    ));
  }

  void _showReviewDialog(TouristSite site) {
    final commentC = TextEditingController();
    double rating = 5.0;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text("Review ${site.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [const Text("Rating: "), Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold))]),
              Slider(value: rating, min: 1, max: 5, divisions: 4, onChanged: (v) => setDialogState(() => rating = v)),
              TextField(controller: commentC, decoration: const InputDecoration(hintText: "Your review...")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                await _firestore.collection('tour_reviews').add({
                  'siteId': site.id,
                  'siteName': site.name,
                  'userId': user?.uid,
                  'rating': rating,
                  'review': commentC.text,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review submitted!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            }, child: const Text("Submit"))
          ],
        );
      }
    ));
  }

  Widget _buildAddSiteTab() {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    final hoursC = TextEditingController(text: "6:00 AM - 6:00 PM");
    final feeC = TextEditingController(text: "Free");
    final latC = TextEditingController(text: "7.0504");
    final lngC = TextEditingController(text: "38.4955");
    String cat = 'Nature';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(controller: nameC, decoration: const InputDecoration(labelText: "Site Name")),
          const SizedBox(height: 12),
          TextField(controller: descC, decoration: const InputDecoration(labelText: "Description"), maxLines: 3),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: cat,
            decoration: const InputDecoration(labelText: "Category"),
            items: ['Nature', 'Adventure', 'Culture', 'Food', 'Luxury'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => cat = v!,
          ),
          const SizedBox(height: 12),
          TextField(controller: hoursC, decoration: const InputDecoration(labelText: "Opening Hours")),
          const SizedBox(height: 12),
          TextField(controller: feeC, decoration: const InputDecoration(labelText: "Entry Fee")),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: latC, decoration: const InputDecoration(labelText: "Latitude"), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: lngC, decoration: const InputDecoration(labelText: "Longitude"), keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await _firestore.collection('tourist_sites').add({
                    'name': nameC.text,
                    'description': descC.text,
                    'category': cat,
                    'openingHours': hoursC.text,
                    'entryFee': feeC.text,
                    'lat': double.tryParse(latC.text) ?? 7.0504,
                    'lng': double.tryParse(lngC.text) ?? 38.4955,
                    'rating': 4.5,
                    'isActive': true,
                    'images': [],
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Site added successfully!")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
              child: const Text("Add Site"),
            ),
          ),
          const SizedBox(height: 40),
          const Text("Existing Sites", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('tourist_sites').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map;
                  return ListTile(
                    title: Text(data['name'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => doc.reference.delete()),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          )
        ],
      ),
    );
  }
}
