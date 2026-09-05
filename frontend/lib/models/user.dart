class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String clinicName;
  final String? clinicAddress;
  final String? status;
  final int? delayMinutes;
  final int? slotDurationMin;
  final int? slotCount;
  final int? slotStartHour;
  final String? verificationStatus;

  // Professional Onboarding Details
  final String? profilePhoto;
  final String? medicalDegree;
  final String? subSpecialization;
  final String? registrationNumber;
  final String? registrationCouncil;
  final int? experienceYears;
  final String? languagesSpoken;

  // Clinic & Practice Profile Details
  final String? googleMapsLocation;
  final String? clinicPhone;
  final int? consultationFee;
  final String? availableDays;
  final String? workingHours;

  // Live Session Status
  final bool isSessionActive;
  final String? sessionStartedAt;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.clinicName,
    this.clinicAddress,
    this.status,
    this.verificationStatus,
    this.delayMinutes,
    this.slotDurationMin,
    this.slotCount,
    this.slotStartHour,
    this.profilePhoto,
    this.medicalDegree,
    this.subSpecialization,
    this.registrationNumber,
    this.registrationCouncil,
    this.experienceYears,
    this.languagesSpoken,
    this.googleMapsLocation,
    this.clinicPhone,
    this.consultationFee,
    this.availableDays,
    this.workingHours,
    this.isSessionActive = false,
    this.sessionStartedAt,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? json['specialization']?.toString() ?? '',
      clinicName: json['clinic_name']?.toString() ?? 'My Clinic',
      clinicAddress: json['clinic_address']?.toString(),
      status: json['status']?.toString() ?? 'available',
      verificationStatus: json['verification_status']?.toString() ?? 'pending',
      delayMinutes: json['delay_minutes'] is int
          ? json['delay_minutes']
          : int.tryParse(json['delay_minutes']?.toString() ?? '0'),
      slotDurationMin: json['slot_duration_min'] is int
          ? json['slot_duration_min']
          : int.tryParse(json['slot_duration_min']?.toString() ?? '30'),
      slotCount: json['slot_count'] is int
          ? json['slot_count']
          : int.tryParse(json['slot_count']?.toString() ?? '8'),
      slotStartHour: json['slot_start_hour'] is int
          ? json['slot_start_hour']
          : int.tryParse(json['slot_start_hour']?.toString() ?? '9'),
      profilePhoto: json['profile_photo']?.toString() ?? json['photo_url']?.toString(),
      medicalDegree: json['medical_degree']?.toString() ?? json['degree']?.toString(),
      subSpecialization: json['sub_specialization']?.toString(),
      registrationNumber: json['registration_number']?.toString() ?? json['medical_council_reg_no']?.toString(),
      registrationCouncil: json['registration_council']?.toString() ?? json['registration_state_council']?.toString(),
      experienceYears: json['years_of_experience'] is int
          ? json['years_of_experience']
          : int.tryParse(json['years_of_experience']?.toString() ?? json['experience_years']?.toString() ?? ''),
      languagesSpoken: json['languages_spoken']?.toString() ?? json['languages']?.toString(),
      googleMapsLocation: json['google_maps_location']?.toString() ?? json['location_link']?.toString() ?? json['google_maps_url']?.toString(),
      clinicPhone: json['clinic_phone']?.toString() ?? json['clinic_phone_number']?.toString(),
      consultationFee: json['consultation_fee'] is int
          ? json['consultation_fee']
          : int.tryParse(json['consultation_fee']?.toString() ?? '800'),
      availableDays: json['available_days']?.toString(),
      workingHours: json['working_hours']?.toString(),
      isSessionActive: json['is_session_active'] == true || json['is_session_active'] == 'true',
      sessionStartedAt: json['session_started_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'specialization': specialty,
      'clinic_name': clinicName,
      'clinic_address': clinicAddress,
      'status': status,
      'verification_status': verificationStatus,
      'delay_minutes': delayMinutes,
      'slot_duration_min': slotDurationMin,
      'slot_count': slotCount,
      'slot_start_hour': slotStartHour,
      'profile_photo': profilePhoto,
      'medical_degree': medicalDegree,
      'sub_specialization': subSpecialization,
      'registration_number': registrationNumber,
      'registration_council': registrationCouncil,
      'years_of_experience': experienceYears,
      'languages_spoken': languagesSpoken,
      'google_maps_location': googleMapsLocation,
      'clinic_phone': clinicPhone,
      'consultation_fee': consultationFee,
      'available_days': availableDays,
      'working_hours': workingHours,
      'is_session_active': isSessionActive,
      'session_started_at': sessionStartedAt,
    };
  }
}

class PatientMember {
  final String id;
  final String name;
  final String ageOrDob;
  final String gender;
  final String relation;
  final bool isPrimary;

  PatientMember({
    required this.id,
    required this.name,
    required this.ageOrDob,
    required this.gender,
    required this.relation,
    this.isPrimary = false,
  });

  factory PatientMember.fromJson(Map<String, dynamic> json) {
    return PatientMember(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      ageOrDob: json['age_or_dob']?.toString() ?? json['age']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'Male',
      relation: json['relation']?.toString() ?? 'Family',
      isPrimary: json['is_primary'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age_or_dob': ageOrDob,
      'gender': gender,
      'relation': relation,
      'is_primary': isPrimary,
    };
  }
}

class AdminUser {
  final String id;
  final String email;
  final String name;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? 'System Administrator',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }
}

class Patient {
  final String id;
  final String name;
  final String phone;
  final int? age;
  final String? gender;
  final String? allergies;

  Patient({
    required this.id,
    required this.name,
    required this.phone,
    this.age,
    this.gender,
    this.allergies,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      age: json['age'] is int
          ? json['age']
          : int.tryParse(json['age']?.toString() ?? ''),
      gender: json['gender']?.toString(),
      allergies: json['allergies']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'age': age,
      'gender': gender,
      'allergies': allergies,
    };
  }
}

class StaffUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final String clinicName;
  final String designation;

  StaffUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'clinical_staff',
    this.clinicName = 'Cure Clinic',
    this.designation = 'Triage & Clinical Nurse',
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Clinical Staff',
      role: json['role']?.toString() ?? 'clinical_staff',
      clinicName: json['clinic_name']?.toString() ?? 'Cure Clinic',
      designation: json['designation']?.toString() ?? 'Triage & Clinical Nurse',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'clinic_name': clinicName,
      'designation': designation,
    };
  }
}

