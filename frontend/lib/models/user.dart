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
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? '',
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'clinic_name': clinicName,
      'clinic_address': clinicAddress,
      'status': status,
      'verification_status': verificationStatus,
      'delay_minutes': delayMinutes,
      'slot_duration_min': slotDurationMin,
      'slot_count': slotCount,
      'slot_start_hour': slotStartHour,
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

