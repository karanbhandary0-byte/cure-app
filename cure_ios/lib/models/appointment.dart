import 'user.dart';

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

class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime scheduledAt;
  final String? reason;
  final String status;
  final int tokenNumber;
  final bool? feedbackSubmitted;
  final int? queuePosition;
  final String? estimatedStartTime;
  final String? doctorName;
  final String? clinicName;
  final String? patientName;
  final String? patientPhone;
  final Doctor? doctor;
  final Patient? patient;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.scheduledAt,
    this.reason,
    required this.status,
    this.tokenNumber = 1,
    this.feedbackSubmitted,
    this.queuePosition,
    this.estimatedStartTime,
    this.doctorName,
    this.clinicName,
    this.patientName,
    this.patientPhone,
    this.doctor,
    this.patient,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      scheduledAt: _parseDateTime(json['scheduled_at']),
      reason: json['reason']?.toString(),
      status: json['status']?.toString() ?? 'scheduled',
      tokenNumber: (json['token_number'] is int)
          ? json['token_number']
          : int.tryParse(json['token_number']?.toString() ?? '1') ?? 1,
      feedbackSubmitted: json['feedback_submitted'] as bool?,
      queuePosition: (json['queue_position'] is int)
          ? json['queue_position']
          : int.tryParse(json['queue_position']?.toString() ?? ''),
      estimatedStartTime: json['estimated_start_time']?.toString(),
      doctorName: json['doctor_name']?.toString(),
      clinicName: json['clinic_name']?.toString(),
      patientName: json['patient_name']?.toString(),
      patientPhone: json['patient_phone']?.toString(),
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
      patient: json['patient'] != null ? Patient.fromJson(json['patient']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'patient_id': patientId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'reason': reason,
      'status': status,
      'token_number': tokenNumber,
      'feedback_submitted': feedbackSubmitted,
      'queue_position': queuePosition,
      'estimated_start_time': estimatedStartTime,
      'doctor_name': doctorName,
      'clinic_name': clinicName,
      'patient_name': patientName,
      'patient_phone': patientPhone,
      'doctor': doctor?.toJson(),
      'patient': patient?.toJson(),
    };
  }
}
