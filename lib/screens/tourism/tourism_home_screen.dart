import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../utils/language_provider.dart';
import '../../models/city_os_models.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import 'tourist_sites_screen.dart';
import 'tour_packages_screen.dart';
import 'tour_guides_screen.dart';
import 'contract_ride_screen.dart';
import 'tour_operator_registration_screen.dart';
import 'tour_guide_registration_screen.dart';
import 'tourism_dashboard_screen.dart';
import '../ai_assistant_screen.dart';

class TourismHomeScreen extends StatefulWidget {
  const TourismHomeScreen({super.key});

  @override
  State<TourismHomeScreen> createState() => _TourismHomeScreenState();
}

class _TourismHomeScreenState extends State<TourismHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Demo seeding is debug-only.
    if (kDebugMode) _seedInitialData();
  }

  Future<void> _seedInitialData() async {
    try {
      final snapshot = await _firestore
          .collection('tourist_sites')
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        final List<Map<String, dynamic>> initialSites = [
          {
            "name": "Lake Hawassa",
            "description":
                "Beautiful rift valley lake with stunning bird life and boat rides.",
            "category": "Nature",
            "lat": 7.0639,
            "lng": 38.4813,
            "rating": 4.9,
            "openingHours": "6:00 AM - 6:00 PM",
            "entryFee": "Free",
            "isActive": true,
            "images": [],
          },
          {
            "name": "Amora Gedel Park",
            "description":
                "Famous bird sanctuary and fish market at the lake shore.",
            "category": "Nature",
            "lat": 7.0639,
            "lng": 38.4813,
            "rating": 4.8,
            "openingHours": "5:30 AM - 6:00 PM",
            "entryFee": "Free",
            "isActive": true,
            "images": [],
          },
          {
            "name": "Tabor Mountain",
            "description":
                "Scenic hiking trails with panoramic views of Hawassa.",
            "category": "Adventure",
            "lat": 7.0633,
            "lng": 38.5183,
            "rating": 4.7,
            "openingHours": "6:00 AM - 6:00 PM",
            "entryFee": "Free",
            "isActive": true,
            "images": [],
          },
          {
            "name": "Gudumale Cultural Center",
            "description":
                "UNESCO heritage site for Fichee-Chambalaala Sidama New Year.",
            "category": "Culture",
            "lat": 7.0504,
            "lng": 38.4955,
            "rating": 4.8,
            "openingHours": "8:00 AM - 5:00 PM",
            "entryFee": "50 ETB",
            "isActive": true,
            "images": [],
          },
          {
            "name": "Fish Market",
            "description":
                "Vibrant lakeside market with fresh daily Tilapia catch.",
            "category": "Food",
            "lat": 7.0639,
            "lng": 38.4813,
            "rating": 4.6,
            "openingHours": "5:00 AM - 10:00 AM",
            "entryFee": "Free",
            "isActive": true,
            "images": [],
          },
          {
            "name": "Haile Resort",
            "description":
                "Luxury lakeside resort with pool, spa and lake views.",
            "category": "Luxury",
            "lat": 7.0639,
            "lng": 38.4813,
            "rating": 4.9,
            "openingHours": "24 Hours",
            "entryFee": "Free",
            "isActive": true,
            "images": [],
          },
          {
            "name": "Millennium Park",
            "description":
                "Beautiful public park in the heart of Hawassa city.",
            "category": "Nature",
            "lat": 7.0504,
            "lng": 38.4955,
            "rating": 4.5,
            "openingHours": "7:00 AM - 8:00 PM",
            "entryFee": "20 ETB",
            "isActive": true,
            "images": [],
          },
          {
            "name": "Sidama Cultural Village",
            "description":
                "Traditional homestead with local crafts and coffee ceremony.",
            "category": "Culture",
            "lat": 7.0504,
            "lng": 38.5050,
            "rating": 4.7,
            "openingHours": "8:00 AM - 6:00 PM",
            "entryFee": "100 ETB",
            "isActive": true,
            "images": [],
          },
        ];
        for (var site in initialSites) {
          await _firestore.collection('tourist_sites').add(site);
        }
      }
    } catch (e) {
      debugPrint("Error seeding initial data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final role = Provider.of<AuthProvider>(context, listen: false).userModel?.role;
    final bool isAdmin = role == UserRole.superAdmin || role == UserRole.tourismAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🗺️ Hawassa Tourism"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TourismDashboardScreen(),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroBanner(),
            _buildQuickActions(context),
            _buildSectionHeader(
              lang.t('popular_sites'),
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TouristSitesScreen()),
              ),
            ),
            _buildTouristSites(),
            _buildSectionHeader("🎪 Events & Festivals", () => {}),
            _buildUpcomingEvents(),
            _buildPartnerRegistration(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text("Ask AI", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Discover Hawassa",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            "Explore nature, culture & adventure",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatChip("8 Sites"),
              _buildStatChip("12 Guides"),
              _buildStatChip("6 Packages"),
              _buildStatChip("3 Events"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildActionCard(
            "🗺️ Tourist Sites",
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TouristSitesScreen()),
            ),
          ),
          _buildActionCard(
            "📦 Tour Packages",
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TourPackagesScreen()),
            ),
          ),
          _buildActionCard(
            "👨‍💼 Tour Guides",
            Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TourGuidesScreen()),
            ),
          ),
          _buildActionCard(
            "🚗 Hire Vehicle",
            Colors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContractRideScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title.split(" ")[0], style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title.substring(title.indexOf(" ") + 1),
              style: TextStyle(
                color: color.withAlpha(200),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          TextButton(onPressed: onTap, child: const Text("View All")),
        ],
      ),
    );
  }

  Widget _buildTouristSites() {
    return SizedBox(
      height: 250,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('tourist_sites')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text("No sites found."));
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final site = TouristSite.fromMap(
                docs[index].data() as Map<String, dynamic>,
                docs[index].id,
              );
              return _buildSiteCard(site);
            },
          );
        },
      ),
    );
  }

  Widget _buildSiteCard(TouristSite site) {
    Color color;
    String emoji;
    switch (site.category) {
      case "Nature":
        color = Colors.green;
        emoji = "🌿";
        break;
      case "Adventure":
        color = Colors.orange;
        emoji = "⛰️";
        break;
      case "Culture":
        color = Colors.brown;
        emoji = "🎭";
        break;
      case "Food":
        color = Colors.red;
        emoji = "🍽️";
        break;
      case "Luxury":
        color = Colors.purple;
        emoji = "🏨";
        break;
      default:
        color = Colors.teal;
        emoji = "📍";
    }

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const Spacer(),
          Text(
            site.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.yellowAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                site.rating.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              site.entryFee,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
              ),
              child: const Text("Explore"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('events').orderBy('date').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("No upcoming events"),
          );
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final event = TouristEvent.fromMap(
              docs[index].data() as Map<String, dynamic>,
              docs[index].id,
            );
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                  ),
                ],
                border: const Border(
                  left: BorderSide(color: Colors.blue, width: 4),
                ),
              ),
              child: ListTile(
                title: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${event.location} • ${_formatDate(event.date)}",
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Widget _buildPartnerRegistration() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TourGuideRegistrationScreen(),
                ),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text(
                "👨‍💼 Register as Guide",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TourOperatorRegistrationScreen(),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
              ),
              child: const Text(
                "🏢 Register as Operator",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
