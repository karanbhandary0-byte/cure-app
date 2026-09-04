import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../models/user.dart';
import '../models/appointment.dart';
import '../models/feedback.dart';
import '../models/slot.dart';
import '../models/consultation.dart';
import 'schedule_provider.dart';

class DoctorDashboardState {
  final bool isLoading;
  final Doctor? doctor;
  final List<Appointment> appointments;
  final List<PatientFeedbackItem> feedbacks;
  final List<CustomSlot> customSlots;
  final String? error;

  DoctorDashboardState({
    this.isLoading = true,
    this.doctor,
    this.appointments = const [],
    this.feedbacks = const [],
    this.customSlots = const [],
    this.error,
  });

  DoctorDashboardState copyWith({
    bool? isLoading,
    Doctor? doctor,
    List<Appointment>? appointments,
    List<PatientFeedbackItem>? feedbacks,
    List<CustomSlot>? customSlots,
    String? error,
  }) {
    return DoctorDashboardState(
      isLoading: isLoading ?? this.isLoading,
      doctor: doctor ?? this.doctor,
      appointments: appointments ?? this.appointments,
      feedbacks: feedbacks ?? this.feedbacks,
      customSlots: customSlots ?? this.customSlots,
      error: error,
    );
  }
}

class DoctorDashboardNotifier extends StateNotifier<DoctorDashboardState> {
  final ApiService _api;
  final FirebaseService _firebase;
  final Ref _ref;

  StreamSubscription? _docSub;
  StreamSubscription? _apptsSub;
  StreamSubscription? _fbsSub;
  StreamSubscription? _slotsSub;
  StreamSubscription? _schedSub;

  DoctorDashboardNotifier(this._api, this._firebase, this._ref) : super(DoctorDashboardState());

  @override
  void dispose() {
    _docSub?.cancel();
    _apptsSub?.cancel();
    _fbsSub?.cancel();
    _slotsSub?.cancel();
    _schedSub?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    final authState = _ref.read(authProvider);
    final Doctor? currentDoc = authState.currentUser is Doctor ? authState.currentUser as Doctor : null;

    if (currentDoc != null && currentDoc.id.isNotEmpty) {
      // Connect to Firestore real-time streams
      _docSub?.cancel();
      _docSub = _firebase.streamDoctor(currentDoc.id).listen((doc) {
        if (doc != null) {
          final status = (doc.verificationStatus ?? 'pending').toLowerCase();
          if (status == "rejected" || status == "pending") {
            _ref.read(authProvider.notifier).logout();
            return;
          }
          state = state.copyWith(doctor: doc, isLoading: false);
        }
      });

      _apptsSub?.cancel();
      _apptsSub = _firebase.streamDoctorAppointments(currentDoc.id).listen((appts) {
        state = state.copyWith(appointments: appts, isLoading: false);
      });

      _fbsSub?.cancel();
      _fbsSub = _firebase.streamDoctorFeedbacks(currentDoc.id).listen((fbs) {
        state = state.copyWith(feedbacks: fbs, isLoading: false);
      });

      _slotsSub?.cancel();
      _slotsSub = _firebase.streamDoctorSlots(currentDoc.id).listen((slots) {
        state = state.copyWith(customSlots: slots, isLoading: false);
      });

      _schedSub?.cancel();
      _schedSub = _firebase.streamDoctorSchedules(currentDoc.id).listen((schedules) {
        if (schedules.isNotEmpty) {
          _ref.read(scheduleProvider.notifier).setSchedules(schedules);
        }
      });

      state = state.copyWith(doctor: currentDoc, isLoading: false);
      return;
    }

    // Fallback to API load
    try {
      final results = await Future.wait([
        _api.get("/auth/doctor/me"),
        _api.get("/doctor/appointments?filter=today"),
        _api.get("/doctor/feedbacks"),
        _api.get("/doctor/slots/upcoming"),
      ]);

      final doctor = Doctor.fromJson(results[0] as Map<String, dynamic>);
      final appts = (results[1] as List)
          .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
          .toList();
      final fbs = (results[2] as List)
          .map((e) => PatientFeedbackItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final slots = (results[3] as List)
          .map((e) => CustomSlot.fromJson(e as Map<String, dynamic>))
          .toList();

      state = DoctorDashboardState(
        isLoading: false,
        doctor: doctor,
        appointments: appts,
        feedbacks: fbs,
        customSlots: slots,
      );
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains("401") || err.contains("unauthorized") || err.contains("invalid token") || err.contains("token expired")) {
        _ref.read(authProvider.notifier).logout();
      }
      final fallbackDoc = state.doctor ?? (currentDoc ?? Doctor(id: 'doc_demo_1', name: 'Dr. Sarah Smith', specialty: 'Cardiology', clinicName: 'Cure Medical Center', clinicAddress: 'Bandra West, Mumbai', status: 'available', delayMinutes: 0, slotDurationMin: 30, slotCount: 8, slotStartHour: 9));
      state = state.copyWith(doctor: fallbackDoc, isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateStatus(String status, int delayMinutes) async {
    final docId = state.doctor?.id;
    if (docId != null && docId.isNotEmpty) {
      try {
        await _firebase.updateDoctorStatus(docId, status, delayMinutes);
        return true;
      } catch (_) {}
    }
    try {
      await _api.put("/doctor/status", body: {
        "status": status,
        "delay_minutes": (status == "available" || status == "closed") ? 0 : delayMinutes,
      });
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateLocation(String clinicName, String clinicAddress) async {
    final docId = state.doctor?.id;
    if (docId != null && docId.isNotEmpty) {
      try {
        await _firebase.updateDoctorLocation(docId, clinicName, clinicAddress);
        return true;
      } catch (_) {}
    }
    try {
      await _api.put("/doctor/location", body: {
        "clinic_name": clinicName,
        "clinic_address": clinicAddress,
      });
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateSettings(int duration, int count, int startHour) async {
    final docId = state.doctor?.id;
    if (docId != null && docId.isNotEmpty) {
      try {
        await _firebase.updateDoctorSettings(docId, duration, count, startHour);
        return true;
      } catch (_) {}
    }
    try {
      await _api.put("/doctor/settings", body: {
        "slot_duration_min": duration,
        "slot_count": count,
        "slot_start_hour": startHour,
      });
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addSlot(DateTime scheduledAt) async {
    final docId = state.doctor?.id;
    if (docId != null && docId.isNotEmpty) {
      try {
        await _firebase.addSlot(docId, scheduledAt);
        return true;
      } catch (_) {}
    }
    try {
      await _api.post("/doctor/slots", body: {
        "scheduled_at": scheduledAt.toIso8601String(),
      });
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSlot(String slotId) async {
    try {
      await _firebase.deleteSlot(slotId);
      return true;
    } catch (_) {}
    try {
      await _api.delete("/doctor/slots/$slotId");
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> postpone(int shiftMinutes, String scope) async {
    try {
      await _api.post("/doctor/postpone", body: {
        "shift_minutes": shiftMinutes,
        "apply_to": scope,
      });
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final doctorDashboardProvider =
    StateNotifierProvider<DoctorDashboardNotifier, DoctorDashboardState>((ref) {
  final api = ref.watch(apiServiceProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return DoctorDashboardNotifier(api, firebase, ref);
});

// Patients & Detail Provider
class PatientDetailState {
  final bool isLoading;
  final Patient? patient;
  final List<Appointment> appointments;
  final List<Consultation> consultations;
  final List<PatientFeedbackItem> feedbacks;
  final String? error;

  PatientDetailState({
    this.isLoading = true,
    this.patient,
    this.appointments = const [],
    this.consultations = const [],
    this.feedbacks = const [],
    this.error,
  });
}

final patientDetailProvider =
    FutureProvider.family<PatientDetailState, String>((ref, patientId) async {
  if (patientId.trim().isEmpty) {
    return PatientDetailState(
      isLoading: false,
      error: "Patient ID is missing.",
    );
  }

  // 1. Try Cloud Firestore first
  try {
    final fb = ref.read(firebaseServiceProvider);
    final authState = ref.read(authProvider);
    final Doctor? currentDoc = authState.currentUser is Doctor ? authState.currentUser as Doctor : null;
    final currentDocId = currentDoc?.id;

    final patient = await fb.getPatient(patientId);
    final appts = await fb.getPatientAppointments(patientId);
    final consults = await fb.getPatientConsultations(patientId, doctorId: currentDocId);
    final fbs = await fb.getPatientFeedbacks(patientId);

    if (patient != null) {
      return PatientDetailState(
        isLoading: false,
        patient: patient,
        appointments: appts,
        consultations: consults,
        feedbacks: fbs,
      );
    }
  } catch (_) {}

  // 2. Fallback to REST API
  final api = ref.watch(apiServiceProvider);
  try {
    final res = await api.get("/doctor/patients/$patientId");
    if (res != null && res is Map<String, dynamic> && res['patient'] != null) {
      final patient = Patient.fromJson(res['patient'] as Map<String, dynamic>);
      final appts = (res['appointments'] as List? ?? [])
          .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
          .toList();
      final consults = (res['consultations'] as List? ?? [])
          .map((e) => Consultation.fromJson(e as Map<String, dynamic>))
          .toList();
      final fbs = (res['feedbacks'] as List? ?? [])
          .map((e) => PatientFeedbackItem.fromJson(e as Map<String, dynamic>))
          .toList();

      return PatientDetailState(
        isLoading: false,
        patient: patient,
        appointments: appts,
        consultations: consults,
        feedbacks: fbs,
      );
    }
  } catch (_) {}

  // 3. Check Booked Schedule / Walk-in Patients State
  final bookedPatients = ref.watch(bookedSchedulePatientsProvider);
  final booked = bookedPatients.cast<BookedPatientScheduleItem?>().firstWhere(
    (p) => p?.id == patientId,
    orElse: () => null,
  );

  if (booked != null) {
    return PatientDetailState(
      isLoading: false,
      patient: Patient(
        id: booked.id,
        name: booked.name,
        phone: "+91 98765 43210",
        age: booked.age,
        gender: booked.gender,
        allergies: "None",
      ),
      appointments: [
        Appointment(
          id: 'appt_${booked.id}',
          doctorId: 'doc_demo_1',
          patientId: booked.id,
          tokenNumber: booked.slotNumber,
          scheduledAt: booked.date,
          status: booked.status,
          patientName: booked.name,
        ),
      ],
      consultations: [],
      feedbacks: [],
    );
  }

  // 4. Fallback to default patient profile for smooth UI demo
  final fallbackPatient = Patient(
    id: patientId,
    name: "Patient (${patientId.length > 8 ? patientId.substring(0, 8) : patientId})",
    phone: "+15551110001",
    age: 32,
    gender: "Other",
    allergies: "None",
  );

  return PatientDetailState(
    isLoading: false,
    patient: fallbackPatient,
    appointments: [],
    consultations: [],
    feedbacks: [],
  );
});

// =======================================================
// RECORDED CONSULTATIONS STATE (WITH UPLOADED IMAGES)
// =======================================================

class RecordedConsultation {
  final String id;
  final String doctorId;
  final String patientId;
  final String? patientName;
  final String appointmentId;
  final String diagnosis;
  final String prescription;
  final String? prescriptionImageUrl;
  final String? reportImageUrl;
  final String? followUpInstructions;
  final String? followUpDate;
  final DateTime createdAt;
  final String doctorName;

  RecordedConsultation({
    required this.id,
    required this.doctorId,
    required this.patientId,
    this.patientName,
    required this.appointmentId,
    required this.diagnosis,
    required this.prescription,
    this.prescriptionImageUrl,
    this.reportImageUrl,
    this.followUpInstructions,
    this.followUpDate,
    required this.createdAt,
    required this.doctorName,
  });
}

class RecordedConsultationsNotifier extends StateNotifier<List<RecordedConsultation>> {
  RecordedConsultationsNotifier() : super([]);

  void addConsultation(RecordedConsultation consult) {
    state = [consult, ...state];
  }

  List<RecordedConsultation> getForPatientAndDoctor(String patientId, String doctorId, {String? patientName}) {
    return state
        .where((c) {
          final docMatch = doctorId.isEmpty || c.doctorId == doctorId;
          final idMatch = c.patientId == patientId;
          final nameMatch = patientName == null || patientName.isEmpty || (c.patientName != null && c.patientName!.toLowerCase() == patientName.toLowerCase());
          return docMatch && (idMatch || nameMatch);
        })
        .toList();
  }
}

final recordedConsultationsProvider =
    StateNotifierProvider<RecordedConsultationsNotifier, List<RecordedConsultation>>((ref) {
  return RecordedConsultationsNotifier();
});

