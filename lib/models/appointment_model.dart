class AppointmentModel {
  final String? id;
  final String patientName;
  final String specialty;
  final String hospital;
  final String doctor;
  final String date;
  final String time;
  final String status;
  final String tasks;
  final String observations;

  const AppointmentModel({
    this.id,
    required this.patientName,
    required this.specialty,
    this.hospital = '',
    this.doctor = '',
    required this.date,
    this.time = '',
    this.status = 'pending',
    this.tasks = '',
    this.observations = '',
  });

  factory AppointmentModel.fromFirestore(String id, Map<String, dynamic> data) {
    return AppointmentModel(
      id: id,
      patientName: data['patientName'] ?? '',
      specialty: data['specialty'] ?? '',
      hospital: data['hospital'] ?? '',
      doctor: data['doctor'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      status: data['status'] ?? 'pending',
      tasks: data['tasks'] ?? '',
      observations: data['observations'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientName': patientName,
      'specialty': specialty,
      'hospital': hospital,
      'doctor': doctor,
      'date': date,
      'time': time,
      'status': status,
      'tasks': tasks,
      'observations': observations,
    };
  }
}
