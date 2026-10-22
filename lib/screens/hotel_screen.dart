import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'ai_assistant_screen.dart';

class HotelScreen extends StatefulWidget {
  const HotelScreen({super.key});

  @override
  State<HotelScreen> createState() => _HotelScreenState();
}

class _HotelScreenState extends State<HotelScreen> {
  @override
  void initState() {
    super.initState();
    // Only seed hotels in debug mode for development/testing
    if (kDebugMode) {
      _seedHotels();
    }
  }

  Future<void> _seedHotels() async {
    final snap = await FirebaseFirestore.instance.collection('hotels').limit(1).get();
    if (snap.docs.isEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      final hotels = [
        {'name': 'Haile Resort', 'location': 'Hawassa Lake Side', 'rating': 4.9, 'description': 'Premium luxury resort.'},
        {'name': 'Lewi Hotel', 'location': 'Piazza', 'rating': 4.7, 'description': 'Modern business hotel.'},
        {'name': 'Central Hawassa', 'location': 'Menaharia', 'rating': 4.5, 'description': 'Great service at city center.'},
      ];
      for (var h in hotels) {
        batch.set(FirebaseFirestore.instance.collection('hotels').doc(), h);
      }
      await batch.commit();
    }
  }

  void _bookRoom(BuildContext context, DocumentSnapshot hotelDoc) {
    final hotel = hotelDoc.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book at ${hotel['name']}'),
        content: const Text('Do you want to book a room at this hotel? Our staff will contact you for confirmation.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final user = Provider.of<AuthProvider>(context, listen: false).userModel;
              await FirebaseFirestore.instance.collection('hotel_reservations').add({
                'hotelId': hotelDoc.id,
                'hotelName': hotel['name'],
                'guestName': user?.fullName ?? 'Guest',
                'guestPhone': user?.phone ?? 'N/A',
                'userId': user?.uid,
                'status': 'pending',
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reservation request sent!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('BOOK NOW'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotels & Lodging'),
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('hotels').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hotels available at the moment.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snapshot.data!.docs[i];
              final h = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: const Icon(Icons.hotel, size: 64, color: Colors.purple),
                    ),
                    ListTile(
                      title: Text(h['name'] ?? 'Hotel', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(h['location'] ?? 'Hawassa'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(8)),
                        child: Text('⭐ ${h['rating'] ?? '4.5'}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _bookRoom(context, doc),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[800], foregroundColor: Colors.white),
                          child: const Text('RESERVE ROOM'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
        backgroundColor: Colors.purple[800],
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text('Ask AI', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
