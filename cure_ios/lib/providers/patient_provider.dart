import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/session_service.dart';
import '../models/user.dart';
import '../models/appointment.dart';

class PatientHomeState {
  final bool isLoading;
  final Patient? patient;
  final List<Appointment> appointments;
  final List<Appointment> pendingFeedbackAppts;
  final String? error;

  PatientHomeState({
    this.isLoading = true,
    this.patient,
    this.appointments = const [],
    this.pendingFeedbackAppts = const [],
    this.error,
  });

  PatientHomeState copyWith({
    bool? isLoading,
    Patient? patient,
    List<Appointment>? appointments,
    List<Appointment>? pendingFeedbackAppts,
    String? error,
  }) {
    return PatientHomeState(
      isLoading: isLoading ?? this.isLoading,
      patient: patient ?? this.patient,
      appointments: appointments ?? this.appointments,
      pendingFeedbackAppts: pendingFeedbackAppts ?? this.pendingFeedbackAppts,
      error: error,
    );
  }
}

class PatientHomeNotifier extends StateNotifier<PatientHomeState> {
  final ApiService _api;
  final FirebaseService _firebase;
  final Ref _ref;

  StreamSubscription? _apptsSub;

  PatientHomeNotifier(this._api, this._firebase, this._ref) : super(PatientHomeState());

  @override
  void dispose() {
    _apptsSub?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    final authState = _ref.read(authProvider);
    final Patient? currentPatient = authState.currentUser is Patient ? authState.currentUser as Patient : null;

    if (currentPatient != null && currentPatient.id.isNotEmpty) {
      _apptsSub?.cancel();
      _apptsSub = _firebase.streamPatientAppointments(currentPatient.id).listen((appts) {
        final pendingFbs = appts.where((a) => (a.status == 'completed' || a.status == 'booked' || a.status == 'scheduled') && !(a.feedbackSubmitted ?? false) && a.status != 'cancelled').toList();
        state = state.copyWith(
          patient: currentPatient,
          appointments: appts,
          pendingFeedbackAppts: pendingFbs,
          isLoading: false,
        );
      });

      state = state.copyWith(patient: currentPatient, isLoading: false);
      return;
    }

    try {
      final results = await Future.wait([
        _api.get("/auth/patient/me"),
        _api.get("/patient/appointments"),
        _api.get("/patient/pending-feedback"),
      ]);

      final patient = Patient.fromJson(results[0] as Map<String, dynamic>);
      final appts = (results[1] as List)
          .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
          .toList();
      final pendingFbs = (results[2] as List)
          .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
          .toList();

      state = PatientHomeState(
        isLoading: false,
        patient: patient,
        appointments: appts,
        pendingFeedbackAppts: pendingFbs,
      );
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains("401") || err.contains("unauthorized") || err.contains("invalid token") || err.contains("token expired")) {
        _ref.read(authProvider.notifier).logout();
      }
      final fallbackPatient = state.patient ?? (currentPatient ?? Patient(id: 'patient_demo', name: 'John Doe', phone: '+15551110001', age: 32, gender: 'Male'));
      state = state.copyWith(patient: fallbackPatient, isLoading: false, error: e.toString());
    }
  }

  Future<bool> bookAppointment({
    required String doctorId,
    required String doctorName,
    required String clinicName,
    required DateTime scheduledAt,
  }) async {
    final patient = state.patient;
    if (patient != null) {
      try {
        await _firebase.bookAppointment(
          doctorId: doctorId,
          doctorName: doctorName,
          clinicName: clinicName,
          patientId: patient.id,
          patientName: patient.name,
          patientPhone: patient.phone,
          scheduledAt: scheduledAt,
        );
        return true;
      } catch (_) {}
    }
    return false;
  }

  Future<bool> submitFeedback({
    required String appointmentId,
    required String doctorId,
    required int rating,
    required List<String> tags,
    String? comments,
  }) async {
    final patient = state.patient;
    if (patient != null) {
      try {
        await _firebase.submitFeedback(
          appointmentId: appointmentId,
          doctorId: doctorId,
          patientId: patient.id,
          patientName: patient.name,
          rating: rating,
          tags: tags,
          comments: comments,
        );
        await load();
        return true;
      } catch (_) {}
    }
    return false;
  }
}

final patientHomeProvider =
    StateNotifierProvider<PatientHomeNotifier, PatientHomeState>((ref) {
  final api = ref.watch(apiServiceProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return PatientHomeNotifier(api, firebase, ref);
});

class PatientLocationNotifier extends StateNotifier<String> {
  final SessionService _sessionService;

  PatientLocationNotifier(this._sessionService) : super("Mangalore, Karnataka") {
    _init();
  }

  Future<void> _init() async {
    try {
      final saved = await _sessionService.getPatientLocation();
      if (saved != null && saved.trim().isNotEmpty) {
        state = saved.trim();
      }
    } catch (_) {}
  }

  Future<void> setLocation(String newLocation) async {
    final trimmed = newLocation.trim();
    if (trimmed.isEmpty) return;
    state = trimmed;
    try {
      await _sessionService.savePatientLocation(trimmed);
    } catch (_) {}
  }

  Future<void> updateCityAndState(String city, String stateName) async {
    final cleanCity = city.trim();
    final cleanState = stateName.trim();
    if (cleanCity.isEmpty) return;
    final formatted = cleanState.isNotEmpty ? "$cleanCity, $cleanState" : cleanCity;
    await setLocation(formatted);
  }

  @override
  set state(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    super.state = trimmed;
    _sessionService.savePatientLocation(trimmed);
  }
}

final patientLocationProvider =
    StateNotifierProvider<PatientLocationNotifier, String>((ref) {
  final session = ref.watch(sessionServiceProvider);
  return PatientLocationNotifier(session);
});

class PatientMembersState {
  final List<PatientMember> members;
  final PatientMember selectedMember;

  PatientMembersState({
    required this.members,
    required this.selectedMember,
  });

  PatientMembersState copyWith({
    List<PatientMember>? members,
    PatientMember? selectedMember,
  }) {
    return PatientMembersState(
      members: members ?? this.members,
      selectedMember: selectedMember ?? this.selectedMember,
    );
  }
}

class PatientMembersNotifier extends StateNotifier<PatientMembersState> {
  PatientMembersNotifier()
      : super(
          PatientMembersState(
            members: [
              PatientMember(
                id: 'member_self',
                name: 'Roy Kumar',
                ageOrDob: '35 yrs',
                gender: 'Male',
                relation: 'Self',
                isPrimary: true,
              ),
              PatientMember(
                id: 'member_priya',
                name: 'Priya Kumar',
                ageOrDob: '32 yrs',
                gender: 'Female',
                relation: 'Family (Spouse)',
              ),
              PatientMember(
                id: 'member_aarav',
                name: 'Aarav Kumar',
                ageOrDob: '6 yrs',
                gender: 'Male',
                relation: 'Family (Child)',
              ),
            ],
            selectedMember: PatientMember(
              id: 'member_self',
              name: 'Roy Kumar',
              ageOrDob: '35 yrs',
              gender: 'Male',
              relation: 'Self',
              isPrimary: true,
            ),
          ),
        );

  void selectMember(PatientMember member) {
    state = state.copyWith(selectedMember: member);
  }

  void addMember({
    required String name,
    required String ageOrDob,
    required String gender,
    required String relation,
    bool selectAfterAdd = true,
  }) {
    final newMember = PatientMember(
      id: 'member_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      ageOrDob: ageOrDob,
      gender: gender,
      relation: relation,
      isPrimary: false,
    );

    final updated = [...state.members, newMember];
    state = state.copyWith(
      members: updated,
      selectedMember: selectAfterAdd ? newMember : state.selectedMember,
    );
  }
}

final patientMembersProvider =
    StateNotifierProvider<PatientMembersNotifier, PatientMembersState>((ref) {
  return PatientMembersNotifier();
});

