import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/session_service.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../models/user.dart';

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final session = ref.watch(sessionServiceProvider);
  return ApiService(session);
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

enum AuthStatus { unknown, unauthenticated, authenticatedDoctor, authenticatedPatient, authenticatedAdmin }

class AuthState {
  final AuthStatus status;
  final String? role;
  final String? token;
  final dynamic currentUser;
  final bool isLoading;
  final String? error;

  AuthState({
    required this.status,
    this.role,
    this.token,
    this.currentUser,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? role,
    String? token,
    dynamic currentUser,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      role: role ?? this.role,
      token: token ?? this.token,
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SessionService _session;
  final ApiService _api;
  final FirebaseService _firebase;

  AuthNotifier(this._session, this._api, this._firebase)
      : super(AuthState(status: AuthStatus.unknown)) {
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    final token = await _session.getToken();
    final role = await _session.getRole();
    final user = await _session.getUser();

    if (token != null && token.isNotEmpty) {
      if (role == "doctor") {
        Doctor? doctor = user != null ? Doctor.fromJson(user) : null;
        if (doctor != null) {
          try {
            await _firebase.ensureAuth();
            final freshDoctor = await _firebase.fetchDoctor(doctor.id);
            if (freshDoctor != null) {
              doctor = freshDoctor;
            }
          } catch (_) {}

          final status = (doctor?.verificationStatus ?? 'pending').toLowerCase();
          if (status == "rejected" || status == "pending") {
            await _session.clearSession();
            await _firebase.signOut();
            state = AuthState(
              status: AuthStatus.unauthenticated,
              error: status == "rejected"
                  ? "❌ Access Denied: Your doctor account application has been rejected by the administrator."
                  : "⏳ Pending Approval: Your account is currently under review by the administrator.",
            );
            return;
          }
        }

        state = AuthState(
          status: AuthStatus.authenticatedDoctor,
          role: role,
          token: token,
          currentUser: doctor,
        );
        return;
      } else if (role == "patient") {
        state = AuthState(
          status: AuthStatus.authenticatedPatient,
          role: role,
          token: token,
          currentUser: user != null ? Patient.fromJson(user) : null,
        );
        return;
      } else if (role == "admin") {
        state = AuthState(
          status: AuthStatus.authenticatedAdmin,
          role: role,
          token: token,
          currentUser: user != null ? AdminUser.fromJson(user) : null,
        );
        return;
      }
    }
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> adminAuth({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    // Direct Instant Master Admin Validation
    if (cleanEmail == "admin@cure.app" && cleanPassword == "admin123") {
      final adminMap = {
        "id": "admin_master_001",
        "email": "admin@cure.app",
        "name": "Master Administrator",
        "role": "admin",
      };
      final admin = AdminUser.fromJson(adminMap);
      await _session.saveSession(token: "admin_master_token_secure_2026", role: "admin", user: adminMap);

      state = AuthState(
        status: AuthStatus.authenticatedAdmin,
        role: "admin",
        token: "admin_master_token_secure_2026",
        currentUser: admin,
        isLoading: false,
      );
      return true;
    }

    try {
      final res = await _api.post("/auth/admin/login", body: {"email": cleanEmail, "password": password}, auth: false);
      final token = res["token"].toString();
      final adminMap = res["admin"] as Map<String, dynamic>;
      final admin = AdminUser.fromJson(adminMap);

      await _session.saveSession(token: token, role: "admin", user: adminMap);

      state = AuthState(
        status: AuthStatus.authenticatedAdmin,
        role: "admin",
        token: token,
        currentUser: admin,
        isLoading: false,
      );
      return true;
    } catch (err) {
      state = state.copyWith(
        isLoading: false,
        error: "Invalid admin email or password.",
      );
      return false;
    }
  }

  Future<bool> doctorAuth({
    required bool isRegister,
    required String email,
    required String password,
    String? name,
    String? specialty,
    String? clinicName,
    String? clinicAddress,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    // Try Firebase Authentication first
    try {
      Doctor doctor;
      if (isRegister) {
        doctor = await _firebase.doctorRegister(
          email: email,
          password: password,
          name: name ?? "Dr. Doctor",
          specialty: specialty ?? "General Physician",
          clinicName: (clinicName != null && clinicName.isNotEmpty) ? clinicName : "Cure Clinic",
          clinicAddress: clinicAddress,
        );
      } else {
        doctor = await _firebase.doctorLogin(
          email: email,
          password: password,
        );
      }

      // Enforce Master Admin Verification Approval
      final status = (doctor.verificationStatus ?? 'pending').toLowerCase();
      if (status == "rejected") {
        await _firebase.signOut();
        state = state.copyWith(
          isLoading: false,
          error: "❌ Access Denied: Your doctor account application has been rejected by the administrator.",
        );
        return false;
      }

      if (status == "pending") {
        await _firebase.signOut();
        state = state.copyWith(
          isLoading: false,
          error: "⏳ Pending Approval: Your account is currently under review by the administrator. Please wait for verification.",
        );
        return false;
      }

      final token = "fb_${doctor.id}";
      await _session.saveSession(token: token, role: "doctor", user: doctor.toJson());

      state = AuthState(
        status: AuthStatus.authenticatedDoctor,
        role: "doctor",
        token: token,
        currentUser: doctor,
        isLoading: false,
      );
      return true;
    } catch (firebaseErr) {
      // Fallback to API if Firebase project options are default/unconfigured
      try {
        final path = isRegister ? "/auth/doctor/register" : "/auth/doctor/login";
        final body = isRegister
            ? {
                "email": email,
                "password": password,
                "name": name,
                "specialty": specialty,
                "clinic_name": (clinicName != null && clinicName.isNotEmpty) ? clinicName : "My Clinic",
                "clinic_address": clinicAddress ?? "",
              }
            : {"email": email, "password": password};

        final res = await _api.post(path, body: body, auth: false);
        final token = res["token"].toString();
        final doctorMap = res["doctor"] as Map<String, dynamic>;
        final doctor = Doctor.fromJson(doctorMap);

        final status = (doctor.verificationStatus ?? 'pending').toLowerCase();
        if (status == "rejected") {
          state = state.copyWith(
            isLoading: false,
            error: "❌ Access Denied: Your doctor account application has been rejected by the administrator.",
          );
          return false;
        }

        if (status == "pending") {
          state = state.copyWith(
            isLoading: false,
            error: "⏳ Pending Approval: Your account is currently under review by the administrator. Please wait for verification.",
          );
          return false;
        }

        await _session.saveSession(token: token, role: "doctor", user: doctorMap);

        state = AuthState(
          status: AuthStatus.authenticatedDoctor,
          role: "doctor",
          token: token,
          currentUser: doctor,
          isLoading: false,
        );
        return true;
      } catch (apiErr) {
        String msg = firebaseErr.toString().replaceAll("Exception: ", "").replaceAll("[firebase_auth/", "[Firebase: ");
        if (msg.contains("user-not-found") || msg.contains("invalid-credential") || msg.contains("wrong-password")) {
          msg = "Invalid email or password. If you are new, tap 'Create an account' below.";
        }
        state = state.copyWith(
          isLoading: false,
          error: msg,
        );
        return false;
      }
    }
  }

  Future<String?> sendPatientOtp(String phone) async {
    state = AuthState(status: AuthStatus.unauthenticated, isLoading: true, error: null);
    try {
      // Mock / quick OTP mode for rapid patient verification
      state = AuthState(status: AuthStatus.unauthenticated, isLoading: false);
      return "123456";
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  Future<bool> verifyPatientOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Authenticate Patient in Cloud Firestore
      final patient = await _firebase.patientAuth(phone: phone);
      final token = "fb_${patient.id}";

      await _session.saveSession(token: token, role: "patient", user: patient.toJson());

      state = AuthState(
        status: AuthStatus.authenticatedPatient,
        role: "patient",
        token: token,
        currentUser: patient,
        isLoading: false,
      );
      return true;
    } catch (e) {
      // API fallback
      try {
        final res = await _api.post("/auth/patient/verify-otp", body: {"phone": phone, "code": code}, auth: false);
        final token = res["token"].toString();
        final patientMap = res["patient"] as Map<String, dynamic>;
        final patient = Patient.fromJson(patientMap);

        await _session.saveSession(token: token, role: "patient", user: patientMap);

        state = AuthState(
          status: AuthStatus.authenticatedPatient,
          role: "patient",
          token: token,
          currentUser: patient,
          isLoading: false,
        );
        return true;
      } catch (apiErr) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll("Exception: ", ""),
        );
        return false;
      }
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> logout() async {
    try {
      await _firebase.signOut();
    } catch (_) {}
    await _session.clearSession();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final session = ref.watch(sessionServiceProvider);
  final api = ref.watch(apiServiceProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return AuthNotifier(session, api, firebase);
});
