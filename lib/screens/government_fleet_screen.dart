import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/role_protected_widget.dart';
import '../models/user_model.dart';
import '../models/city_os_models.dart';
import '../widgets/paginated_list.dart';

class GovernmentFleetScreen extends StatelessWidget {
  const GovernmentFleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleProtectedWidget(
      allowedRoles: const [UserRole.superAdmin, UserRole.governmentFleetAdmin],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Government Fleet'),
          backgroundColor: const Color(0xFF1B263B),
          foregroundColor: Colors.white,
        ),
        body: PaginatedFirestoreListView(
          query: FirebaseFirestore.instance.collection(CityOSCollection.governmentVehicles).orderBy('name'),
          emptyWidget: const Center(child: Text('No government vehicles registered.')),
          itemBuilder: (context, doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Vehicle';
            final type = data['type'] ?? 'General';
            final status = data['status'] ?? 'Idle';

            Color statusColor = Colors.green;
            if (status == 'Maintenance') statusColor = Colors.orange;
            if (status == 'Idle') statusColor = Colors.grey;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(
                  type == 'Bus' ? Icons.directions_bus :
                  type == 'Emergency' ? Icons.medical_services : Icons.settings,
                  color: const Color(0xFF1B263B),
                ),
                title: Text(name),
                subtitle: Text('Type: $type'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
