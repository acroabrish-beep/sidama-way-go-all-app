import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'ai_assistant_screen.dart';

class HealthcareScreen extends StatelessWidget {
  const HealthcareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HEALTHCARE HUB')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('QUICK ACTIONS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildAction('Book Appointment', Icons.calendar_month, Colors.blue),
                const SizedBox(width: 12),
                _buildAction('Ambulance', Icons.emergency, Colors.red),
                const SizedBox(width: 12),
                _buildAction('Tele-Health', Icons.video_call, Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            const Text('NEARBY HOSPITALS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            _buildHospitalList(),
            const SizedBox(height: 32),
            const Text('SPECIALISTS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            _buildDoctorListStream(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text('Ask AI', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHospitalList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('hospitals').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Text('No hospitals found.', style: TextStyle(color: Colors.grey));

        return Column(
          children: snapshot.data!.docs.map((doc) {
            return _buildHospitalCard(context, doc);
          }).toList(),
        );
      },
    );
  }

  void _bookAppointment(BuildContext context, DocumentSnapshot hospitalDoc) {
    final h = hospitalDoc.data() as Map<String, dynamic>? ?? {};
    final hospitalName = h['name'] as String? ?? 'Hospital';
    final reasonC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointment: $hospitalName'),
        content: TextField(controller: reasonC, decoration: const InputDecoration(labelText: 'Reason for visit')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final user = Provider.of<AuthProvider>(context, listen: false).userModel;
              await FirebaseFirestore.instance.collection('appointments').add({
                'hospitalId': hospitalDoc.id,
                'hospitalName': hospitalName,
                'patientName': user?.fullName ?? 'Patient',
                'patientPhone': user?.phone ?? 'N/A',
                'reason': reasonC.text,
                'status': 'pending',
                'userId': user?.uid,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment requested!')));
            },
            child: const Text('BOOK'),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(BuildContext context, DocumentSnapshot doc) {
    final h = doc.data() as Map<String, dynamic>? ?? {};
    final name = h['name'] as String? ?? 'Hospital';
    final location = h['location'] as String? ?? 'Hawassa';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.red.withValues(alpha: 0.1), child: const Icon(Icons.local_hospital, color: Colors.red)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(location),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _bookAppointment(context, doc),
      ),
    );
  }

  Widget _buildAction(String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorListStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Text('No doctors available.', style: TextStyle(color: Colors.grey));

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>? ?? {};
            final name = d['name'] as String? ?? 'Dr. Name';
            final specialty = d['specialty'] as String? ?? 'Specialist';
            final rating = (d['rating'] as num? ?? 5.0).toString();

            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(name),
                subtitle: Text(specialty),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(' $rating'),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
