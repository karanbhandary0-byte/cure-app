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

class Consultation {
  final String id;
  final String appointmentId;
  final String? patientId;
  final String? patientName;
  final String diagnosis;
  final String prescription;
  final String? prescriptionImageUrl;
  final String? followUpInstructions;
  final String? followUpDate;
  final DateTime createdAt;
  final Doctor? doctor;

  Consultation({
    required this.id,
    required this.appointmentId,
    this.patientId,
    this.patientName,
    required this.diagnosis,
    required this.prescription,
    this.prescriptionImageUrl,
    this.followUpInstructions,
    this.followUpDate,
    required this.createdAt,
    this.doctor,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id']?.toString() ?? '',
      appointmentId: json['appointment_id']?.toString() ?? '',
      patientId: json['patient_id']?.toString(),
      patientName: json['patient_name']?.toString() ?? json['patient']?['name']?.toString(),
      diagnosis: json['diagnosis']?.toString() ?? '',
      prescription: json['prescription']?.toString() ?? '',
      prescriptionImageUrl: json['prescription_image_url']?.toString(),
      followUpInstructions: json['follow_up_instructions']?.toString(),
      followUpDate: json['follow_up_date']?.toString(),
      createdAt: _parseDateTime(json['created_at']),
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'patient_id': patientId,
      'patient_name': patientName,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'prescription_image_url': prescriptionImageUrl,
      'follow_up_instructions': followUpInstructions,
      'follow_up_date': followUpDate,
      'created_at': createdAt.toIso8601String(),
      'doctor': doctor?.toJson(),
    };
  }
}
