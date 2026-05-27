import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment_model.dart';
import '../models/patient_model.dart';
import '../services/firestore_service.dart';
import '../widgets/app_drawer.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Citas')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAppointmentDialog(context, service),
        label: const Text('Nueva cita'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: service.appointmentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return const Center(child: Text('No hay citas todavía.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final a = appointments[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${a.patientName} · ${a.specialty}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => service.deleteAppointment(a.id!),
                          ),
                        ],
                      ),
                      Text('${a.date}${a.time.isNotEmpty ? ' · ${a.time}' : ''}'),
                      if (a.hospital.isNotEmpty) Text('Hospital: ${a.hospital}'),
                      if (a.doctor.isNotEmpty) Text('Doctor/a: ${a.doctor}'),
                      if (a.tasks.isNotEmpty) Text('Tareas: ${a.tasks}'),
                      if (a.observations.isNotEmpty) Text('Observaciones: ${a.observations}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAppointmentDialog(BuildContext context, FirestoreService service) {
    final specialtyCtrl = TextEditingController();
    final hospitalCtrl = TextEditingController();
    final doctorCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final tasksCtrl = TextEditingController();
    final observationsCtrl = TextEditingController();
    String? selectedPatientName;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Nueva cita'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<List<PatientModel>>(
                    stream: service.patientsStream(),
                    builder: (context, snapshot) {
                      final patients = snapshot.data ?? [];
                      return DropdownButtonFormField<String>(
                        initialValue: selectedPatientName,
                        decoration: const InputDecoration(labelText: 'Paciente'),
                        items: patients
                            .map((p) => DropdownMenuItem(value: p.name, child: Text(p.name)))
                            .toList(),
                        onChanged: (value) => setState(() => selectedPatientName = value),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: specialtyCtrl, decoration: const InputDecoration(labelText: 'Especialidad')),
                  const SizedBox(height: 10),
                  TextField(controller: hospitalCtrl, decoration: const InputDecoration(labelText: 'Hospital / Clínica')),
                  const SizedBox(height: 10),
                  TextField(controller: doctorCtrl, decoration: const InputDecoration(labelText: 'Doctor/a')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Fecha', suffixIcon: Icon(Icons.calendar_month)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDate: DateTime.now(),
                      );
                      if (picked != null) {
                        dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Hora, ej. 13:30')),
                  const SizedBox(height: 10),
                  TextField(controller: tasksCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Tareas')),
                  const SizedBox(height: 10),
                  TextField(controller: observationsCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Observaciones')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if ((selectedPatientName ?? '').isEmpty || specialtyCtrl.text.trim().isEmpty || dateCtrl.text.trim().isEmpty) return;
                  await service.addAppointment(AppointmentModel(
                    patientName: selectedPatientName!,
                    specialty: specialtyCtrl.text.trim(),
                    hospital: hospitalCtrl.text.trim(),
                    doctor: doctorCtrl.text.trim(),
                    date: dateCtrl.text.trim(),
                    time: timeCtrl.text.trim(),
                    tasks: tasksCtrl.text.trim(),
                    observations: observationsCtrl.text.trim(),
                  ));
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
