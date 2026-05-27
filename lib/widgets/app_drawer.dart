import 'package:flutter/material.dart';

import '../screens/appointments_screen.dart';
import '../screens/home_screen.dart';
import '../screens/patients_screen.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              title: Text(
                'PrototipoDavid Care',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text('Gestión médica privada'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Home'),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Pacientes'),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PatientsScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Citas'),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
              ),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () => AuthService().logout(),
            ),
          ],
        ),
      ),
    );
  }
}
