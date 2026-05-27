class PatientModel {
  final String? id;
  final String name;
  final String relation;
  final String phone;
  final String notes;

  const PatientModel({
    this.id,
    required this.name,
    this.relation = '',
    this.phone = '',
    this.notes = '',
  });

  factory PatientModel.fromFirestore(String id, Map<String, dynamic> data) {
    return PatientModel(
      id: id,
      name: data['name'] ?? '',
      relation: data['relation'] ?? '',
      phone: data['phone'] ?? '',
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relation': relation,
      'phone': phone,
      'notes': notes,
    };
  }
}
