import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../widgets/ai_insights_card.dart';
import '../models/city_os_models.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class GuestHouseDashboard extends StatefulWidget {
  const GuestHouseDashboard({super.key});

  @override
  State<GuestHouseDashboard> createState() => _GuestHouseDashboardState();
}

class _GuestHouseDashboardState extends State<GuestHouseDashboard> {
  final FlutterTts _flutterTts = FlutterTts();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = "";
  String _resFilter = "All";

  @override
  void initState() {
    super.initState();
    // Demo seeding is debug-only.
    if (kDebugMode) _seedData();
  }

  Future<void> _seedData() async {
    try {
      final ghSnap = await _firestore.collection(CityOSCollection.guestHouses).limit(1).get();
      if (ghSnap.docs.isEmpty) {
        final guestHouses = [
          {
            "name": "Sidama Home Guest House",
            "ownerName": "Almaz Tadesse",
            "phone": "+251911100001",
            "email": "sidamahome@gmail.com",
            "address": "Piazza Area, Hawassa",
            "description": "Cozy family-run guest house in the heart of Hawassa. Traditional Sidama hospitality with home-cooked meals.",
            "facilities": ["Free WiFi", "Breakfast Included", "Traditional Coffee", "Garden", "Hot Water"],
            "totalRooms": 12,
            "availableRooms": 8,
            "pricePerNight": 400,
            "rating": 4.6,
            "isActive": true,
            "gpsLat": 7.0504,
            "gpsLng": 38.4955
          },
          {
            "name": "Lake View Guest House",
            "ownerName": "Bekele Hailu",
            "phone": "+251911100002",
            "email": "lakeview@gmail.com",
            "address": "Lake Side Road, Hawassa",
            "description": "Affordable guest house with beautiful views of Lake Hawassa. Perfect for budget travelers who want the lake experience.",
            "facilities": ["Free WiFi", "Lake View", "Parking", "Breakfast Available", "Hot Water"],
            "totalRooms": 16,
            "availableRooms": 10,
            "pricePerNight": 550,
            "rating": 4.4,
            "isActive": true,
            "gpsLat": 7.0639,
            "gpsLng": 38.4813
          },
          {
            "name": "Tabor Mountain Guest House",
            "ownerName": "Tigist Bekele",
            "phone": "+251911100003",
            "email": "taborguesthouse@gmail.com",
            "address": "Tabor Area, Hawassa",
            "description": "Quiet guest house near Tabor Mountain. Ideal for hikers and nature lovers exploring Hawassa's natural attractions.",
            "facilities": ["Free WiFi", "Mountain View", "Garden", "Breakfast", "Parking"],
            "totalRooms": 10,
            "availableRooms": 6,
            "pricePerNight": 350,
            "rating": 4.3,
            "isActive": true,
            "gpsLat": 7.0633,
            "gpsLng": 38.5183
          },
          {
            "name": "Hawassa City Guest House",
            "ownerName": "Dawit Alemu",
            "phone": "+251911100004",
            "email": "hawassacity@gmail.com",
            "address": "Menaharia Area, Hawassa",
            "description": "Centrally located guest house with easy access to city transport, markets, and business centers.",
            "facilities": ["Free WiFi", "Parking", "Hot Water", "Laundry Service"],
            "totalRooms": 20,
            "availableRooms": 14,
            "pricePerNight": 300,
            "rating": 4.2,
            "isActive": true,
            "gpsLat": 7.0570,
            "gpsLng": 38.4900
          }
        ];
        for (var gh in guestHouses) {
          await _firestore.collection(CityOSCollection.guestHouses).add(gh);
        }
      }

      final roomSnap = await _firestore.collection("guest_house_rooms").limit(1).get();
      if (roomSnap.docs.isEmpty) {
        final rooms = [
          {"guestHouseName": "Sidama Home Guest House", "roomType": "Single", "totalRooms": 7, "availableRooms": 5, "pricePerNight": 350, "amenities": ["Single Bed", "WiFi", "Hot Water"]},
          {"guestHouseName": "Sidama Home Guest House", "roomType": "Double", "totalRooms": 5, "availableRooms": 3, "pricePerNight": 450, "amenities": ["Double Bed", "WiFi", "Hot Water", "Breakfast"]},
          {"guestHouseName": "Lake View Guest House", "roomType": "Single", "totalRooms": 9, "availableRooms": 6, "pricePerNight": 480, "amenities": ["Single Bed", "WiFi", "Lake View"]},
          {"guestHouseName": "Lake View Guest House", "roomType": "Double", "totalRooms": 7, "availableRooms": 4, "pricePerNight": 620, "amenities": ["Double Bed", "WiFi", "Lake View", "Breakfast"]},
          {"guestHouseName": "Tabor Mountain Guest House", "roomType": "Single", "totalRooms": 6, "availableRooms": 4, "pricePerNight": 300, "amenities": ["Single Bed", "WiFi", "Mountain View"]},
          {"guestHouseName": "Tabor Mountain Guest House", "roomType": "Double", "totalRooms": 4, "availableRooms": 2, "pricePerNight": 400, "amenities": ["Double Bed", "WiFi", "Mountain View"]},
          {"guestHouseName": "Hawassa City Guest House", "roomType": "Single", "totalRooms": 12, "availableRooms": 9, "pricePerNight": 260, "amenities": ["Single Bed", "WiFi", "Hot Water"]},
          {"guestHouseName": "Hawassa City Guest House", "roomType": "Family", "totalRooms": 8, "availableRooms": 5, "pricePerNight": 480, "amenities": ["Two Beds", "WiFi", "Hot Water", "TV"]}
        ];
        for (var r in rooms) {
          await _firestore.collection("guest_house_rooms").add(r);
        }
      }
    } catch (e) {
      debugPrint("Error seeding data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthProvider>(context, listen: false).userModel?.role;
    final isAuthorized = role == UserRole.superAdmin || role == UserRole.hotelAdmin;

    if (!isAuthorized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text("Access Restricted", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text("Guest House Management Only"),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("BACK"),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Guest House Dashboard"),
          backgroundColor: const Color(0xFF00695C),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Overview"),
              Tab(text: "Guest Houses"),
              Tab(text: "Reservations"),
              Tab(text: "Rooms"),
              Tab(text: "Reports"),
              Tab(text: "AI Assistant"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildGuestHousesTab(),
            _buildReservationsTab(),
            _buildRoomsTab(),
            _buildReportsTab(),
            _buildAIAssistantTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(CityOSCollection.guestHouses).snapshots(),
      builder: (context, ghSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection("guest_house_reservations").snapshots(),
          builder: (context, resSnap) {
            if (!ghSnap.hasData || !resSnap.hasData) return const Center(child: CircularProgressIndicator());

            int totalGH = ghSnap.data!.docs.length;
            int totalRes = resSnap.data!.docs.length;
            int todayCheckins = 0;
            double todayRevenue = 0;
            int activeGH = 0;
            int totalAvailRooms = 0;
            Map<String, int> popularity = {};

            for (var doc in ghSnap.data!.docs) {
              final d = doc.data() as Map<String, dynamic>;
              if (d['isActive'] == true) activeGH++;
              totalAvailRooms += (d['availableRooms'] ?? 0) as int;
            }

            for (var doc in resSnap.data!.docs) {
              final d = doc.data() as Map<String, dynamic>;
              final gh = d['guestHouseName'] ?? "Unknown";
              popularity[gh] = (popularity[gh] ?? 0) + 1;

              if (d['checkInDate'] == today) {
                todayCheckins++;
                todayRevenue += (d['totalPrice'] ?? 0).toDouble();
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AIInsightsCard(dashboardContext: 'guest_house', title: '🤖 Guest House AI Insights'),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _summaryCard("Total Guest Houses", totalGH.toString(), Icons.house, Colors.teal),
                      _summaryCard("Reservations", totalRes.toString(), Icons.book_online, Colors.blue),
                      _summaryCard("Today Check-ins", todayCheckins.toString(), Icons.login, Colors.orange),
                      _summaryCard("Today Revenue", "${todayRevenue.toInt()} ETB", Icons.attach_money, Colors.green),
                      _summaryCard("Avail. Rooms", totalAvailRooms.toString(), Icons.meeting_room, Colors.cyan),
                      _summaryCard("Active Guest Houses", activeGH.toString(), Icons.check_circle, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text("Guest House Popularity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...popularity.entries.map((e) => _popularityBar(e.key, e.value, totalRes == 0 ? 1 : totalRes)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _popularityBar(String name, int count, int total) {
    double factor = count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 13)),
              Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(5)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: factor.clamp(0.0, 1.0),
              child: Container(decoration: BoxDecoration(color: const Color(0xFF00695C), borderRadius: BorderRadius.circular(5))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestHousesTab() {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection(CityOSCollection.guestHouses).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text("🏠 ${data['name'] ?? ''}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          Switch(
                            value: data['isActive'] ?? true,
                            onChanged: (v) => _firestore.collection(CityOSCollection.guestHouses).doc(id).update({'isActive': v}),
                          ),
                        ],
                      ),
                      Row(children: List.generate(5, (index) => Icon(Icons.star, size: 16, color: index < (data['rating'] ?? 0).floor() ? Colors.amber : Colors.grey[300]))),
                      const SizedBox(height: 8),
                      _iconInfo(Icons.person, data['ownerName']),
                      _iconInfo(Icons.phone, data['phone']),
                      _iconInfo(Icons.email, data['email']),
                      _iconInfo(Icons.location_on, data['address']),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Rooms: ${data['availableRooms']}/${data['totalRooms']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("${data['pricePerNight']} ETB / night", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: (data['facilities'] as List? ?? []).map((f) => Chip(label: Text(f.toString(), style: const TextStyle(fontSize: 8)), padding: EdgeInsets.zero)).toList(),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(onPressed: () => _showSnackbar("Photo storage coming soon"), icon: const Icon(Icons.add_a_photo), label: const Text("PHOTOS")),
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showGuestHouseDialog(doc: doc)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteDoc("guest_houses", id)),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchQuery = data['name'];
                              _resFilter = "All";
                            });
                            DefaultTabController.of(context).animateTo(2);
                          },
                          icon: const Icon(Icons.list_alt),
                          label: const Text("VIEW RESERVATIONS"),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGuestHouseDialog(),
        backgroundColor: const Color(0xFF00695C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _iconInfo(IconData icon, String? text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 8), Text(text ?? "N/A", style: const TextStyle(fontSize: 12))]),
  );

  void _showGuestHouseDialog({DocumentSnapshot? doc}) {
    final data = doc?.data() as Map<String, dynamic>?;
    final nameC = TextEditingController(text: data?['name']);
    final ownerC = TextEditingController(text: data?['ownerName']);
    final phoneC = TextEditingController(text: data?['phone']);
    final emailC = TextEditingController(text: data?['email']);
    final addrC = TextEditingController(text: data?['address']);
    final descC = TextEditingController(text: data?['description']);
    final roomsC = TextEditingController(text: data?['totalRooms']?.toString());
    final priceC = TextEditingController(text: data?['pricePerNight']?.toString());
    final rateC = TextEditingController(text: data?['rating']?.toString());
    final facC = TextEditingController(text: (data?['facilities'] as List? ?? []).join(", "));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc == null ? "Add Guest House" : "Edit Guest House"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: ownerC, decoration: const InputDecoration(labelText: "Owner")),
              TextField(controller: phoneC, decoration: const InputDecoration(labelText: "Phone")),
              TextField(controller: emailC, decoration: const InputDecoration(labelText: "Email")),
              TextField(controller: addrC, decoration: const InputDecoration(labelText: "Address")),
              TextField(controller: descC, decoration: const InputDecoration(labelText: "Description"), maxLines: 2),
              TextField(controller: roomsC, decoration: const InputDecoration(labelText: "Total Rooms"), keyboardType: TextInputType.number),
              TextField(controller: priceC, decoration: const InputDecoration(labelText: "Price/Night"), keyboardType: TextInputType.number),
              TextField(controller: rateC, decoration: const InputDecoration(labelText: "Rating (1-5)"), keyboardType: TextInputType.number),
              TextField(controller: facC, decoration: const InputDecoration(labelText: "Facilities (comma separated)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              final payload = {
                "name": nameC.text,
                "ownerName": ownerC.text,
                "phone": phoneC.text,
                "email": emailC.text,
                "address": addrC.text,
                "description": descC.text,
                "totalRooms": int.tryParse(roomsC.text) ?? 0,
                "availableRooms": data?['availableRooms'] ?? int.tryParse(roomsC.text) ?? 0,
                "pricePerNight": double.tryParse(priceC.text) ?? 0,
                "rating": double.tryParse(rateC.text) ?? 0,
                "isActive": data?['isActive'] ?? true,
                "facilities": facC.text.split(",").map((e) => e.trim()).toList(),
              };
              if (doc == null) {
                await _firestore.collection(CityOSCollection.guestHouses).add(payload);
              } else {
                await _firestore.collection(CityOSCollection.guestHouses).doc(doc.id).update(payload);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsTab() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(hintText: "Search Guest Name...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ["All", "Today", "Confirmed", "Pending"].map((s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s),
                selected: _resFilter == s,
                onSelected: (selected) => setState(() => _resFilter = s),
              ),
            )).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection("guest_house_reservations").orderBy("timestamp", descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final filtered = snapshot.data!.docs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final guest = (d['guestName'] ?? "").toString().toLowerCase();
                final status = (d['status'] ?? "").toString().toLowerCase();
                final checkIn = (d['checkInDate'] ?? "").toString();

                bool matchesSearch = guest.contains(_searchQuery);
                bool matchesFilter = true;
                if (_resFilter == "Today") {
                  matchesFilter = checkIn == today;
                } else if (_resFilter != "All") matchesFilter = status == _resFilter.toLowerCase();

                return matchesSearch && matchesFilter;
              }).toList();

              if (filtered.isEmpty) return const Center(child: Text("No reservations found"));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final docId = filtered[i].id;
                  final d = filtered[i].data() as Map<String, dynamic>;
                  final status = d['status'] ?? "confirmed";

                  return Card(
                    child: ListTile(
                      title: Text(d['guestName'] ?? ""),
                      subtitle: Text("${d['guestHouseName']} • ${d['roomType']}\n${d['checkInDate']} to ${d['checkOutDate']}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Chip(label: Text(status, style: const TextStyle(fontSize: 8, color: Colors.white)), backgroundColor: _getStatusColor(status), padding: EdgeInsets.zero),
                          Text("${d['totalPrice']} ETB", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      onTap: () => _showResActions(docId, d),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(onPressed: () => _showAddRes(), icon: const Icon(Icons.add), label: const Text("NEW RESERVATION")),
        )
      ],
    );
  }

  Color _getStatusColor(String s) {
    switch(s.toLowerCase()) {
      case 'confirmed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'checked_out': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _showResActions(String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reservation Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.person), title: Text(data['guestName'] ?? ""), subtitle: Text(data['phone'] ?? "")),
            ListTile(leading: const Icon(Icons.house), title: Text(data['guestHouseName'] ?? ""), subtitle: Text(data['roomType'] ?? "")),
            ListTile(leading: const Icon(Icons.calendar_today), title: Text("${data['checkInDate']} to ${data['checkOutDate']}")),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(onPressed: () => _showQR(id, data), child: const Text("VIEW QR")),
                ElevatedButton(onPressed: () => _updateResStatus(id), child: const Text("UPDATE")),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showQR(String id, Map<String, dynamic> data) {
    final qrData = jsonEncode({
      "type": "guest_house",
      "reservationId": id,
      "guest": data['guestName'],
      "guestHouse": data['guestHouseName'],
      "checkIn": data['checkInDate'],
      "checkOut": data['checkOutDate'],
      "room": data['roomType'],
      "status": data['status'] ?? "confirmed"
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("QR Ticket"),
        content: SizedBox(width: 200, height: 200, child: QrImageView(data: qrData, version: QrVersions.auto, size: 200.0)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("DONE"))],
      ),
    );
  }

  void _updateResStatus(String id) {
    String selected = "Confirmed";
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: const Text("Update Status"),
          content: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            items: ["Confirmed", "Pending", "Cancelled", "Checked Out"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setDState(() => selected = v!),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection("guest_house_reservations").doc(id).update({'status': selected.toLowerCase().replaceAll(" ", "_")});
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
              child: const Text("UPDATE"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRes() async {
    final ghSnap = await _firestore.collection(CityOSCollection.guestHouses).get();
    final houses = ghSnap.docs.map((d) => d['name'] as String).toList();

    final guestC = TextEditingController();
    final phoneC = TextEditingController();
    final checkInC = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final checkOutC = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1))));
    final priceC = TextEditingController();
    String? selectedGH = houses.isNotEmpty ? houses.first : null;
    String selectedRoom = "Single";
    String selectedPay = "Telebirr";

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: const Text("Add Reservation"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: guestC, decoration: const InputDecoration(labelText: "Guest Name")),
                TextField(controller: phoneC, decoration: const InputDecoration(labelText: "Phone")),
                DropdownButtonFormField<String>(
                  initialValue: selectedGH,
                  items: houses.map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 10)))).toList(),
                  onChanged: (v) => setDState(() => selectedGH = v),
                  decoration: const InputDecoration(labelText: "Guest House"),
                ),
                DropdownButtonFormField<String>(
                  initialValue: selectedRoom,
                  items: ["Single", "Double", "Family"].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setDState(() => selectedRoom = v!),
                  decoration: const InputDecoration(labelText: "Room Type"),
                ),
                TextField(controller: checkInC, decoration: const InputDecoration(labelText: "Check-in (YYYY-MM-DD)")),
                TextField(controller: checkOutC, decoration: const InputDecoration(labelText: "Check-out (YYYY-MM-DD)")),
                TextField(controller: priceC, decoration: const InputDecoration(labelText: "Total Price"), keyboardType: TextInputType.number),
                DropdownButtonFormField<String>(
                  initialValue: selectedPay,
                  items: ["Telebirr", "CBE Birr", "Cash"].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setDState(() => selectedPay = v!),
                  decoration: const InputDecoration(labelText: "Payment Method"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection("guest_house_reservations").add({
                  "guestName": guestC.text,
                  "phone": phoneC.text,
                  "guestHouseName": selectedGH,
                  "roomType": selectedRoom,
                  "checkInDate": checkInC.text,
                  "checkOutDate": checkOutC.text,
                  "totalPrice": double.tryParse(priceC.text) ?? 0.0,
                  "paymentMethod": selectedPay,
                  "status": "confirmed",
                  "timestamp": FieldValue.serverTimestamp(),
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("SAVE"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsTab() {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection("guest_house_rooms").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final docId = docs[i].id;
              final d = docs[i].data() as Map<String, dynamic>;
              int avail = d['availableRooms'] ?? 0;
              int total = d['totalRooms'] ?? 0;

              return Card(
                child: ListTile(
                  title: Text("${d['roomType']} - ${d['guestHouseName']}"),
                  subtitle: Text("Price: ${d['pricePerNight']} ETB\nAmenities: ${(d['amenities'] as List? ?? []).join(", ")}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateRoomAvail(docId, avail - 1)),
                      Text("$avail/$total", style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _updateRoomAvail(docId, avail + 1)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRoomDialog(),
        backgroundColor: const Color(0xFF00695C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddRoomDialog() async {
    final ghSnap = await _firestore.collection(CityOSCollection.guestHouses).get();
    final houses = ghSnap.docs.map((d) => d['name'] as String).toList();

    final typeC = TextEditingController();
    final totalC = TextEditingController();
    final priceC = TextEditingController();
    final amenC = TextEditingController();
    String? selectedGH = houses.isNotEmpty ? houses.first : null;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: const Text("Add Room Type"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedGH,
                  items: houses.map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 10)))).toList(),
                  onChanged: (v) => setDState(() => selectedGH = v),
                  decoration: const InputDecoration(labelText: "Guest House"),
                ),
                TextField(controller: typeC, decoration: const InputDecoration(labelText: "Room Type (e.g. Single)")),
                TextField(controller: totalC, decoration: const InputDecoration(labelText: "Total Rooms"), keyboardType: TextInputType.number),
                TextField(controller: priceC, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
                TextField(controller: amenC, decoration: const InputDecoration(labelText: "Amenities (comma separated)")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection("guest_house_rooms").add({
                  "guestHouseName": selectedGH,
                  "roomType": typeC.text,
                  "totalRooms": int.tryParse(totalC.text) ?? 0,
                  "availableRooms": int.tryParse(totalC.text) ?? 0,
                  "pricePerNight": double.tryParse(priceC.text) ?? 0.0,
                  "amenities": amenC.text.split(",").map((e) => e.trim()).toList(),
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("SAVE"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateRoomAvail(String id, int newVal) async {
    if (newVal < 0) return;
    await _firestore.collection("guest_house_rooms").doc(id).update({'availableRooms': newVal});
  }

  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Guest House Performance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _reportCard("Revenue Summary", "Today: 8,400 ETB\nWeekly: 56,200 ETB\nTotal: 245,000 ETB", Icons.monetization_on, Colors.green),
        const SizedBox(height: 16),
        const Text("Occupancy Rates", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _occupancyRow("Sidama Home GH", 0.66),
        _occupancyRow("Lake View GH", 0.72),
        _occupancyRow("Tabor Mountain GH", 0.40),
        _occupancyRow("Hawassa City GH", 0.55),
        const SizedBox(height: 24),
        const Card(
          color: Color(0xFFE0F2F1),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.psychology, color: Colors.teal),
                SizedBox(width: 12),
                Expanded(child: Text("AI Insight: Lake View Guest House has strong occupancy due to its scenic location. Consider promoting Hawassa City Guest House with weekday corporate rates to improve midweek occupancy.", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: () => _showSnackbar("Export feature coming soon"), icon: const Icon(Icons.download), label: const Text("EXPORT DATA")),
      ],
    );
  }

  Widget _reportCard(String title, String content, IconData icon, Color color) => Card(
    child: ListTile(
      leading: Icon(icon, color: color, size: 32),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(content),
    ),
  );

  Widget _occupancyRow(String name, double rate) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(name), Text("${(rate * 100).toInt()}%")]),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: rate, backgroundColor: Colors.grey[200], color: Colors.teal),
      ],
    ),
  );

  Widget _buildAIAssistantTab() {
    final List<Map<String, dynamic>> messages = [
      {'text': "I'm the Guest House AI Assistant. Ask me about availability, revenue, occupancy rates, or recommendations.", 'isUser': false}
    ];
    final controller = TextEditingController();

    return StatefulBuilder(
      builder: (context, setChatState) {
        void handleSend() async {
          if (controller.text.isEmpty) return;
          String q = controller.text.toLowerCase();
          setChatState(() {
            messages.insert(0, {'text': controller.text, 'isUser': true});
          });
          controller.clear();

          String response = "I can help with guest house data. Try asking about rooms or revenue.";
          if (q.contains("available") || q.contains("rooms")) {
            response = "Currently available: Sidama Home (8), Lake View (10), Tabor Mountain (6), Hawassa City (14). Total: 38 rooms.";
          } else if (q.contains("revenue") || q.contains("income")) {
            response = "Guest house total revenue for today is 8,400 ETB across the city network.";
          } else if (q.contains("popular") || q.contains("best")) {
            response = "Lake View Guest House is currently most popular with a 72% average occupancy rate.";
          } else if (q.contains("occupancy") || q.contains("vacancy")) {
            response = "City-wide guest house occupancy is at 58%. Lake View has the highest at 72%.";
          } else if (q.contains("cheap") || q.contains("budget")) {
            response = "Hawassa City Guest House at 300 ETB/night is the most affordable option, great for budget travelers.";
          } else if (q.contains("recommend")) {
            response = "For lake views, Lake View GH is excellent. For nature lovers, Tabor Mountain GH is ideal. For central location, Hawassa City GH is best.";
          } else if (q.contains("predict") || q.contains("forecast")) {
            response = "Demand typically peaks during Ethiopian public holidays. Recommend ensuring maximum availability during Fichee-Chambalaala.";
          }

          setChatState(() {
            messages.insert(0, {'text': response, 'isUser': false});
          });
          await _flutterTts.speak(response);
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final m = messages[i];
                  return Align(
                    alignment: m['isUser'] ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: m['isUser'] ? Colors.teal[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(m['text']),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: "Ask guest house assistant..."))),
                      IconButton(icon: const Icon(Icons.send, color: Colors.teal), onPressed: handleSend),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _sendGuestAlert,
                    icon: const Icon(Icons.notifications_active),
                    label: const Text("SEND ALERT TO GUESTS"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 40)),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  void _sendGuestAlert() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Alert Guest House Guests"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Enter message...")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _firestore.collection("notifications").add({
                  'target': 'guest_house_guests',
                  'message': controller.text,
                  'timestamp': FieldValue.serverTimestamp(),
                  'type': 'guest_house_alert'
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSnackbar("Alert sent to all guests");
                }
              }
            },
            child: const Text("SEND"),
          ),
        ],
      ),
    );
  }

  void _deleteDoc(String collection, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Permanently remove this record?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(onPressed: () async {
            await _firestore.collection(collection).doc(id).delete();
            if (context.mounted) Navigator.pop(context);
          }, child: const Text("DELETE", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
