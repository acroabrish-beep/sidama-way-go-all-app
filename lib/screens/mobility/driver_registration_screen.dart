import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/taxi_models.dart';
import '../../models/city_os_models.dart' as city;
import '../../services/taxi_service.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taxiService = TaxiService();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plateController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _licenseController = TextEditingController();
  final _vehicleModelController = TextEditingController();

  String _vehicleType = 'City Taxi';
  String? _selectedStationName;
  String? _selectedStationId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    _vehicleColorController.dispose();
    _licenseController.dispose();
    _vehicleModelController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _selectedStationName == null) {
      if (_selectedStationName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a station')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Check for duplicates
      final plateCheck = await FirebaseFirestore.instance
          .collection('drivers')
          .where('plateNumber', isEqualTo: _plateController.text.trim())
          .get();
      if (plateCheck.docs.isNotEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plate number already registered')));
        setState(() => _isSubmitting = false);
        return;
      }

      final phoneCheck = await FirebaseFirestore.instance
          .collection('drivers')
          .where('phone', isEqualTo: _phoneController.text.trim())
          .get();
      if (phoneCheck.docs.isNotEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number already registered')));
        setState(() => _isSubmitting = false);
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? '';

      final driver = TaxiDriver(
        workerId: uid,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        email: user?.email ?? '',
        photo: '',
        governmentId: '',
        licenseNumber: _licenseController.text,
        assignedVehicleId: _plateController.text,
        assignedHubId: _selectedStationId ?? '',
        role: _vehicleType.toLowerCase().contains('bajaj')
            ? WorkforceRole.bajajDriver
            : (_vehicleType.toLowerCase().contains('bus') ? WorkforceRole.busDriver : WorkforceRole.taxiDriver),
        governmentApproval: city.ApprovalStatus.approved,
        lifecycleStatus: WorkforceLifecycleStatus.active,
        online: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _taxiService.registerDriver(driver);

      // After saving driver to Firestore, also add to queue:
      await FirebaseFirestore.instance.collection('queues').add({
        'plateNumber': _plateController.text.trim(),
        'driverName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'station': _selectedStationName, // station name
        'stationId': _selectedStationId, // added stationId
        'status': 'waiting',
        'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'joinTime': FieldValue.serverTimestamp(),
        'vehicleType': _vehicleType,
      });

      // Save vehicle for backward compatibility or as requested
      await FirebaseFirestore.instance.collection('vehicles').add({
        'plateNumber': _plateController.text,
        'vehicleType': _vehicleType,
        'driverName': _fullNameController.text,
        'ownerName': _fullNameController.text,
        'route': _selectedStationName,
        'status': 'Active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Registration Successful'),
            content: Text('Registration successful! You are now in the queue at $_selectedStationName. Your position will be shown when you join the queue screen.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Taxi Driver', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFE65100),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                const SizedBox(height: 16),
                _buildTextField(_fullNameController, 'Full Name', Icons.person),
                const SizedBox(height: 12),
                _buildTextField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildTextField(_licenseController, 'License Number', Icons.card_membership),

                const SizedBox(height: 24),
                const Text('Vehicle Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                const SizedBox(height: 16),
                _buildTextField(_plateController, 'Plate Number (e.g. HW-34567)', Icons.pin_outlined),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _vehicleType,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: ['City Taxi', 'Minibus', 'Bajaj'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _vehicleType = v!),
                ),
                const SizedBox(height: 12),
                _buildTextField(_vehicleColorController, 'Vehicle Color', Icons.color_lens_outlined),

                const SizedBox(height: 24),
                const Text('Station Assignment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                const SizedBox(height: 16),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('taxi_stations').where('status', isEqualTo: 'Active').get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: LinearProgressIndicator());
                    }
                    final stations = snapshot.data?.docs ?? [];
                    if (stations.isEmpty) return const Text('No active stations available. Please contact admin.', style: TextStyle(color: Colors.red));

                    return DropdownButtonFormField<String>(
                      hint: const Text('Select Pickup Station'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.place),
                      ),
                      items: stations.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] as String;
                        return DropdownMenuItem(value: doc.id, child: Text(name));
                      }).toList(),
                      onChanged: (id) {
                        final doc = stations.firstWhere((d) => d.id == id);
                        final data = doc.data() as Map<String, dynamic>;
                        setState(() {
                          _selectedStationId = id;
                          _selectedStationName = data['name'];
                        });
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    );
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                    ),
                    child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('REGISTER NOW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      validator: (v) => v == null || v.isEmpty ? 'This field is required' : null,
    );
  }
}
