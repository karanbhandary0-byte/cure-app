import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CustomSlotSchedule {
  final String id;
  DateTime date;
  TimeOfDay fromTime;
  TimeOfDay toTime;
  int durationMinutes;
  int totalSlots;

  CustomSlotSchedule({
    required this.id,
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

  void addSchedule(CustomSlotSchedule schedule) {
    state = [schedule, ...state];
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
