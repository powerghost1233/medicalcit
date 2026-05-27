import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../widgets/app_drawer.dart';
import 'appointments_screen.dart';
import 'patients_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Panel principal')),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hero(),
            const SizedBox(height: 16),
            StreamBuilder(
              stream: service.patientsStream(),
              builder: (context, patientsSnap) {
                return StreamBuilder(
                  stream: service.appointmentsStream(),
                  builder: (context, appointmentsSnap) {
                    final patientsCount = patientsSnap.data?.length ?? 0;
                    final appointmentsCount = appointmentsSnap.data?.length ?? 0;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _statCard('Pacientes', patientsCount.toString(), Icons.people),
                        _statCard('Citas', appointmentsCount.toString(), Icons.calendar_month),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            _actionCard(
              context,
              title: 'Pacientes',
              subtitle: 'Crear y consultar perfiles de pacientes.',
              icon: Icons.people,
              screen: const PatientsScreen(),
            ),
            _actionCard(
              context,
              title: 'Citas médicas',
              subtitle: 'Gestionar consultas, tareas y observaciones.',
              icon: Icons.calendar_month,
              screen: const AppointmentsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF071F45), Color(0xFF0B2F66)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAVID MILÁN ACADEMY',
            style: TextStyle(
              color: Color(0xFFF6E7AA),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.7,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'PrototipoDavid Care',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'App privada multiusuario para gestionar pacientes, citas y seguimiento médico.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFC9A74D)),
              const SizedBox(height: 10),
              Text(label),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF071F45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget screen,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF071F45),
          foregroundColor: Colors.white,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        ),
      ),
    );
  }
}
