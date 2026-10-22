import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TourGuideRegistrationScreen extends StatefulWidget {
  const TourGuideRegistrationScreen({super.key});

  @override
  State<TourGuideRegistrationScreen> createState() => _TourGuideRegistrationScreenState();
}

class _TourGuideRegistrationScreenState extends State<TourGuideRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _emailC = TextEditingController();
  final _idC = TextEditingController();
  final _aboutC = TextEditingController();

  String _experience = '0-1 years';
  final List<String> _selectedLanguages = [];
  final List<String> _selectedSpecializations = [];

  final List<String> _languages = ['English', 'Amharic', 'Sidama', 'French', 'German', 'Arabic', 'Italian', 'Chinese'];
  final List<String> _specializations = ['Nature', 'Culture', 'Adventure', 'Historical', 'Food', 'Photography'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register as Tour Guide"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.teal.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Join Hawassa's tourism team and share your knowledge with visitors from around the world!",
                    style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(controller: _nameC, decoration: const InputDecoration(labelText: "Full Name"), validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 16),
              TextFormField(controller: _phoneC, decoration: const InputDecoration(labelText: "Phone"), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 16),
              TextFormField(controller: _emailC, decoration: const InputDecoration(labelText: "Email"), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 16),
              TextFormField(controller: _idC, decoration: const InputDecoration(labelText: "National ID Number"), validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _experience,
                decoration: const InputDecoration(labelText: "Years of Experience"),
                items: ['0-1 years', '1-3 years', '3-5 years', '5+ years'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _experience = v!),
              ),
              const SizedBox(height: 24),
              const Text("Languages", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: _languages.map((lang) {
                  final isSelected = _selectedLanguages.contains(lang);
                  return FilterChip(
                    label: Text(lang),
                    selected: isSelected,
                    onSelected: (v) => setState(() => v ? _selectedLanguages.add(lang) : _selectedLanguages.remove(lang)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text("Specializations", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: _specializations.map((spec) {
                  final isSelected = _selectedSpecializations.contains(spec);
                  return FilterChip(
                    label: Text(spec),
                    selected: isSelected,
                    onSelected: (v) => setState(() => v ? _selectedSpecializations.add(spec) : _selectedSpecializations.remove(spec)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _aboutC,
                decoration: const InputDecoration(labelText: "About Yourself", hintText: "Max 300 characters"),
                maxLines: 4,
                maxLength: 300,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitApplication,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Submit Application", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one language")));
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('tour_guides').add({
        'fullName': _nameC.text,
        'phone': _phoneC.text,
        'email': _emailC.text,
        'nationalId': _idC.text,
        'experience': _experience,
        'languages': _selectedLanguages,
        'about': _aboutC.text,
        'specializations': _selectedSpecializations,
        'userId': user?.uid,
        'status': "pending",
        'rating': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text("Application Submitted!"),
          content: const Text("We'll review and contact you within 2-3 business days."),
          actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("OK"))],
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
