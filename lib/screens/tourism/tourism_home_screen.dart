import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hotel_tourism_models.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api/base_api_service.dart';
import '../../services/api/tourism_api_service.dart';
import '../../utils/language_provider.dart';
import '../../widgets/tourism_phase2_widgets.dart';
import '../ai_assistant_screen.dart';
import '../hotel_screen.dart';
import 'tourism_dashboard_screen.dart';
import 'tourist_sites_screen.dart';

class TourismHomeScreen extends StatefulWidget {
  const TourismHomeScreen({super.key});

  @override
  State<TourismHomeScreen> createState() => _TourismHomeScreenState();
}

class _TourismHomeScreenState extends State<TourismHomeScreen> {
  final TourismApiService _service = TourismApiService();

  List<TourismSiteModel>? _sites;
  List<HotelModel>? _hotels;
  Object? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final (sites, hotels) = await (
        _service.getTouristSites(),
        _service.getHotels(),
      ).wait;
      if (!mounted) return;
      setState(() {
        _sites = sites;
        _hotels = hotels;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (_sites == null || _hotels == null) {
        setState(() {
          _error = error;
          _loading = false;
        });
        return;
      }
      setState(() => _loading = false);
      final message = error is ApiException
          ? error.message
          : 'Could not refresh tourism data. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
      );
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  Future<void> _openSites() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TouristSitesScreen()),
    );
    if (!mounted) return;
    _load();
  }

  void _openNotMigrated(String module, IconData icon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(module),
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
          ),
          body: Phase2NotMigratedPanel(module: module, icon: icon),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final role =
        Provider.of<AuthProvider>(context, listen: false).userModel?.role;
    final isAdmin =
        role == UserRole.superAdmin || role == UserRole.tourismAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hawassa Tourism'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh tourism data',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          if (isAdmin)
            IconButton(
              tooltip: 'Tourism dashboard',
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroBanner(),
              if (_error != null && (_sites == null || _hotels == null))
                _buildError()
              else ...[
                _buildQuickActions(context),
                _buildSectionHeader(
                  lang.t('popular_sites'),
                  _openSites,
                ),
                _buildTouristSites(),
                _buildSectionHeader('Hotels & Lodging', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HotelScreen()),
                  );
                }),
                _buildHotels(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Phase2NotMigratedBanner(
                    module: 'Events & festivals',
                    icon: Icons.event,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Phase2NotMigratedBanner(
                    module: 'Guide & operator registration',
                    icon: Icons.badge,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text('Ask AI', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildError() {
    final message = _error is ApiException
        ? (_error as ApiException).message
        : 'Could not load tourism data. Please try again.';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _retry, child: const Text('TRY AGAIN')),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 190,
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
            'Discover Hawassa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Explore nature, culture & adventure',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatChip(
                _sites == null ? 'Sites: …' : '${_sites!.length} Sites',
              ),
              _buildStatChip(
                _hotels == null ? 'Hotels: …' : '${_hotels!.length} Hotels',
              ),
              _buildStatChip('Live Supabase data'),
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
        childAspectRatio: 1.25,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildActionCard(
            Icons.landscape,
            'Tourist Sites',
            Colors.green,
            _openSites,
          ),
          _buildActionCard(
            Icons.hotel,
            'Hotels & Lodging',
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HotelScreen()),
            ),
          ),
          _buildActionCard(
            Icons.inventory_2,
            'Tour Packages',
            Colors.blue,
            () => _openNotMigrated('Tour Packages', Icons.inventory_2),
            enabled: false,
          ),
          _buildActionCard(
            Icons.badge,
            'Tour Guides',
            Colors.teal,
            () => _openNotMigrated('Tour Guides', Icons.badge),
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    final tint = enabled ? color : Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tint.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: tint),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: enabled ? color : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (!enabled)
              const Text(
                'Phase 2 pending',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          TextButton(onPressed: onTap, child: const Text('View All')),
        ],
      ),
    );
  }

  Widget _buildTouristSites() {
    if (_sites == null) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_sites!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No tourist sites have been published yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _sites!.length,
        itemBuilder: (context, index) => _buildSiteCard(_sites![index]),
      ),
    );
  }

  Widget _buildSiteCard(TourismSiteModel site) {
    final (icon, color) = _categoryVisual(site.category);
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
          Icon(icon, color: Colors.white, size: 30),
          const Spacer(),
          Text(
            site.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
                site.ratingLabel,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  site.categoryLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
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
              site.entryFeeLabel,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showSiteDetails(site),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 30),
              ),
              child: const Text('Explore'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSiteDetails(TourismSiteModel site) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(site.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${site.categoryLabel} · ${site.ratingLabel} ★',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (site.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(site.description),
              ],
              const SizedBox(height: 8),
              Text('Entry: ${site.entryFeeLabel}'),
              Text(
                'Hours: ${site.openingHours.isEmpty ? 'Not listed' : site.openingHours}',
              ),
              if (site.address.isNotEmpty) Text('Address: ${site.address}'),
              Text('Coordinates: ${site.coordinatesLabel}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildHotels() {
    if (_hotels == null) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hotels!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No hotels have been published yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _hotels!.length,
        itemBuilder: (context, index) => _buildHotelCard(_hotels![index]),
      ),
    );
  }

  Widget _buildHotelCard(HotelModel hotel) {
    final available = hotel.availableRooms.length;
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hotel, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hotel.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hotel.locationLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            '★ ${hotel.ratingLabel} · $available room'
            '${available == 1 ? '' : 's'} available',
            style: const TextStyle(fontSize: 12),
          ),
          const Spacer(),
          Text(
            hotel.lowestAvailableRate == null
                ? 'No rooms available'
                : 'From ${formatAmount(hotel.lowestAvailableRate)} ETB / night',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HotelScreen()),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('VIEW ROOMS'),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _categoryVisual(String category) {
    switch (category) {
      case 'natural':
        return (Icons.landscape, Colors.green);
      case 'historical':
        return (Icons.account_balance, Colors.brown);
      case 'cultural':
        return (Icons.theater_comedy, Colors.orange);
      case 'religious':
        return (Icons.church, Colors.deepPurple);
      case 'entertainment':
        return (Icons.celebration, Colors.pink);
      case 'shopping':
        return (Icons.shopping_bag, Colors.blue);
      case 'dining':
        return (Icons.restaurant, Colors.red);
      default:
        return (Icons.place, Colors.teal);
    }
  }
}
