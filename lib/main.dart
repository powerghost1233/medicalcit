
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'firebase_options.dart';

const azul = Color(0xFF071F45);
const azul2 = Color(0xFF0B2F66);
const dorado = Color(0xFFC9A74D);
const fondo = Color(0xFF0D1117);
const card = Color(0xFF161B22);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PrototipoDavidCare());
}

class PrototipoDavidCare extends StatelessWidget {
  const PrototipoDavidCare({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrototipoDavid Care',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: fondo,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: dorado,
          primary: dorado,
          secondary: azul,
          surface: card,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: azul,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: card,
          indicatorColor: dorado.withOpacity(.18),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: card,
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: dorado, width: 1.4),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/* ================= AUTH ================= */

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.hasData ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;
  bool obscure = true;

  Future<void> login() async {
    if (email.text.trim().isEmpty || pass.text.trim().isEmpty) {
      msg('Rellena email y contraseña.');
      return;
    }
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      msg(e.message ?? 'Error al iniciar sesión.');
    } catch (e) {
      msg('Error inesperado: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  void msg(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                const PremiumHero(
                  title: 'PrototipoDavid Care',
                  subtitle: 'Interfaz fusionada: NadiaCare clínica + David Milán Academy premium.',
                  icon: Icons.health_and_safety,
                ),
                const SizedBox(height: 20),
                PremiumCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: pass,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => obscure = !obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GoldButton(text: 'Entrar', loading: loading, onPressed: login),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text('Crear nueva cuenta'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;
  bool obscure = true;

  Future<void> register() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || pass.text.trim().isEmpty) {
      msg('Rellena todos los campos.');
      return;
    }
    if (pass.text.trim().length < 6) {
      msg('La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    setState(() => loading = true);
    try {
      final c = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );
      final uid = c.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': name.text.trim(),
        'email': email.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      msg(e.message ?? 'Error al crear cuenta.');
    } catch (e) {
      msg('Error inesperado: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  void msg(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: PremiumCard(
              child: Column(
                children: [
                  const Icon(Icons.health_and_safety, color: dorado, size: 56),
                  const SizedBox(height: 10),
                  const Text('Registro PrototipoDavid Care', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 22),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline))),
                  const SizedBox(height: 14),
                  TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 14),
                  TextField(
                    controller: pass,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  GoldButton(text: 'Crear cuenta', loading: loading, onPressed: register),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ================= HOME ================= */

enum TabApp { dashboard, patients, appointments }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TabApp tab = TabApp.dashboard;
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  String search = '';
  String statusFilter = 'Todas';

  User get user => FirebaseAuth.instance.currentUser!;
  DocumentReference<Map<String, dynamic>> get userRef => FirebaseFirestore.instance.collection('users').doc(user.uid);
  CollectionReference<Map<String, dynamic>> get patientsRef => userRef.collection('patients');
  CollectionReference<Map<String, dynamic>> get appointmentsRef => userRef.collection('appointments');

  DateTime? parseDate(String? date) {
    if (date == null || date.trim().isEmpty) return null;
    try {
      final p = date.split('-');
      return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    } catch (_) {
      return null;
    }
  }

  DateTime? fullDate(Map<String, dynamic> d) {
    final date = parseDate(d['date']?.toString());
    if (date == null) return null;
    final time = (d['time'] ?? '').toString();
    if (time.contains(':')) {
      final p = time.split(':');
      return DateTime(date.year, date.month, date.day, int.tryParse(p[0]) ?? 0, int.tryParse(p[1]) ?? 0);
    }
    return date;
  }

  bool sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filterDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final q = search.trim().toLowerCase();
    return docs.where((doc) {
      final d = doc.data();
      final s = (d['status'] ?? 'pending').toString();
      final text = [
        d['patientName'] ?? '',
        d['specialty'] ?? '',
        d['hospital'] ?? '',
        d['doctor'] ?? '',
        d['tasks'] ?? '',
        d['observations'] ?? '',
      ].join(' ').toLowerCase();
      final okSearch = q.isEmpty || text.contains(q);
      final okStatus = statusFilter == 'Todas' ||
          (statusFilter == 'Pendientes' && s != 'completed') ||
          (statusFilter == 'Completadas' && s == 'completed');
      return okSearch && okStatus;
    }).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> docsForDay(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, DateTime day) {
    return docs.where((doc) {
      final date = parseDate(doc.data()['date']?.toString());
      return date != null && sameDate(date, day);
    }).toList();
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? nextAppointment(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    final up = docs.where((doc) {
      final d = doc.data();
      final dt = fullDate(d);
      return dt != null && dt.isAfter(now) && d['status'] != 'completed';
    }).toList();
    up.sort((a, b) => (fullDate(a.data()) ?? DateTime(3000)).compareTo(fullDate(b.data()) ?? DateTime(3000)));
    return up.isEmpty ? null : up.first;
  }

  String daysUntil(DateTime? date) {
    if (date == null) return 'Sin fecha';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff < 0) return 'Pasada';
    return 'Faltan $diff días';
  }

  Future<void> seedDemo() async {
    final batch = FirebaseFirestore.instance.batch();
    final patient = patientsRef.doc('nadia');
    batch.set(patient, {
      'name': 'Nadia',
      'birthDate': '',
      'phone': '',
      'notes': 'Paciente demo estilo NadiaCare.',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final appts = [
      {
        'id': 'nadia_cardiologia_2026_05_14_1330',
        'patientId': 'nadia',
        'patientName': 'Nadia',
        'specialty': 'Cardiología',
        'hospital': 'Hospital IMED',
        'doctor': '',
        'date': '2026-05-14',
        'time': '13:30',
        'status': 'pending',
        'category': 'Consulta',
        'tasks': 'Tiene que hacerse analítica. Se puede hacer en IMED Colón.',
        'observations': '',
      },
      {
        'id': 'nadia_traumatologia_2026_05_12_1730',
        'patientId': 'nadia',
        'patientName': 'Nadia',
        'specialty': 'Traumatología',
        'hospital': '',
        'doctor': 'Dr. Castañeda',
        'date': '2026-05-12',
        'time': '17:30',
        'status': 'pending',
        'category': 'Consulta',
        'tasks': 'Densitometría. 2 volantes para rehabilitación.',
        'observations': '',
      },
      {
        'id': 'nadia_urologia_2026_05_15_1300',
        'patientId': 'nadia',
        'patientName': 'Nadia',
        'specialty': 'Urología',
        'hospital': 'IMED Colón',
        'doctor': 'Dra. Casandra Sánchez',
        'date': '2026-05-15',
        'time': '13:00',
        'status': 'pending',
        'category': 'Consulta',
        'tasks': 'Ecografía vaginal 08/01/2026. Pendiente analítica.',
        'observations': '',
      },
    ];
    for (final a in appts) {
      batch.set(appointmentsRef.doc(a['id'] as String), {
        ...a,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo NadiaCare cargada')));
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (tab) {
      TabApp.dashboard => DashboardPage(
          appointmentsRef: appointmentsRef,
          nextAppointment: nextAppointment,
          fullDate: fullDate,
          daysUntil: daysUntil,
        ),
      TabApp.patients => PatientsPage(patientsRef: patientsRef),
      TabApp.appointments => AppointmentsPage(
          patientsRef: patientsRef,
          appointmentsRef: appointmentsRef,
          focusedDay: focusedDay,
          selectedDay: selectedDay,
          search: search,
          statusFilter: statusFilter,
          onFocusedDay: (v) => setState(() => focusedDay = v),
          onSelectedDay: (v) => setState(() => selectedDay = v),
          onSearch: (v) => setState(() => search = v),
          onStatus: (v) => setState(() => statusFilter = v),
          filterDocs: filterDocs,
          docsForDay: docsForDay,
          parseDate: parseDate,
          fullDate: fullDate,
          daysUntil: daysUntil,
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('PrototipoDavid Care'),
        actions: [
          IconButton(tooltip: 'Demo NadiaCare', onPressed: seedDemo, icon: const Icon(Icons.cloud_upload_outlined)),
          IconButton(tooltip: 'Salir', onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) => setState(() => tab = TabApp.values[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Pacientes'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Citas'),
        ],
      ),
    );
  }
}

/* ================= DASHBOARD ================= */

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.appointmentsRef,
    required this.nextAppointment,
    required this.fullDate,
    required this.daysUntil,
  });

  final CollectionReference<Map<String, dynamic>> appointmentsRef;
  final QueryDocumentSnapshot<Map<String, dynamic>>? Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>) nextAppointment;
  final DateTime? Function(Map<String, dynamic>) fullDate;
  final String Function(DateTime?) daysUntil;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: appointmentsRef.orderBy('date').snapshots(),
      builder: (_, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        final pending = docs.where((d) => d.data()['status'] != 'completed').length;
        final completed = docs.where((d) => d.data()['status'] == 'completed').length;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final week = docs.where((doc) {
          final dt = fullDate(doc.data());
          return dt != null && dt.isAfter(today.subtract(const Duration(seconds: 1))) && dt.isBefore(today.add(const Duration(days: 7)));
        }).length;
        final next = nextAppointment(docs);
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: PremiumHero(
                title: 'Panel médico privado',
                subtitle: 'Citas, pacientes y seguimiento con estética clínica NadiaCare y acabado premium David Milán Academy.',
                icon: Icons.local_hospital,
              ),
            ),
            NextAppointmentCard(doc: next, fullDate: fullDate, daysUntil: daysUntil),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(child: StatBox(title: 'Pendientes', value: '$pending', icon: Icons.pending_actions, color: dorado)),
                  const SizedBox(width: 10),
                  Expanded(child: StatBox(title: 'Completadas', value: '$completed', icon: Icons.check_circle, color: Colors.greenAccent)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(child: StatBox(title: 'Esta semana', value: '$week', icon: Icons.date_range, color: Colors.lightBlueAccent)),
                  const SizedBox(width: 10),
                  Expanded(child: StatBox(title: 'Total citas', value: '${docs.length}', icon: Icons.medical_services, color: Colors.purpleAccent)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/* ================= PATIENTS ================= */

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key, required this.patientsRef});
  final CollectionReference<Map<String, dynamic>> patientsRef;

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  Future<void> openPatient({String? id, Map<String, dynamic>? data}) async {
    final name = TextEditingController(text: data?['name'] ?? '');
    final birth = TextEditingController(text: data?['birthDate'] ?? '');
    final phone = TextEditingController(text: data?['phone'] ?? '');
    final notes = TextEditingController(text: data?['notes'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: fondo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_add_alt_1, color: dorado, size: 42),
                const SizedBox(height: 10),
                Text(id == null ? 'Nuevo paciente' : 'Editar paciente', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                DialogField(label: 'Nombre', controller: name),
                DialogField(label: 'Fecha nacimiento', controller: birth, readOnly: true, onTap: () => pickDate(birth)),
                DialogField(label: 'Teléfono', controller: phone),
                DialogField(label: 'Notas', controller: notes, maxLines: 3),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: dorado, foregroundColor: Colors.black),
                        onPressed: () async {
                          if (name.text.trim().isEmpty) return;
                          final d = {
                            'name': name.text.trim(),
                            'birthDate': birth.text.trim(),
                            'phone': phone.text.trim(),
                            'notes': notes.text.trim(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          };
                          if (id == null) {
                            await widget.patientsRef.add({...d, 'createdAt': FieldValue.serverTimestamp()});
                          } else {
                            await widget.patientsRef.doc(id).update(d);
                          }
                          if (mounted) Navigator.pop(context);
                        },
                        child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pickDate(TextEditingController c) async {
    final p = await showDatePicker(context: context, firstDate: DateTime(1900), lastDate: DateTime(2100), initialDate: DateTime.now());
    if (p != null) c.text = DateFormat('yyyy-MM-dd').format(p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: widget.patientsRef.orderBy('name').snapshots(),
        builder: (_, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Todavía no hay pacientes.'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final d = doc.data();
              return Card(
                color: card,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: azul, foregroundColor: Colors.white, child: Icon(Icons.person)),
                  title: Text(d['name'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text([
                    if ((d['birthDate'] ?? '').toString().isNotEmpty) 'Nacimiento: ${d['birthDate']}',
                    if ((d['phone'] ?? '').toString().isNotEmpty) 'Tel: ${d['phone']}',
                    if ((d['notes'] ?? '').toString().isNotEmpty) d['notes'],
                  ].join('\n')),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') openPatient(id: doc.id, data: d);
                      if (v == 'delete') widget.patientsRef.doc(doc.id).delete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Borrar')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openPatient(),
        icon: const Icon(Icons.add),
        label: const Text('Paciente'),
      ),
    );
  }
}

/* ================= APPOINTMENTS ================= */

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({
    super.key,
    required this.patientsRef,
    required this.appointmentsRef,
    required this.focusedDay,
    required this.selectedDay,
    required this.search,
    required this.statusFilter,
    required this.onFocusedDay,
    required this.onSelectedDay,
    required this.onSearch,
    required this.onStatus,
    required this.filterDocs,
    required this.docsForDay,
    required this.parseDate,
    required this.fullDate,
    required this.daysUntil,
  });

  final CollectionReference<Map<String, dynamic>> patientsRef;
  final CollectionReference<Map<String, dynamic>> appointmentsRef;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final String search;
  final String statusFilter;
  final ValueChanged<DateTime> onFocusedDay;
  final ValueChanged<DateTime> onSelectedDay;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onStatus;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>) filterDocs;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>, DateTime) docsForDay;
  final DateTime? Function(String?) parseDate;
  final DateTime? Function(Map<String, dynamic>) fullDate;
  final String Function(DateTime?) daysUntil;

  String selectedDateText() => '${selectedDay.day.toString().padLeft(2, '0')}/${selectedDay.month.toString().padLeft(2, '0')}/${selectedDay.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: appointmentsRef.orderBy('date').snapshots(),
        builder: (_, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final all = snap.data!.docs;
          final filtered = filterDocs(all);
          final selected = docsForDay(filtered, selectedDay);

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                child: Column(
                  children: [
                    TextField(
                      onChanged: onSearch,
                      decoration: const InputDecoration(hintText: 'Buscar por paciente, especialidad, hospital, médico...', prefixIcon: Icon(Icons.search)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final f in ['Todas', 'Pendientes', 'Completadas'])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: ChoiceChip(
                                label: Text(f),
                                selected: statusFilter == f,
                                selectedColor: dorado,
                                backgroundColor: card,
                                onSelected: (_) => onStatus(f),
                                labelStyle: TextStyle(color: statusFilter == f ? Colors.black : Colors.white, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              CalendarBox(
                docs: filtered,
                focusedDay: focusedDay,
                selectedDay: selectedDay,
                docsForDay: docsForDay,
                onSelected: (s, f) {
                  onSelectedDay(s);
                  onFocusedDay(f);
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(child: SummaryBox(title: 'Resultados filtrados', value: '${filtered.length}', icon: Icons.filter_alt)),
                    const SizedBox(width: 12),
                    Expanded(child: SummaryBox(title: 'Día elegido', value: '${selected.length}', icon: Icons.event_available)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(child: Text('Citas del ${selectedDateText()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                    Text('${selected.length}', style: const TextStyle(color: dorado, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              if (selected.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Center(child: Text('No hay citas para este día con los filtros actuales', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 16))),
                )
              else
                ...selected.map((doc) => AppointmentCard(
                      id: doc.id,
                      data: doc.data(),
                      appointmentsRef: appointmentsRef,
                      patientsRef: patientsRef,
                    )),
              const SizedBox(height: 90),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AppointmentDialog(patientsRef: patientsRef, appointmentsRef: appointmentsRef),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Cita'),
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.id,
    required this.data,
    required this.appointmentsRef,
    required this.patientsRef,
  });

  final String id;
  final Map<String, dynamic> data;
  final CollectionReference<Map<String, dynamic>> appointmentsRef;
  final CollectionReference<Map<String, dynamic>> patientsRef;

  @override
  Widget build(BuildContext context) {
    final completed = data['status'] == 'completed';
    return Card(
      color: card,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: completed ? Colors.greenAccent.withOpacity(.25) : dorado.withOpacity(.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(completed ? Icons.check_circle : Icons.local_hospital, color: completed ? Colors.greenAccent : dorado, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(data['specialty'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, decoration: completed ? TextDecoration.lineThrough : null))),
            StatusPill(completed: completed),
          ]),
          const SizedBox(height: 12),
          InfoLine(icon: Icons.person, text: 'Paciente: ${data['patientName'] ?? '—'}'),
          if ((data['hospital'] ?? '').toString().isNotEmpty) InfoLine(icon: Icons.apartment, text: 'Centro: ${data['hospital']}'),
          if ((data['doctor'] ?? '').toString().isNotEmpty) InfoLine(icon: Icons.badge, text: 'Doctor/a: ${data['doctor']}'),
          if ((data['date'] ?? '').toString().isNotEmpty || (data['time'] ?? '').toString().isNotEmpty) InfoLine(icon: Icons.event, text: 'Fecha: ${data['date'] ?? ''} ${data['time'] ?? ''}'),
          if ((data['tasks'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(data['tasks'], style: TextStyle(color: Colors.grey[400], height: 1.35)),
          ],
          if ((data['observations'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Observaciones: ${data['observations']}', style: TextStyle(color: Colors.grey[500], height: 1.35)),
          ],
          const SizedBox(height: 14),
          Wrap(alignment: WrapAlignment.end, spacing: 8, children: [
            TextButton.icon(
              onPressed: () => appointmentsRef.doc(id).update({'status': completed ? 'pending' : 'completed', 'updatedAt': FieldValue.serverTimestamp()}),
              icon: Icon(completed ? Icons.undo : Icons.check_circle_outline, color: completed ? Colors.orangeAccent : Colors.greenAccent),
              label: Text(completed ? 'Reabrir' : 'Completar', style: TextStyle(color: completed ? Colors.orangeAccent : Colors.greenAccent)),
            ),
            TextButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AppointmentDialog(patientsRef: patientsRef, appointmentsRef: appointmentsRef, docId: id, existingData: data),
              ),
              icon: const Icon(Icons.edit, color: dorado),
              label: const Text('Editar', style: TextStyle(color: dorado)),
            ),
            TextButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: card,
                    title: const Text('Eliminar cita'),
                    content: const Text('¿Seguro que quieres eliminar esta cita médica?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                );
                if (ok == true) appointmentsRef.doc(id).delete();
              },
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              label: const Text('Borrar', style: TextStyle(color: Colors.redAccent)),
            ),
          ]),
        ]),
      ),
    );
  }
}

class AppointmentDialog extends StatefulWidget {
  const AppointmentDialog({
    super.key,
    required this.patientsRef,
    required this.appointmentsRef,
    this.docId,
    this.existingData,
  });
  final CollectionReference<Map<String, dynamic>> patientsRef;
  final CollectionReference<Map<String, dynamic>> appointmentsRef;
  final String? docId;
  final Map<String, dynamic>? existingData;

  @override
  State<AppointmentDialog> createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<AppointmentDialog> {
  final specialty = TextEditingController();
  final hospital = TextEditingController();
  final doctor = TextEditingController();
  final date = TextEditingController();
  final time = TextEditingController();
  final tasks = TextEditingController();
  final observations = TextEditingController();
  String? patientId;
  String? patientName;
  bool loading = false;
  bool get editing => widget.docId != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existingData;
    if (d != null) {
      patientId = d['patientId'];
      patientName = d['patientName'];
      specialty.text = d['specialty'] ?? '';
      hospital.text = d['hospital'] ?? '';
      doctor.text = d['doctor'] ?? '';
      date.text = d['date'] ?? '';
      time.text = d['time'] ?? '';
      tasks.text = d['tasks'] ?? '';
      observations.text = d['observations'] ?? '';
    }
  }

  Future<void> save() async {
    if (patientId == null) {
      msg('Selecciona un paciente.');
      return;
    }
    if (specialty.text.trim().isEmpty) {
      msg('Introduce al menos la especialidad.');
      return;
    }
    setState(() => loading = true);
    try {
      final d = {
        'patientId': patientId,
        'patientName': patientName,
        'specialty': specialty.text.trim(),
        'hospital': hospital.text.trim(),
        'doctor': doctor.text.trim(),
        'date': date.text.trim(),
        'time': time.text.trim(),
        'status': widget.existingData?['status'] ?? 'pending',
        'category': 'Consulta',
        'tasks': tasks.text.trim(),
        'observations': observations.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (editing) {
        await widget.appointmentsRef.doc(widget.docId).update(d);
      } else {
        await widget.appointmentsRef.add({...d, 'createdAt': FieldValue.serverTimestamp()});
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      msg('Error guardando cita: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  void msg(String t) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> pickDate() async {
    final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (p != null) date.text = DateFormat('yyyy-MM-dd').format(p);
  }

  Future<void> pickTime() async {
    final p = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (p != null && mounted) time.text = '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: fondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(editing ? Icons.edit_calendar : Icons.medical_services, color: dorado, size: 42),
            const SizedBox(height: 10),
            Text(editing ? 'Editar cita médica' : 'Nueva cita médica', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: widget.patientsRef.orderBy('name').snapshots(),
              builder: (_, snap) {
                final patients = snap.data?.docs ?? [];
                return DropdownButtonFormField<String>(
                  value: patientId,
                  dropdownColor: card,
                  decoration: const InputDecoration(labelText: 'Paciente', prefixIcon: Icon(Icons.person)),
                  items: patients.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.data()['name'] ?? 'Sin nombre'))).toList(),
                  onChanged: (v) {
                    final selected = patients.where((d) => d.id == v).toList();
                    setState(() {
                      patientId = v;
                      patientName = selected.isEmpty ? 'Sin nombre' : selected.first.data()['name'];
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 14),
            DialogField(label: 'Especialidad', controller: specialty),
            DialogField(label: 'Hospital / Centro', controller: hospital),
            DialogField(label: 'Doctor/a', controller: doctor),
            Row(children: [
              Expanded(child: DialogField(label: 'Fecha', controller: date, readOnly: true, onTap: pickDate)),
              const SizedBox(width: 10),
              Expanded(child: DialogField(label: 'Hora', controller: time, readOnly: true, onTap: pickTime)),
            ]),
            DialogField(label: 'Tareas', controller: tasks, maxLines: 3),
            DialogField(label: 'Observaciones', controller: observations, maxLines: 3),
            const SizedBox(height: 10),
            GoldButton(text: editing ? 'Guardar cambios' : 'Guardar cita', loading: loading, onPressed: save),
          ]),
        ),
      ),
    );
  }
}

/* ================= UI WIDGETS ================= */

class PremiumHero extends StatelessWidget {
  const PremiumHero({super.key, required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [azul, azul2]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: azul.withOpacity(.28), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      child: Row(children: [
        Icon(icon, color: dorado, size: 48),
        const SizedBox(width: 18),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('DAVID MILÁN ACADEMY', style: TextStyle(color: Color(0xFFF6E7AA), fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.white70, height: 1.35)),
          ]),
        ),
      ]),
    );
  }
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(.07)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: child,
      );
}

class GoldButton extends StatelessWidget {
  const GoldButton({super.key, required this.text, required this.loading, required this.onPressed});
  final String text;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: dorado, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: loading
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
      );
}

class StatBox extends StatelessWidget {
  const StatBox({super.key, required this.title, required this.value, required this.icon, required this.color});
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(.26))),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ]),
          ),
        ]),
      );
}

class SummaryBox extends StatelessWidget {
  const SummaryBox({super.key, required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.06))),
        child: Row(children: [
          Icon(icon, color: dorado),
          const SizedBox(width: 10),
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ]),
          ),
        ]),
      );
}

class NextAppointmentCard extends StatelessWidget {
  const NextAppointmentCard({super.key, required this.doc, required this.fullDate, required this.daysUntil});
  final QueryDocumentSnapshot<Map<String, dynamic>>? doc;
  final DateTime? Function(Map<String, dynamic>) fullDate;
  final String Function(DateTime?) daysUntil;

  @override
  Widget build(BuildContext context) {
    if (doc == null) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(24), border: Border.all(color: dorado.withOpacity(.25))),
        child: const Row(children: [
          Icon(Icons.event_busy, color: dorado, size: 34),
          SizedBox(width: 14),
          Expanded(child: Text('No hay próximas citas pendientes con fecha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
        ]),
      );
    }
    final d = doc!.data();
    final date = fullDate(d);
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [azul, card]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dorado.withOpacity(.45)),
      ),
      child: Row(children: [
        const Icon(Icons.notification_important, color: dorado, size: 42),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PRÓXIMA CITA', style: TextStyle(color: dorado, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text(d['specialty'] ?? '', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${d['patientName'] ?? ''} · ${d['hospital'] ?? ''} ${d['doctor'] ?? ''}', style: TextStyle(color: Colors.grey[300])),
            const SizedBox(height: 4),
            Text('${d['date'] ?? ''} · ${d['time'] ?? ''}', style: TextStyle(color: Colors.grey[400])),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: dorado.withOpacity(.16), borderRadius: BorderRadius.circular(30), border: Border.all(color: dorado)),
          child: Text(daysUntil(date), style: const TextStyle(color: dorado, fontWeight: FontWeight.w900)),
        ),
      ]),
    );
  }
}

class CalendarBox extends StatelessWidget {
  const CalendarBox({super.key, required this.docs, required this.focusedDay, required this.selectedDay, required this.docsForDay, required this.onSelected});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>, DateTime) docsForDay;
  final void Function(DateTime selected, DateTime focused) onSelected;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(.05))),
        child: TableCalendar(
          locale: 'es_ES',
          focusedDay: focusedDay,
          firstDay: DateTime(2020),
          lastDay: DateTime(2035),
          startingDayOfWeek: StartingDayOfWeek.monday,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          eventLoader: (day) => docsForDay(docs, day),
          onDaySelected: onSelected,
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(color: azul, shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: dorado, shape: BoxShape.circle),
            markerDecoration: BoxDecoration(color: dorado, shape: BoxShape.circle),
            weekendTextStyle: TextStyle(color: Colors.redAccent),
            defaultTextStyle: TextStyle(color: Colors.white),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(weekdayStyle: TextStyle(color: Colors.white70), weekendStyle: TextStyle(color: Colors.redAccent)),
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
          ),
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.completed});
  final bool completed;
  @override
  Widget build(BuildContext context) {
    final c = completed ? Colors.greenAccent : dorado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: c.withOpacity(.14), borderRadius: BorderRadius.circular(30), border: Border.all(color: c)),
      child: Text(completed ? 'Completada' : 'Pendiente', style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w900)),
    );
  }
}

class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[300]))),
        ]),
      );
}

class DialogField extends StatelessWidget {
  const DialogField({super.key, required this.label, required this.controller, this.maxLines = 1, this.onTap, this.readOnly = false});
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final VoidCallback? onTap;
  final bool readOnly;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(controller: controller, readOnly: readOnly, onTap: onTap, maxLines: maxLines, decoration: InputDecoration(labelText: label)),
      );
}
