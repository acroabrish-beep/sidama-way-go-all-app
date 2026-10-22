import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../widgets/paginated_list.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _toggleUserStatus(String uid, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';
    await _db.collection('users').doc(uid).update({'status': newStatus});
  }

  void _changeRole(String uid, UserRole newRole) async {
    await _db.collection('users').doc(uid).update({'role': newRole.name});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: PaginatedFirestoreListView(
        query: _db.collection('users').orderBy('fullName'),
        itemBuilder: (context, doc) {
          final userData = doc.data() as Map<String, dynamic>;
          final user = UserModel.fromMap(userData, doc.id);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(user.fullName),
              subtitle: Text('${user.email}\nRole: ${user.role.name}'),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(user.status == 'active' ? Icons.check_circle : Icons.block, color: user.status == 'active' ? Colors.green : Colors.red),
                    onPressed: () => _toggleUserStatus(user.uid, user.status),
                  ),
                  PopupMenuButton<UserRole>(
                    onSelected: (role) => _changeRole(user.uid, role),
                    itemBuilder: (context) => UserRole.values.map((role) => PopupMenuItem(
                      value: role,
                      child: Text(role.name),
                    )).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
