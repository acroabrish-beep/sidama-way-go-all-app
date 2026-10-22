import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../widgets/role_protected_widget.dart';

class ServiceAdminDashboard extends StatefulWidget {
  final UserRole role;
  final String serviceName;
  const ServiceAdminDashboard({super.key, required this.role, required this.serviceName});

  @override
  State<ServiceAdminDashboard> createState() => _ServiceAdminDashboardState();
}

class _ServiceAdminDashboardState extends State<ServiceAdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return RoleProtectedWidget(
      allowedRoles: [widget.role, UserRole.superAdmin],
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.serviceName} Admin'),
          backgroundColor: _getRoleColor(widget.role),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () => _showAIAssistant(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildQuickActions(context),
              const SizedBox(height: 20),
              _buildDataManagement(context),
              const SizedBox(height: 20),
              _buildAnalyticsPreview(context),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.oldTerminalAdmin:
      case UserRole.newTerminalAdmin:
        return Colors.teal;
      case UserRole.healthAdmin: return Colors.redAccent;
      case UserRole.tourismAdmin: return Colors.green;
      case UserRole.businessAdmin: return Colors.orange;
      case UserRole.pharmacyAdmin: return Colors.purple;
      case UserRole.emergencyAdmin: return Colors.red;
      case UserRole.taxiAdmin: return Colors.blue;
      default: return Colors.blueGrey;
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(Icons.add_a_photo, 'Upload Photo'),
        _actionButton(Icons.description, 'Upload Doc'),
        _actionButton(Icons.notification_add, 'Notify Users'),
        _actionButton(Icons.summarize, 'Report'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(radius: 25, backgroundColor: Colors.grey[200], child: Icon(icon, color: Colors.black87)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildDataManagement(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const ListTile(
            title: Text('Record Management', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Manage items, prices, and status'),
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text('Sample Record ${index + 1}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () {}),
                ],
              ),
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('VIEW ALL RECORDS')),
        ],
      ),
    );
  }

  Widget _buildAnalyticsPreview(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
      child: const Center(
        child: Text('Service Specific Analytics Chart Here'),
      ),
    );
  }

  void _showAIAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('AI Service Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'Insights for today:\n\n- Performance is up by 12% compared to last Tuesday.\n- High demand predicted for the next 2 hours.\n- Recommend updating price records for season 2.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('DISMISS')),
          ],
        ),
      ),
    );
  }
}
