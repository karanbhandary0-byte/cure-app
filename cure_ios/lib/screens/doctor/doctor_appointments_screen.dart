import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../models/slot.dart';

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends ConsumerState<DoctorAppointmentsScreen> {
  // Session 1: Morning (Default 6:00 AM – 8:00 AM, 4 min)
  TimeOfDay _startTime1 = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime1 = const TimeOfDay(hour: 8, minute: 0);
  int _duration1 = 4;

  // Session 2: Evening (Optional Toggle)
  bool _enableSession2 = true;
  TimeOfDay _startTime2 = const TimeOfDay(hour: 17, minute: 0); // 5:00 PM
  TimeOfDay _endTime2 = const TimeOfDay(hour: 20, minute: 0); // 8:00 PM
  int _duration2 = 4;

  List<AppointmentSlot> _slots = [];
  bool _isGenerated = false;

  @override
  void initState() {
    super.initState();
    _generateSlots();
  }

  void _generateSlots() {
    final List<AppointmentSlot> newSlots = [];
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. Generate Session 1 Slots
    int startMin1 = _startTime1.hour * 60 + _startTime1.minute;
    int endMin1 = _endTime1.hour * 60 + _endTime1.minute;
    int total1 = endMin1 - startMin1;
    if (total1 > 0 && _duration1 > 0) {
      int count1 = total1 ~/ _duration1;
      for (int i = 0; i < count1; i++) {
        int s = startMin1 + (i * _duration1);
        int e = s + _duration1;
        newSlots.add(
          AppointmentSlot(
            id: 'slot_1_${i + 1}',
            doctorId: 'doc_demo_001',
            sessionName: 'Morning Session',
            date: today,
            startTime: _formatTimeOfDay(TimeOfDay(hour: s ~/ 60, minute: s % 60)),
            endTime: _formatTimeOfDay(TimeOfDay(hour: e ~/ 60, minute: e % 60)),
            startMinutes: s,
            endMinutes: e,
            durationMin: _duration1,
            tokenNumber: (i + 1).toString().padLeft(2, '0'),
            status: i == 0 ? 'booked' : (i == 1 ? 'checked_in' : 'available'),
            patientName: i == 0 ? 'John Doe' : (i == 1 ? 'Sarah Connor (Walk-in)' : null),
          ),
        );
      }
    }

    // 2. Generate Session 2 Slots (if enabled)
    if (_enableSession2) {
      int startMin2 = _startTime2.hour * 60 + _startTime2.minute;
      int endMin2 = _endTime2.hour * 60 + _endTime2.minute;
      int total2 = endMin2 - startMin2;
      if (total2 > 0 && _duration2 > 0) {
        int count2 = total2 ~/ _duration2;
        for (int i = 0; i < count2; i++) {
          int s = startMin2 + (i * _duration2);
          int e = s + _duration2;
          newSlots.add(
            AppointmentSlot(
              id: 'slot_2_${i + 1}',
              doctorId: 'doc_demo_001',
              sessionName: 'Evening Session',
              date: today,
              startTime: _formatTimeOfDay(TimeOfDay(hour: s ~/ 60, minute: s % 60)),
              endTime: _formatTimeOfDay(TimeOfDay(hour: e ~/ 60, minute: e % 60)),
              startMinutes: s,
              endMinutes: e,
              durationMin: _duration2,
              tokenNumber: (newSlots.length + 1).toString().padLeft(2, '0'),
              status: 'available',
            ),
          );
        }
      }
    }

    setState(() {
      _slots = newSlots;
      _isGenerated = true;
    });
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return DateFormat('h:mm a').format(dt);
  }

  Future<void> _pickTime(BuildContext context, bool isStart, int sessionNum) async {
    final current = sessionNum == 1
        ? (isStart ? _startTime1 : _endTime1)
        : (isStart ? _startTime2 : _endTime2);

    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: isStart ? "SELECT START TIME (AM/PM)" : "SELECT END TIME (AM/PM)",
    );

    if (picked != null) {
      setState(() {
        if (sessionNum == 1) {
          if (isStart) _startTime1 = picked;
          else _endTime1 = picked;
        } else {
          if (isStart) _startTime2 = picked;
          else _endTime2 = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalSlots = _slots.length;
    int availableCount = _slots.where((s) => s.status == 'available').length;
    int bookedCount = _slots.where((s) => s.status == 'booked' || s.status == 'checked_in').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Doctor Schedule & Slots",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Morning Session Box
            _buildSessionBox(
              title: "Morning Working Hours",
              startTime: _startTime1,
              endTime: _endTime1,
              duration: _duration1,
              onPickStart: () => _pickTime(context, true, 1),
              onPickEnd: () => _pickTime(context, false, 1),
              onDurationChanged: (v) => setState(() => _duration1 = v),
            ),
            const SizedBox(height: AppSpacing.md),

            // Evening Session Box (Collapsible / Toggleable)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Evening Working Hours (Optional)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Switch(
                        value: _enableSession2,
                        activeColor: const Color(0xFF0F766E),
                        onChanged: (val) => setState(() => _enableSession2 = val),
                      ),
                    ],
                  ),
                  if (_enableSession2) ...[
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 8),
                    _buildTimeDurationRow(
                      startTime: _startTime2,
                      endTime: _endTime2,
                      duration: _duration2,
                      onPickStart: () => _pickTime(context, true, 2),
                      onPickEnd: () => _pickTime(context, false, 2),
                      onDurationChanged: (v) => setState(() => _duration2 = v),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Big 1-Tap Generate Slots Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                key: const Key("generate-slots-btn"),
                onPressed: () {
                  _generateSlots();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("✓ Generated $totalSlots slots successfully!"),
                      backgroundColor: const Color(0xFF15803D),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.bolt, color: Colors.white),
                label: const Text(
                  "Generate Slots",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Summary Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Slots ($totalSlots Total)",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface),
                ),
                Row(
                  children: [
                    _statusBadge("Available ($availableCount)", const Color(0xFFDCFCE7), const Color(0xFF15803D)),
                    const SizedBox(width: 6),
                    _statusBadge("Booked ($bookedCount)", const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Slots List (Clean & Simple)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _slots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final slot = _slots[index];
                final isAvailable = slot.status == 'available';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      // Token
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            "#${slot.tokenNumber}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Time (e.g. 6:00 AM – 6:04 AM)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${slot.startTime} – ${slot.endTime}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            if (slot.patientName != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                "Patient: ${slot.patientName}",
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAvailable ? "Available" : "Booked",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? const Color(0xFF15803D) : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionBox({
    required String title,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required int duration,
    required VoidCallback onPickStart,
    required VoidCallback onPickEnd,
    required ValueChanged<int> onDurationChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _buildTimeDurationRow(
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            onPickStart: onPickStart,
            onPickEnd: onPickEnd,
            onDurationChanged: onDurationChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDurationRow({
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required int duration,
    required VoidCallback onPickStart,
    required VoidCallback onPickEnd,
    required ValueChanged<int> onDurationChanged,
  }) {
    return Row(
      children: [
        // Start Time
        Expanded(
          child: InkWell(
            onTap: onPickStart,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Start Time", style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimeOfDay(startTime),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // End Time
        Expanded(
          child: InkWell(
            onTap: onPickEnd,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("End Time", style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimeOfDay(endTime),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Duration (in minutes)
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Duration", style: TextStyle(fontSize: 11, color: AppColors.muted)),
              DropdownButton<int>(
                value: duration,
                isDense: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 3, child: Text("3 min", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DropdownMenuItem(value: 4, child: Text("4 min", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DropdownMenuItem(value: 5, child: Text("5 min", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DropdownMenuItem(value: 10, child: Text("10 min", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DropdownMenuItem(value: 15, child: Text("15 min", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                onChanged: (v) {
                  if (v != null) onDurationChanged(v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String text, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
