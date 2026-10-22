import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../screens/splash_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/crud_list_screen.dart';
import '../screens/ai_assistant_screen.dart';

class DashboardBase extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const DashboardBase({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ...?actions,
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'Ask AI',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF2E7D32)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: children,
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildDrawer(BuildContext context, UserModel? user) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1A237E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF283593)],
                ),
              ),
              accountName: Text(user?.fullName ?? 'Admin', style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: const Text('SIDAMA WAY GO – Smart City Digital Platform', style: TextStyle(fontSize: 10, color: Colors.white70)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'A',
                  style: const TextStyle(fontSize: 40.0, color: Color(0xFF1A237E)),
                ),
              ),
            ),
            _drawerItem(context, 'Dashboard', Icons.dashboard, () => Navigator.pop(context)),
            if (user?.role == UserRole.superAdmin) ...[
              const Divider(color: Colors.white24),
              _drawerItem(context, 'User Management', Icons.people, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()));
              }),
              _drawerItem(context, 'Citizen Reports', Icons.report_problem, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => CRUDListScreen(
                  collection: 'citizen_reports',
                  title: 'Citizen Reports',
                  fields: ['category', 'status', 'description', 'location', 'userName'],
                )));
              }),
              _drawerItem(context, 'Audit Logs', Icons.history, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => CRUDListScreen(
                  collection: 'audit_logs',
                  title: 'Audit Logs',
                  fields: ['action', 'user', 'timestamp', 'details'],
                )));
              }),
              _drawerItem(context, 'System Logs', Icons.list_alt, () {}),
            ],
            const Divider(color: Colors.white24),
            _drawerItem(context, 'Profile', Icons.person, () {}),
            _drawerItem(context, 'Settings', Icons.settings, () {}),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
