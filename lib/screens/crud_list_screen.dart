import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/glass_card.dart';
import '../widgets/paginated_list.dart';

import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as custom_auth;

class CRUDListScreen extends StatefulWidget {
  final String collection;
  final String title;
  final List<String> fields;
  final Map<String, dynamic>? initialData; // Fixed values like 'terminal' or 'department'

  const CRUDListScreen({
    super.key,
    required this.collection,
    required this.title,
    required this.fields,
    this.initialData,
  });

  @override
  State<CRUDListScreen> createState() => _CRUDListScreenState();
}

class _CRUDListScreenState extends State<CRUDListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF2E7D32)],
          ),
        ),
        child: PaginatedFirestoreListView(
          query: FirebaseFirestore.instance.collection(widget.collection).orderBy('createdAt', descending: true),
          itemBuilder: (context, doc) {
            final data = doc.data() as Map<String, dynamic>;

            return GlassCard(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(
                  data[widget.fields.first]?.toString() ?? 'Unnamed',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.fields.skip(1).map((f) {
                    final val = data[f]?.toString() ?? 'N/A';
                    return Text('$f: $val', style: const TextStyle(color: Colors.white70, fontSize: 12));
                  }).toList(),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () => _showEditDialog(context, doc),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _confirmDelete(context, doc),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null),
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              doc.reference.delete();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, DocumentSnapshot? doc) {
    final Map<String, TextEditingController> controllers = {
      for (var f in widget.fields)
        f: TextEditingController(
          text: doc != null ? (doc.data() as Map<String, dynamic>)[f]?.toString() ?? '' : '',
        )
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc == null ? 'Add New ${widget.title}' : 'Edit ${widget.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.fields.map((f) {
              if (f == 'terminal') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: DropdownButtonFormField<String>(
                    initialValue: controllers[f]!.text.isEmpty ? null : controllers[f]!.text,
                    decoration: const InputDecoration(labelText: 'TERMINAL', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Hawassa Old Terminal', child: Text('Hawassa Old Terminal')),
                      DropdownMenuItem(value: 'Hawassa New Terminal', child: Text('Hawassa New Terminal')),
                    ],
                    onChanged: (v) => controllers[f]!.text = v ?? '',
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TextField(
                  controller: controllers[f],
                  decoration: InputDecoration(
                    labelText: f.replaceAll('_', ' ').toUpperCase(),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: (f == 'fare' || f == 'price' || f == 'capacity' || f == 'phone') ? TextInputType.number : TextInputType.text,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              for (var c in controllers.values) {
                c.dispose();
              }
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = Provider.of<custom_auth.AuthProvider>(context, listen: false).userModel;

                final Map<String, dynamic> newData = {
                  for (var f in widget.fields)
                    f: (f == 'fare' || f == 'price' || f == 'capacity')
                        ? (num.tryParse(controllers[f]!.text) ?? 0)
                        : controllers[f]!.text,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (doc == null) {
                  // Attach common metadata on creation
                  newData['createdAt'] = FieldValue.serverTimestamp();
                  newData['createdBy'] = user?.uid ?? 'anonymous';
                  newData['creatorRole'] = user?.role.name ?? 'unknown';
                  newData['isActive'] = true;

                  // Merge initialData (e.g., terminal: 'Hawassa Old Terminal')
                  if (widget.initialData != null) {
                    newData.addAll(widget.initialData!);
                  }

                  await FirebaseFirestore.instance.collection(widget.collection).add(newData);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.title} saved!')));
                  }
                } else {
                  await doc.reference.update(newData);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.title} updated!')));
                  }
                }

                for (var c in controllers.values) {
                  c.dispose();
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
