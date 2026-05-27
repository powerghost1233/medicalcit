import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/appointment_model.dart';
import '../models/patient_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _db.collection('users').doc(uid).collection('patients');

  CollectionReference<Map<String, dynamic>> get _appointmentsRef =>
      _db.collection('users').doc(uid).collection('appointments');

  Future<void> ensureUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<PatientModel>> patientsStream() {
    return _patientsRef.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => PatientModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addPatient(PatientModel patient) async {
    await _patientsRef.add({
      ...patient.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePatient(PatientModel patient) async {
    if (patient.id == null) return;
    await _patientsRef.doc(patient.id).update({
      ...patient.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePatient(String id) async {
    await _patientsRef.doc(id).delete();
  }

  Stream<List<AppointmentModel>> appointmentsStream() {
    return _appointmentsRef.orderBy('date').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AppointmentModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addAppointment(AppointmentModel appointment) async {
    await _appointmentsRef.add({
      ...appointment.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAppointment(AppointmentModel appointment) async {
    if (appointment.id == null) return;
    await _appointmentsRef.doc(appointment.id).update({
      ...appointment.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAppointment(String id) async {
    await _appointmentsRef.doc(id).delete();
  }
}
