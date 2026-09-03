import 'package:intl/intl.dart';

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

class DoctorScheduleSession {
  final String id;
  final String name; // e.g. "Morning Session", "Evening Session"
  final int startHour; // 1-12
  final int startMinute; // 0-59
  final String startPeriod; // "AM" or "PM"
  final int endHour; // 1-12
  final int endMinute; // 0-59
  final String endPeriod; // "AM" or "PM"
  final int consultationDurationMin; // e.g. 4
  final bool isActive;

  DoctorScheduleSession({
    required this.id,
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.startPeriod,
    required this.endHour,
    required this.endMinute,
    required this.endPeriod,
    required this.consultationDurationMin,
    this.isActive = true,
  });

  int get startMinutesFromMidnight {
    int h = startHour % 12;
    if (startPeriod.toUpperCase() == "PM") h += 12;
    return h * 60 + startMinute;
  }

  int get endMinutesFromMidnight {
    int h = endHour % 12;
    if (endPeriod.toUpperCase() == "PM") h += 12;
    return h * 60 + endMinute;
  }

  int get totalWorkingMinutes {
    return endMinutesFromMidnight - startMinutesFromMidnight;
  }

  int get calculatedSlotCount {
    if (consultationDurationMin <= 0 || totalWorkingMinutes <= 0) return 0;
    return totalWorkingMinutes ~/ consultationDurationMin;
  }

  String get formattedStartTime {
    final mStr = startMinute.toString().padLeft(2, '0');
    return "$startHour:$mStr $startPeriod";
  }

  String get formattedEndTime {
    final mStr = endMinute.toString().padLeft(2, '0');
    return "$endHour:$mStr $endPeriod";
  }

  List<AppointmentSlot> generateSlots({required String doctorId, required String date}) {
    final List<AppointmentSlot> generated = [];
    final count = calculatedSlotCount;
    if (count <= 0) return generated;

    for (int i = 0; i < count; i++) {
      final slotStartMin = startMinutesFromMidnight + (i * consultationDurationMin);
      final slotEndMin = slotStartMin + consultationDurationMin;

      final startLabel = _minutesTo12HourFormat(slotStartMin);
      final endLabel = _minutesTo12HourFormat(slotEndMin);
      final token = (i + 1).toString().padLeft(2, '0');

      generated.add(
        AppointmentSlot(
          id: "slot_${doctorId}_${date}_${sessionKey(name)}_$token",
          doctorId: doctorId,
          sessionName: name,
          date: date,
          startTime: startLabel,
          endTime: endLabel,
          startMinutes: slotStartMin,
          endMinutes: slotEndMin,
          durationMin: consultationDurationMin,
          tokenNumber: token,
          status: 'available',
        ),
      );
    }
    return generated;
  }

  static String sessionKey(String n) {
    return n.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  static String _minutesTo12HourFormat(int totalMinutes) {
    int hours = (totalMinutes ~/ 60) % 24;
    int minutes = totalMinutes % 60;
    String period = hours >= 12 ? "PM" : "AM";
    int displayHour = hours % 12;
    if (displayHour == 0) displayHour = 12;
    String minStr = minutes.toString().padLeft(2, '0');
    return "$displayHour:$minStr $period";
  }

  factory DoctorScheduleSession.fromJson(Map<String, dynamic> json) {
    return DoctorScheduleSession(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Session',
      startHour: (json['start_hour'] as num?)?.toInt() ?? 6,
      startMinute: (json['start_minute'] as num?)?.toInt() ?? 0,
      startPeriod: json['start_period']?.toString() ?? 'AM',
      endHour: (json['end_hour'] as num?)?.toInt() ?? 8,
      endMinute: (json['end_minute'] as num?)?.toInt() ?? 0,
      endPeriod: json['end_period']?.toString() ?? 'AM',
      consultationDurationMin: (json['consultation_duration_min'] as num?)?.toInt() ?? 4,
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_hour': startHour,
      'start_minute': startMinute,
      'start_period': startPeriod,
      'end_hour': endHour,
      'end_minute': endMinute,
      'end_period': endPeriod,
      'consultation_duration_min': consultationDurationMin,
      'is_active': isActive,
    };
  }
}

class AppointmentSlot {
  final String id;
  final String doctorId;
  final String sessionName;
  final String date; // YYYY-MM-DD
  final String startTime; // "6:00 AM"
  final String endTime; // "6:04 AM"
  final int startMinutes;
  final int endMinutes;
  final int durationMin;
  final String tokenNumber;
  String status; // 'available', 'booked', 'checked_in', 'completed', 'cancelled', 'no_show'
  String? patientId;
  String? patientName;
  String? patientPhone;
  String? appointmentType; // 'online' or 'walk_in'
  DateTime? bookedAt;

  AppointmentSlot({
    required this.id,
    required this.doctorId,
    required this.sessionName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.startMinutes,
    required this.endMinutes,
    required this.durationMin,
    required this.tokenNumber,
    this.status = 'available',
    this.patientId,
    this.patientName,
    this.patientPhone,
    this.appointmentType,
    this.bookedAt,
  });

  String get timeRangeLabel => "$startTime–$endTime";

  bool get isAvailable => status == 'available';
  bool get isBooked => status == 'booked';
  bool get isCheckedIn => status == 'checked_in';
  bool get isCompleted => status == 'completed';

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    return AppointmentSlot(
      id: json['id']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString() ?? '',
      sessionName: json['session_name']?.toString() ?? 'Session',
      date: json['date']?.toString() ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      startMinutes: (json['start_minutes'] as num?)?.toInt() ?? 0,
      endMinutes: (json['end_minutes'] as num?)?.toInt() ?? 0,
      durationMin: (json['duration_min'] as num?)?.toInt() ?? 4,
      tokenNumber: json['token_number']?.toString() ?? '01',
      status: json['status']?.toString() ?? 'available',
      patientId: json['patient_id']?.toString(),
      patientName: json['patient_name']?.toString(),
      patientPhone: json['patient_phone']?.toString(),
      appointmentType: json['appointment_type']?.toString(),
      bookedAt: json['booked_at'] != null ? _parseDateTime(json['booked_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'session_name': sessionName,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'start_minutes': startMinutes,
      'end_minutes': endMinutes,
      'duration_min': durationMin,
      'token_number': tokenNumber,
      'status': status,
      'patient_id': patientId,
      'patient_name': patientName,
      'patient_phone': patientPhone,
      'appointment_type': appointmentType,
      'booked_at': bookedAt?.toIso8601String(),
    };
  }
}

class CustomSlot {
  final String id;
  final DateTime scheduledAt;

  CustomSlot({
    required this.id,
    required this.scheduledAt,
  });

  factory CustomSlot.fromJson(Map<String, dynamic> json) {
    return CustomSlot(
      id: json['id']?.toString() ?? '',
      scheduledAt: _parseDateTime(json['scheduled_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduled_at': scheduledAt.toIso8601String(),
    };
  }
}

class TimeSlot {
  final String time;
  final String label;
  final bool available;

  TimeSlot({
    required this.time,
    required this.label,
    required this.available,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      time: json['time']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      available: json['available'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'label': label,
      'available': available,
    };
  }
}
