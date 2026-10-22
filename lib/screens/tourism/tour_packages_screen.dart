import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/city_os_models.dart';
import 'tour_operator_registration_screen.dart';

class TourPackagesScreen extends StatefulWidget {
  const TourPackagesScreen({super.key});

  @override
  State<TourPackagesScreen> createState() => _TourPackagesScreenState();
}

class _TourPackagesScreenState extends State<TourPackagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tour Packages"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: "Browse Packages"),
            Tab(text: "My Bookings"),
            Tab(text: "Create (Operator)"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(),
          _buildMyBookingsTab(),
          _buildCreateTab(),
        ],
      ),
    );
  }

  Widget _buildBrowseTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('tour_packages').where('status', isEqualTo: 'active').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text("No packages available yet. Check back soon for exciting Hawassa tours!", textAlign: TextAlign.center),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final pkg = TourPackage.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
            return _buildPackageCard(pkg);
          },
        );
      },
    );
  }

  Widget _buildPackageCard(TourPackage pkg) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pkg.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _badge(Icons.location_on, pkg.destination, Colors.orange),
                const SizedBox(width: 10),
                _badge(Icons.timer, pkg.duration, Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            Text(pkg.description, style: TextStyle(color: Colors.grey[600]), maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              children: [
                if (pkg.guideIncluded) _chip("Guide Included", Colors.teal),
                if (pkg.vehicleIncluded) ...[const SizedBox(width: 8), _chip("Vehicle Included", Colors.purple)],
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${pkg.price} ETB", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                ElevatedButton(
                  onPressed: () => _showBookingDialog(pkg),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                  child: const Text("Book Now"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: color), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showBookingDialog(TourPackage pkg) {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final dateC = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    int people = 1;
    String payment = 'Telebirr';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: Text("Book ${pkg.name}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameC, decoration: const InputDecoration(labelText: "Passenger Name")),
                TextField(controller: phoneC, decoration: const InputDecoration(labelText: "Phone Number"), keyboardType: TextInputType.phone),
                TextField(controller: dateC, decoration: const InputDecoration(labelText: "Date (YYYY-MM-DD)")),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Number of people:"),
                    Row(
                      children: [
                        IconButton(onPressed: () => setS(() => people = people > 1 ? people - 1 : 1), icon: const Icon(Icons.remove_circle_outline)),
                        Text("$people", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => setS(() => people = people < 10 ? people + 1 : 10), icon: const Icon(Icons.add_circle_outline)),
                      ],
                    )
                  ],
                ),
                DropdownButtonFormField<String>(
                  value: payment,
                  decoration: const InputDecoration(labelText: "Payment Method"),
                  items: ['Telebirr', 'CBE Birr'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => payment = v!,
                ),
                const SizedBox(height: 20),
                Text("Total Price: ${pkg.price * people} ETB", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameC.text.isEmpty || phoneC.text.isEmpty) return;
                try {
                  final doc = await _firestore.collection('tourist_bookings').add({
                    'packageId': pkg.id,
                    'packageName': pkg.name,
                    'userId': _user?.uid,
                    'passengerName': nameC.text,
                    'phone': phoneC.text,
                    'date': dateC.text,
                    'people': people,
                    'totalPrice': pkg.price * people,
                    'paymentMethod': payment,
                    'status': "pending",
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    showDialog(context: context, builder: (_) => AlertDialog(
                      title: const Text("Booking Successful!"),
                      content: Text("Your booking ID is: ${doc.id}\nStatus: Pending confirmation"),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
                    ));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Confirm Booking"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMyBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('tourist_bookings').where('userId', isEqualTo: _user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("You haven't made any bookings yet."));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['packageName'] ?? 'Tour'),
                subtitle: Text("Date: ${data['date']} • ${data['people']} people"),
                trailing: Chip(label: Text(data['status']?.toString().toUpperCase() ?? 'PENDING', style: const TextStyle(fontSize: 10))),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCreateTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('tour_operators').doc(_user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (!snapshot.data!.exists || (snapshot.data!.data() as Map)['status'] != 'approved') {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business_center, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Register as a Tour Operator first to create packages.", textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TourOperatorRegistrationScreen())),
                    child: const Text("Registration Screen"),
                  )
                ],
              ),
            ),
          );
        }

        final nameC = TextEditingController();
        final descC = TextEditingController();
        final durC = TextEditingController(text: "1 day");
        final priceC = TextEditingController();
        bool guide = true;
        bool vehicle = true;
        String dest = 'Lake Hawassa';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: "Package Name")),
              TextField(controller: descC, decoration: const InputDecoration(labelText: "Description"), maxLines: 3),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('tourist_sites').snapshots(),
                builder: (context, siteSnap) {
                  List<String> siteNames = ['Lake Hawassa', 'Amora Gedel', 'Tabor Mountain'];
                  if (siteSnap.hasData) {
                    siteNames = siteSnap.data!.docs.map((e) => (e.data() as Map)['name'].toString()).toList();
                  }
                  return DropdownButtonFormField<String>(
                    value: siteNames.contains(dest) ? dest : siteNames.first,
                    decoration: const InputDecoration(labelText: "Destination"),
                    items: siteNames.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => dest = v!,
                  );
                },
              ),
              TextField(controller: durC, decoration: const InputDecoration(labelText: "Duration")),
              TextField(controller: priceC, decoration: const InputDecoration(labelText: "Price (ETB)"), keyboardType: TextInputType.number),
              StatefulBuilder(builder: (context, setS) => Column(children: [
                SwitchListTile(title: const Text("Guide Included"), value: guide, onChanged: (v) => setS(() => guide = v)),
                SwitchListTile(title: const Text("Vehicle Included"), value: vehicle, onChanged: (v) => setS(() => vehicle = v)),
              ])),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await _firestore.collection('tour_packages').add({
                        'name': nameC.text,
                        'description': descC.text,
                        'destination': dest,
                        'duration': durC.text,
                        'price': double.tryParse(priceC.text) ?? 0,
                        'guideIncluded': guide,
                        'vehicleIncluded': vehicle,
                        'operatorId': _user?.uid,
                        'status': 'active',
                        'images': [],
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Package created!")));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: const Text("Create Package"),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
