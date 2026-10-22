import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/taxi_demo_provider.dart';
import '../models/demo_ride_model.dart';
import '../models/demo_taxi_model.dart';
import '../services/taxi_demo_service.dart';
import '../widgets/glass_card.dart';

class TaxiDemoScreen extends StatefulWidget {
  const TaxiDemoScreen({super.key});

  @override
  State<TaxiDemoScreen> createState() => _TaxiDemoScreenState();
}

class _TaxiDemoScreenState extends State<TaxiDemoScreen> {
  final MapController _mapController = MapController();
  final LatLng _hawassaCenter = const LatLng(7.0622, 38.4763);

  @override
  Widget build(BuildContext context) {
    final demoProvider = Provider.of<TaxiDemoProvider>(context);

    // Auto-center map on taxi during movement
    if (demoProvider.currentTaxiLocation != null && 
        (demoProvider.status == DemoRideStatus.approaching || demoProvider.status == DemoRideStatus.inProgress)) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) {
           _mapController.move(demoProvider.currentTaxiLocation!, _mapController.camera.zoom);
         }
       });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PUBLIC TAXI DEMO'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              demoProvider.reset();
              _mapController.move(_hawassaCenter, 14.0);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _hawassaCenter,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              if (demoProvider.pickup != null && demoProvider.destination != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [demoProvider.pickup!.coordinates, demoProvider.destination!.coordinates],
                      color: Colors.blue.withValues(alpha: 0.5),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: _buildMarkers(demoProvider),
              ),
            ],
          ),

          // 2. Demo Mode Indicator
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'DEMO MODE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),

          // 3. UI Overlay
          if (demoProvider.status == DemoRideStatus.idle)
            _buildSelectionPanel(demoProvider)
          else
            _buildStatusPanel(demoProvider),
            
          // 4. Demo Controls
          _buildDemoControls(demoProvider),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(TaxiDemoProvider provider) {
    List<Marker> markers = [];

    if (provider.pickup != null) {
      markers.add(Marker(
        point: provider.pickup!.coordinates,
        width: 40,
        height: 40,
        child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
      ));
    }

    if (provider.destination != null) {
      markers.add(Marker(
        point: provider.destination!.coordinates,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    }

    if (provider.status == DemoRideStatus.idle || provider.status == DemoRideStatus.searching) {
      for (var taxi in provider.fleet) {
        markers.add(Marker(
          point: taxi.location,
          width: 30,
          height: 30,
          child: Icon(Icons.local_taxi, color: _getTaxiColor(taxi.id), size: 24),
        ));
      }
    } else if (provider.selectedTaxi != null && provider.currentTaxiLocation != null) {
       markers.add(Marker(
          point: provider.currentTaxiLocation!,
          width: 50,
          height: 50,
          child: Column(
            children: [
              const Text('TAXI', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, backgroundColor: Colors.white)),
              Icon(Icons.local_taxi, color: _getTaxiColor(provider.selectedTaxi!.id), size: 30),
            ],
          ),
        ));
    }

    return markers;
  }

  Color _getTaxiColor(String id) {
    if (id == 'T-01') return Colors.blue;
    if (id == 'T-02') return Colors.yellow[700]!;
    if (id == 'T-03') return Colors.green;
    if (id == 'T-04') return Colors.grey[700]!;
    if (id == 'T-05') return Colors.blue;
    if (id == 'T-06') return Colors.yellow[700]!;
    return Colors.black;
  }

  Widget _buildSelectionPanel(TaxiDemoProvider provider) {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WHERE TO?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _buildLocationDropdown(
              label: 'Pickup',
              value: provider.pickup,
              onChanged: (loc) => provider.setPickup(loc!),
            ),
            const SizedBox(height: 12),
            _buildLocationDropdown(
              label: 'Destination',
              value: provider.destination,
              onChanged: (loc) => provider.setDestination(loc!),
            ),
            const SizedBox(height: 24),
            if (provider.pickup != null && provider.destination != null) ...[
               _buildFareEstimate(provider),
               const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (provider.pickup != null && provider.destination != null) ? () => provider.findTaxi() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('FIND TAXI', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDropdown({required String label, DemoLocation? value, required ValueChanged<DemoLocation?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DemoLocation>(
          isExpanded: true,
          hint: Text(label, style: const TextStyle(color: Colors.white70)),
          value: value,
          dropdownColor: Colors.indigo[900],
          style: const TextStyle(color: Colors.white),
          items: TaxiDemoService.hawassaLocations.map((loc) {
            return DropdownMenuItem(
              value: loc,
              child: Text(loc.name),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFareEstimate(TaxiDemoProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Distance', style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text('${provider.distanceRemainingKm.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Est. Time', style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text('${provider.etaMinutes} min', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Est. Fare', style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text('${provider.estimatedFare.toStringAsFixed(0)} ETB', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusPanel(TaxiDemoProvider provider) {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: _buildStatusContent(provider),
      ),
    );
  }

  Widget _buildStatusContent(TaxiDemoProvider provider) {
    switch (provider.status) {
      case DemoRideStatus.searching:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('AI is finding the best taxi for you...', style: TextStyle(color: Colors.white)),
          ],
        );
      case DemoRideStatus.matched:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🤖 AI TAXI MATCHING', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTaxiDetailTile(provider.selectedTaxi!),
            const SizedBox(height: 12),
            Text(provider.aiSelectionReason, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => provider.startApproaching(),
                child: const Text('ACCEPT & CALL'),
              ),
            ),
          ],
        );
      case DemoRideStatus.approaching:
      case DemoRideStatus.arrived:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.status == DemoRideStatus.arrived ? '✅ TAXI ARRIVED' : '🚕 TAXI IS COMING...', style: TextStyle(color: provider.status == DemoRideStatus.arrived ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTaxiDetailTile(provider.selectedTaxi!),
            const Divider(color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Distance: ${provider.distanceRemainingKm.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white)),
                Text('ETA: ${provider.etaMinutes} min', style: const TextStyle(color: Colors.white)),
              ],
            ),
            if (provider.status == DemoRideStatus.arrived) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => provider.startRide(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('START DEMO RIDE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        );
      case DemoRideStatus.inProgress:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🚕 TRIP IN PROGRESS', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Destination', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    Text(provider.destination!.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Fare', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    Text('${provider.estimatedFare.toStringAsFixed(0)} ETB', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: 1 - (provider.distanceRemainingKm / TaxiDemoService.calculateDistance(provider.pickup!.coordinates, provider.destination!.coordinates))),
            const SizedBox(height: 8),
            Text('${provider.distanceRemainingKm.toStringAsFixed(1)} km remaining | ${provider.etaMinutes} min left', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        );
      case DemoRideStatus.completed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            const Text('RIDE COMPLETED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 16),
            _buildFareEstimate(provider),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => provider.reset(),
                child: const Text('DONE'),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTaxiDetailTile(DemoTaxi taxi) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getTaxiColor(taxi.id).withValues(alpha: 0.2),
        child: Icon(Icons.local_taxi, color: _getTaxiColor(taxi.id)),
      ),
      title: Text(taxi.driverName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text('${taxi.vehicleType} | ${taxi.plateNumber}', style: const TextStyle(color: Colors.white70)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 16),
          Text(taxi.rating.toString(), style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildDemoControls(TaxiDemoProvider provider) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.settings, color: Colors.white)),
            onPressed: () => _showDemoControls(context, provider),
          ),
        ],
      ),
    );
  }

  void _showDemoControls(BuildContext context, TaxiDemoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DEMO CONTROLS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Reset Demo'),
              onTap: () {
                provider.reset();
                _mapController.move(_hawassaCenter, 14.0);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
