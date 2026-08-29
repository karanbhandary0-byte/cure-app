DateTime _parseDateTime(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is DateTime) return val;
  try {
    final dyn = val as dynamic;
    if (dyn.toDate != null) {
      return dyn.toDate() as DateTime;
    }
  } catch (_) {}
  return DateTime.tryParse(val.toString()) ?? DateTime.now();
}

class PatientFeedbackItem {
  final String id;
  final String appointmentId;
  final String? doctorId;
  final String patientId;
  final String? patientName;
  final DateTime createdAt;
  final bool feelingBetter;
  final bool medicationHelped;
  final bool symptomsUnchanged;
  final bool symptomsWorsened;
  final String? sideEffects;
  final int severity;
  final String? notes;
  final String recommendation;
  final int? rating;
  final List<String>? tags;
  final String? comments;

  PatientFeedbackItem({
    required this.id,
    required this.appointmentId,
    this.doctorId,
    required this.patientId,
    this.patientName,
    required this.createdAt,
    this.feelingBetter = false,
    this.medicationHelped = false,
    this.symptomsUnchanged = false,
    this.symptomsWorsened = false,
    this.sideEffects,
    this.severity = 5,
    this.notes,
    this.recommendation = 'continue_medication',
    this.rating,
    this.tags,
    this.comments,
  });

  factory PatientFeedbackItem.fromJson(Map<String, dynamic> json) {
    return PatientFeedbackItem(
      id: json['id']?.toString() ?? '',
      appointmentId: json['appointment_id']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString(),
      patientId: json['patient_id']?.toString() ?? '',
      patientName: json['patient_name']?.toString(),
      createdAt: _parseDateTime(json['created_at']),
      feelingBetter: json['feeling_better'] == true,
      medicationHelped: json['medication_helped'] == true,
      symptomsUnchanged: json['symptoms_unchanged'] == true,
      symptomsWorsened: json['symptoms_worsened'] == true,
      sideEffects: json['side_effects']?.toString(),
      severity: json['severity'] is int
          ? json['severity']
          : (int.tryParse(json['severity']?.toString() ?? '5') ?? 5),
      notes: json['notes']?.toString(),
      recommendation: json['recommendation']?.toString() ?? 'continue_medication',
      rating: json['rating'] is int ? json['rating'] : int.tryParse(json['rating']?.toString() ?? ''),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
      comments: json['comments']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'doctor_id': doctorId,
      'patient_id': patientId,
      'patient_name': patientName,
      'created_at': createdAt.toIso8601String(),
      'feeling_better': feelingBetter,
      'medication_helped': medicationHelped,
      'symptoms_unchanged': symptomsUnchanged,
      'symptoms_worsened': symptomsWorsened,
      'side_effects': sideEffects,
      'severity': severity,
      'notes': notes,
      'recommendation': recommendation,
      'rating': rating,
      'tags': tags,
      'comments': comments,
    };
  }
}
