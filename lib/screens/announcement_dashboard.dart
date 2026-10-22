import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/dashboard_base.dart';
import '../widgets/glass_card.dart';
import '../widgets/ai_insights_card.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AnnouncementDashboard extends StatefulWidget {
  const AnnouncementDashboard({super.key});

  @override
  State<AnnouncementDashboard> createState() => _AnnouncementDashboardState();
}

class _AnnouncementDashboardState extends State<AnnouncementDashboard> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'City Update';
  final FlutterTts _tts = FlutterTts();

  final List<String> _categories = [
    'City Update',
    'Emergency',
    'Traffic',
    'Tourism',
    'Health',
    'Event'
  ];

  void _publishAnnouncement() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) return;

    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    await FirebaseFirestore.instance.collection('announcements').add({
      'title': _titleController.text,
      'message': _messageController.text,
      'category': _selectedCategory,
      'createdBy': user?.fullName,
      'department': user?.role.name,
      'isActive': true,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _titleController.clear();
    _messageController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement published to all citizens.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardBase(
      title: 'City Announcement Center',
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: AIInsightsCard(dashboardContext: 'announcements', title: '🤖 Announcement AI Insights'),
        ),
        const Text(
          'Publish New Announcement',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: const Color(0xFF1A237E),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                style: const TextStyle(color: Colors.white),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _publishAnnouncement,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
                  child: const Text('PUBLISH NOW', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Recent Announcements',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        _buildRecentList(),
      ],
    );
  }

  Widget _buildRecentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('announcements').orderBy('timestamp', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final bool isActive = data['isActive'] ?? true;
            return GlassCard(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                title: Text(data['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(data['message'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.orangeAccent),
                      onPressed: () => _tts.speak("${data['title']}. ${data['message']}"),
                      tooltip: 'Speak Announcement',
                    ),
                    IconButton(
                      icon: Icon(isActive ? Icons.visibility : Icons.visibility_off, color: isActive ? Colors.greenAccent : Colors.grey),
                      onPressed: () => doc.reference.update({'isActive': !isActive}),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      onPressed: () => doc.reference.delete(),
                    ),
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
