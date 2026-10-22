import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/citizen_report_model.dart';
import '../services/api/citizen_reporting_api_service.dart';
import '../services/location_service.dart';
import '../services/firebase_storage_service.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class CitizenReportingScreen extends StatefulWidget {
  const CitizenReportingScreen({super.key});

  @override
  State<CitizenReportingScreen> createState() => _CitizenReportingScreenState();
}

class _CitizenReportingScreenState extends State<CitizenReportingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = 'Road Damage';
  bool _isSubmitting = false;
  
  final CitizenReportingApiService _apiService = CitizenReportingApiService();
  final LocationService _locationService = LocationService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  List<CitizenReport> _myReports = [];
  bool _isLoadingReports = false;

  final List<String> _categories = [
    'Road Damage',
    'Waste Problems',
    'Broken Street Lights',
    'Illegal Activities',
    'Public Service Issues',
    'Water Supply Leak',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadMyReports();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current location - this is required
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        throw Exception(
          'Location is needed so the city can find the problem. '
          'Please allow location in your browser/phone settings and try again.'
        );
      }

      // Upload photo if selected
      String? uploadedPhotoUrl;
      if (_selectedImage != null && _selectedImageBytes != null) {
        final isValid = await _storageService.validateImageBytes(
          bytes: _selectedImageBytes!,
          fileName: _selectedImage!.name,
        );
        if (isValid) {
          try {
            uploadedPhotoUrl = await _storageService.uploadPhotoBytes(
              bytes: _selectedImageBytes!,
              firebaseUid: user.uid,
              contentType: 'image/jpeg',
              category: 'citizen_reports',
            );
          } catch (uploadError) {
            // Photo upload failed - show error but allow continuing without photo
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Photo upload failed. You can try again, or submit the report without a photo.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
            // Remove the failed photo and continue without it
            setState(() {
              _selectedImage = null;
              _selectedImageBytes = null;
            });
            uploadedPhotoUrl = null;
          }
        }
      }

      // Normalize category to backend enum
      final normalizedCategory = CitizenReport.normalizeCategory(_selectedCategory);

      // Create report via API
      await _apiService.createReport(
        firebaseUid: user.uid,
        category: normalizedCategory,
        description: _descriptionController.text.trim(),
        photoUrl: uploadedPhotoUrl,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;
      
      // Clear form
      _descriptionController.clear();
      _locationController.clear();
      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
        _selectedCategory = 'Road Damage';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully! Thank you for your contribution.'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload reports
      _loadMyReports();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _loadMyReports() async {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) return;

    setState(() => _isLoadingReports = true);

    try {
      final reportsData = await _apiService.getMyReports(user.uid);
      setState(() {
        _myReports = reportsData.map((data) => CitizenReport.fromMap(data, data['id'].toString())).toList();
      });
    } catch (e) {
      print('Error loading reports: $e');
    } finally {
      setState(() => _isLoadingReports = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citizen Reporting'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report a City Issue',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Help us build a better Hawassa by reporting infrastructure or service issues in your neighborhood.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (Address or Landmark - Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                        hintText: 'e.g., Near Main Gate',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () async {
                      final position = await _locationService.getCurrentLocation();
                      if (position != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('GPS location captured')),
                        );
                      }
                    },
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Capture GPS Location',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Photo upload section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_camera, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 8),
                        const Text(
                          'Add Photo (Optional)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (_selectedImage != null)
                          IconButton(
                            onPressed: () => setState(() {
                              _selectedImage = null;
                              _selectedImageBytes = null;
                            }),
                            icon: const Icon(Icons.close),
                            tooltip: 'Remove photo',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedImageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImageBytes!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 100,
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Tap to add photo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Provide details about the issue...',
                ),
                validator: (v) => v!.isEmpty ? 'Please provide description' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.send),
                  label: const Text('SUBMIT REPORT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text('Your Previous Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildMyReports(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyReports() {
    if (_isLoadingReports) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myReports.isEmpty) {
      return const Text('No reports submitted yet.', style: TextStyle(color: Colors.grey));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _myReports.length,
      itemBuilder: (context, i) {
        final report = _myReports[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: _getCategoryIcon(report.category),
            title: Text(_getCategoryDisplay(report.category)),
            subtitle: Text('${report.statusDisplay} • ${_formatDate(report.createdAt)}'),
            trailing: _getStatusIcon(report.status),
          ),
        );
      },
    );
  }

  Widget _getCategoryIcon(String category) {
    switch (category) {
      case 'pothole':
        return const Icon(Icons.report_problem, color: Colors.orange);
      case 'garbage':
        return const Icon(Icons.delete, color: Colors.brown);
      case 'street_light':
        return const Icon(Icons.lightbulb, color: Colors.yellow);
      case 'water':
        return const Icon(Icons.water_drop, color: Colors.blue);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }

  String _getCategoryDisplay(String category) {
    switch (category) {
      case 'pothole':
        return 'Road Damage';
      case 'garbage':
        return 'Waste Problem';
      case 'street_light':
        return 'Broken Street Light';
      case 'water':
        return 'Water Issue';
      default:
        return 'Other Issue';
    }
  }

  Widget _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return const Icon(Icons.pending, color: Colors.orange);
      case ReportStatus.inProgress:
        return const Icon(Icons.autorenew, color: Colors.blue);
      case ReportStatus.resolved:
        return const Icon(Icons.check_circle, color: Colors.green);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
