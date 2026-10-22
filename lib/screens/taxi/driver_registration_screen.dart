import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/taxi_models.dart';
import '../../models/city_os_models.dart' as city;
import '../../services/taxi_service.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taxiService = TaxiService();

  final _fullNameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _emailC = TextEditingController();
  final _plateC = TextEditingController();
  final _modelC = TextEditingController();
  final _colorC = TextEditingController();
  final _licenseC = TextEditingController();
  final _idC = TextEditingController();
  final _insuranceC = TextEditingController();
  final _emergencyC = TextEditingController();

  String _vehicleType = 'Standard';
  TaxiStation? _selectedStation;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Registration'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Professional Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField(_fullNameC, 'Full Name', Icons.person),
                    _buildField(
                      _phoneC,
                      'Phone Number',
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildField(
                      _emailC,
                      'Email Address',
                      Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildField(_idC, 'National ID Number', Icons.badge),
                    _buildField(
                      _licenseC,
                      'Driving License Number',
                      Icons.card_membership,
                    ),
                    _buildField(
                      _insuranceC,
                      'Insurance Number',
                      Icons.security,
                    ),
                    _buildField(
                      _emergencyC,
                      'Emergency Contact',
                      Icons.contact_emergency,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Vehicle Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField(_plateC, 'Plate Number', Icons.numbers),
                    _buildField(
                      _modelC,
                      'Vehicle Model (e.g. Toyota Vitz)',
                      Icons.car_repair,
                    ),
                    _buildField(_colorC, 'Vehicle Color', Icons.color_lens),
                    DropdownButtonFormField<String>(
                      value: _vehicleType,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Type',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: ['Standard', 'Luxury', 'Van', 'Bajaj']
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _vehicleType = v!),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<TaxiStation>>(
                      stream: _taxiService.getTaxiStations(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const LinearProgressIndicator();
                        final stations = snapshot.data!;
                        if (_selectedStation == null && stations.isNotEmpty) {
                          _selectedStation = stations.first;
                        }
                        return DropdownButtonFormField<TaxiStation>(
                          value: _selectedStation,
                          decoration: const InputDecoration(
                            labelText: 'Preferred Taxi Station',
                            prefixIcon: Icon(Icons.place),
                          ),
                          items: stations
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedStation = v),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'SUBMIT APPLICATION',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your application will be reviewed by the city taxi administration and you will be notified once approved.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a station')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Check for duplicates
      final plateCheck = await FirebaseFirestore.instance
          .collection('drivers')
          .where('plateNumber', isEqualTo: _plateC.text.trim())
          .get();
      if (plateCheck.docs.isNotEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plate number already registered')));
        setState(() => _isLoading = false);
        return;
      }

      final phoneCheck = await FirebaseFirestore.instance
          .collection('drivers')
          .where('phone', isEqualTo: _phoneC.text.trim())
          .get();
      if (phoneCheck.docs.isNotEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number already registered')));
        setState(() => _isLoading = false);
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not authenticated';

      final driver = TaxiDriver(
        workerId: user.uid,
        fullName: _fullNameC.text,
        phone: _phoneC.text,
        email: _emailC.text,
        photo: '',
        governmentId: _idC.text,
        licenseNumber: _licenseC.text,
        assignedVehicleId: _plateC.text,
        assignedHubId: _selectedStation!.id,
        role: _vehicleType.toLowerCase().contains('bajaj') ? WorkforceRole.bajajDriver : WorkforceRole.taxiDriver,
        governmentApproval: city.ApprovalStatus.pending,
        lifecycleStatus: WorkforceLifecycleStatus.registration,
        online: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _taxiService.registerDriver(driver);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'role': 'taxi_driver', 'isDriverPending': true},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
