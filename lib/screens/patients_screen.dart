import 'package:flutter/material.dart';

import '../models/patient_model.dart';
import '../services/firestore_service.dart';
import '../widgets/app_drawer.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Pacientes')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPatientDialog(context, service),
        label: const Text('Nuevo paciente'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<PatientModel>>(
        stream: service.patientsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final patients = snapshot.data ?? [];

          if (patients.isEmpty) {
            return const Center(child: Text('No hay pacientes todavía.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final p = patients[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text([
                    if (p.relation.isNotEmpty) p.relation,
                    if (p.phone.isNotEmpty) p.phone,
                    if (p.notes.isNotEmpty) p.notes,
                  ].join(' · ')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => service.deletePatient(p.id!),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPatientDialog(BuildContext context, FirestoreService service) {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo paciente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 10),
              TextField(controller: relationCtrl, decoration: const InputDecoration(labelText: 'Relación')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Notas')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await service.addPatient(PatientModel(
                name: nameCtrl.text.trim(),
                relation: relationCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              ));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
