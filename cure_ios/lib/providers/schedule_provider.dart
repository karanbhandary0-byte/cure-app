import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CustomSlotSchedule {
  final String id;
  final String? doctorId;
  DateTime date;
  TimeOfDay fromTime;
  TimeOfDay toTime;
  int durationMinutes;
  int totalSlots;

  CustomSlotSchedule({
    required this.id,
    this.doctorId,
    required this.date,
    required this.fromTime,
    required this.toTime,
    required this.durationMinutes,
    required this.totalSlots,
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String get formattedDate => DateFormat('MMMM d, yyyy').format(date);

  Map<String, dynamic> toJson() => {
    'id': id,
    'doctor_id': doctorId,
    'date': DateFormat('yyyy-MM-dd').format(date),
    'from_hour': fromTime.hour,
    'from_minute': fromTime.minute,
    'to_hour': toTime.hour,
    'to_minute': toTime.minute,
    'duration_minutes': durationMinutes,
    'total_slots': totalSlots,
  };

  factory CustomSlotSchedule.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date']?.toString() ?? '';
    final parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
    return CustomSlotSchedule(
      id: json['id']?.toString() ?? 'sched_${DateTime.now().millisecondsSinceEpoch}',
      doctorId: json['doctor_id']?.toString(),
      date: parsedDate,
      fromTime: TimeOfDay(
        hour: (json['from_hour'] as num?)?.toInt() ?? 6,
        minute: (json['from_minute'] as num?)?.toInt() ?? 0,
      ),
      toTime: TimeOfDay(
        hour: (json['to_hour'] as num?)?.toInt() ?? 8,
        minute: (json['to_minute'] as num?)?.toInt() ?? 0,
      ),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 4,
      totalSlots: (json['total_slots'] as num?)?.toInt() ?? 30,
    );
  }
}

class ScheduleNotifier extends StateNotifier<List<CustomSlotSchedule>> {
  ScheduleNotifier()
      : super([
          // Default Today Schedule
          CustomSlotSchedule(
            id: 'sched_today_1',
            date: DateTime.now(),
            fromTime: const TimeOfDay(hour: 6, minute: 0),
            toTime: const TimeOfDay(hour: 8, minute: 0),
            durationMinutes: 4,
            totalSlots: 30,
          ),
          // Default Future Schedule (Tomorrow)
          CustomSlotSchedule(
            id: 'sched_future_1',
            date: DateTime.now().add(const Duration(days: 1)),
            fromTime: const TimeOfDay(hour: 6, minute: 0),
            toTime: const TimeOfDay(hour: 8, minute: 0),
            durationMinutes: 4,
            totalSlots: 30,
          ),
        ]);

  void setSchedules(List<CustomSlotSchedule> list) {
    if (list.isNotEmpty) {
      state = list;
    }
  }

  void addSchedule(CustomSlotSchedule schedule) {
    state = [schedule, ...state.where((s) => s.id != schedule.id)];
  }

  void updateSchedule(CustomSlotSchedule schedule) {
    state = [
      for (final s in state)
        if (s.id == schedule.id) schedule else s
    ];
  }

  void deleteSchedule(String id) {
    state = state.where((s) => s.id != id).toList();
  }

  List<CustomSlotSchedule> get todaySchedules {
    return state.where((s) => s.isToday).toList();
  }
}

final scheduleProvider = StateNotifierProvider<ScheduleNotifier, List<CustomSlotSchedule>>((ref) {
  return ScheduleNotifier();
});

// =======================================================
// BOOKED PATIENTS SCHEDULE STATE (SHARED WITH WALK-INS)
// =======================================================

class BookedPatientScheduleItem {
  final String id;
  final int slotNumber;
  final String name;
  final int age;
  final String gender;
  final DateTime date;
  final String slotTime;
  final bool isWalkIn;
  final String status;

  BookedPatientScheduleItem({
    required this.id,
    required this.slotNumber,
    required this.name,
    required this.age,
    this.gender = 'Other',
    required this.date,
    required this.slotTime,
    this.isWalkIn = false,
    this.status = 'scheduled',
  });
}

class BookedSchedulePatientsNotifier extends StateNotifier<List<BookedPatientScheduleItem>> {
  BookedSchedulePatientsNotifier()
      : super([
          // Default Today Booked Patients
          BookedPatientScheduleItem(
            id: 'demo_1',
            slotNumber: 1,
            name: 'Roy',
            age: 35,
            gender: 'Male',
            date: DateTime.now(),
            slotTime: '4:05 PM',
            isWalkIn: false,
            status: 'scheduled',
          ),
          BookedPatientScheduleItem(
            id: 'demo_2',
            slotNumber: 2,
            name: 'Anjali',
            age: 28,
            gender: 'Female',
            date: DateTime.now(),
            slotTime: '4:09 PM',
            isWalkIn: false,
            status: 'scheduled',
          ),
          BookedPatientScheduleItem(
            id: 'demo_3',
            slotNumber: 3,
            name: 'Rahul',
            age: 42,
            gender: 'Male',
            date: DateTime.now(),
            slotTime: '4:13 PM',
            isWalkIn: false,
            status: 'scheduled',
          ),
        ]);

  void addWalkInPatient({
    required String name,
    required int age,
    String gender = 'Other',
    DateTime? date,
    String? status,
  }) {
    final targetDate = date ?? DateTime.now();
    final sameDayPatients = state.where((p) =>
        p.date.year == targetDate.year &&
        p.date.month == targetDate.month &&
        p.date.day == targetDate.day).toList();

    final nextSlotNo = sameDayPatients.length + 1;
    final nowTime = DateFormat('h:mm a').format(DateTime.now());

    final newPatient = BookedPatientScheduleItem(
      id: 'walkin_${DateTime.now().millisecondsSinceEpoch}',
      slotNumber: nextSlotNo,
      name: name,
      age: age,
      gender: gender,
      date: targetDate,
      slotTime: nowTime,
      isWalkIn: true,
      status: status ?? 'checked_in',
    );

    state = [...state, newPatient];
  }
}

final bookedSchedulePatientsProvider =
    StateNotifierProvider<BookedSchedulePatientsNotifier, List<BookedPatientScheduleItem>>((ref) {
  return BookedSchedulePatientsNotifier();
});
