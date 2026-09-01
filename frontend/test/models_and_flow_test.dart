import 'package:flutter_test/flutter_test.dart';
import 'package:cure_flutter/models/appointment.dart';
import 'package:cure_flutter/models/consultation.dart';
import 'package:cure_flutter/models/feedback.dart';
import 'package:cure_flutter/models/analytics.dart';
import 'package:cure_flutter/models/user.dart';

void main() {
  group('Model Serialization & Null Safety Tests', () {
    test('Appointment deserializes safely with missing or dynamic fields', () {
      final appt = Appointment.fromJson({
        'id': 'appt_123',
        'doctor_id': 'doc_456',
        'patient_id': 'pat_789',
        'scheduled_at': '2026-08-29T10:00:00.000Z',
        'status': 'booked',
        'token_number': '5',
        'patient_name': 'John Doe',
      });

      expect(appt.id, 'appt_123');
      expect(appt.doctorId, 'doc_456');
      expect(appt.patientId, 'pat_789');
      expect(appt.status, 'booked');
      expect(appt.tokenNumber, 5);
      expect(appt.patientName, 'John Doe');
      expect(appt.scheduledAt.year, 2026);
    });

    test('Consultation deserializes safely without throwing FormatException', () {
      final c = Consultation.fromJson({
        'id': 'cons_123',
        'appointment_id': 'appt_123',
        'diagnosis': 'Viral flu',
        'prescription': 'Paracetamol 500mg',
        'follow_up_instructions': 'Drink plenty of water',
        'created_at': '2026-08-29T10:30:00.000Z',
      });

      expect(c.id, 'cons_123');
      expect(c.diagnosis, 'Viral flu');
      expect(c.prescription, 'Paracetamol 500mg');
      expect(c.followUpInstructions, 'Drink plenty of water');
      expect(c.createdAt.year, 2026);
    });

    test('PatientFeedbackItem deserializes all survey fields and doctorId safely', () {
      final fb = PatientFeedbackItem.fromJson({
        'id': 'fb_123',
        'appointment_id': 'appt_123',
        'doctor_id': 'doc_456',
        'patient_id': 'pat_789',
        'patient_name': 'John Doe',
        'created_at': '2026-08-29T11:00:00.000Z',
        'feeling_better': true,
        'medication_helped': true,
        'symptoms_unchanged': false,
        'symptoms_worsened': false,
        'side_effects': 'Mild drowsiness',
        'notes': 'Feeling much better today',
        'severity': 3,
        'recommendation': 'continue_medication',
      });

      expect(fb.id, 'fb_123');
      expect(fb.doctorId, 'doc_456');
      expect(fb.feelingBetter, isTrue);
      expect(fb.medicationHelped, isTrue);
      expect(fb.symptomsWorsened, isFalse);
      expect(fb.sideEffects, 'Mild drowsiness');
      expect(fb.notes, 'Feeling much better today');
      expect(fb.severity, 3);
      expect(fb.recommendation, 'continue_medication');
    });

    test('DoctorAnalytics calculates and parses trends safely', () {
      final analytics = DoctorAnalytics.fromJson({
        'appts_today': 8,
        'total_completed': 6,
        'success_rate': 95.5,
        'followup_rate': 12.0,
        'avg_waiting_min': 7,
        'feedbacks_received': 5,
        'weekly_trend': [
          {'day': 'Mon', 'count': 4},
          {'day': 'Tue', 'count': 6},
        ],
      });

      expect(analytics.apptsToday, 8);
      expect(analytics.totalCompleted, 6);
      expect(analytics.successRate, 95.5);
      expect(analytics.weeklyTrend.length, 2);
      expect(analytics.weeklyTrend[0].day, 'Mon');
      expect(analytics.weeklyTrend[0].count, 4);
    });

    test('Patient profile parses phone, allergies, and age safely', () {
      final p = Patient.fromJson({
        'id': 'pat_1',
        'name': 'Alice Smith',
        'phone': '+15551234567',
        'age': '29',
        'gender': 'Female',
        'allergies': 'Peanuts',
      });

      expect(p.id, 'pat_1');
      expect(p.name, 'Alice Smith');
      expect(p.age, 29);
      expect(p.allergies, 'Peanuts');
    });

    test('Doctor profile parses clinic, delay minutes, and status safely', () {
      final d = Doctor.fromJson({
        'id': 'doc_1',
        'name': 'Dr. Robert Smith',
        'specialty': 'Cardiology',
        'clinic_name': 'Heart Care Clinic',
        'clinic_address': '456 Medical Blvd',
        'status': 'available',
        'delay_minutes': '10',
      });

      expect(d.id, 'doc_1');
      expect(d.name, 'Dr. Robert Smith');
      expect(d.specialty, 'Cardiology');
      expect(d.delayMinutes, 10);
      expect(d.status, 'available');
    });

    test('StaffUser profile parses name, designation, and clinic safely', () {
      final s = StaffUser.fromJson({
        'id': 'staff_1',
        'email': 'nurse.sarah@cure.app',
        'name': 'Nurse Sarah Mitchell',
        'role': 'clinical_staff',
        'clinic_name': 'Cure Medical Center',
        'designation': 'Triage & Clinical Specialist',
      });

      expect(s.id, 'staff_1');
      expect(s.email, 'nurse.sarah@cure.app');
      expect(s.name, 'Nurse Sarah Mitchell');
      expect(s.role, 'clinical_staff');
      expect(s.clinicName, 'Cure Medical Center');
      expect(s.designation, 'Triage & Clinical Specialist');
      expect(s.toJson()['role'], 'clinical_staff');
    });
  });
}

