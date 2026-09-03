import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';

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

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends ConsumerState<DoctorAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Master List of Doctor's Created Schedules
  final List<CustomSlotSchedule> _schedules = [
    // Today's schedule
    CustomSlotSchedule(
      id: 'sched_today_1',
      date: DateTime.now(),
      fromTime: const TimeOfDay(hour: 6, minute: 0),
      toTime: const TimeOfDay(hour: 8, minute: 0),
      durationMinutes: 4,
      totalSlots: 30,
    ),
    // Future schedule (e.g. Tomorrow)
    CustomSlotSchedule(
      id: 'sched_future_1',
      date: DateTime.now().add(const Duration(days: 1)),
      fromTime: const TimeOfDay(hour: 6, minute: 0),
      toTime: const TimeOfDay(hour: 8, minute: 0),
      durationMinutes: 4,
      totalSlots: 30,
    ),
  ];

  // Tab 2: Manage Slots Form State
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _fromTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 8, minute: 0);
  final TextEditingController _durationController = TextEditingController(text: "4");
  String? _editingScheduleId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  int get _calculatedTotalSlots {
    int startMinutes = _fromTime.hour * 60 + _fromTime.minute;
    int endMinutes = _toTime.hour * 60 + _toTime.minute;
    int totalWorkingMinutes = endMinutes - startMinutes;
    int duration = int.tryParse(_durationController.text.trim()) ?? 0;

    if (totalWorkingMinutes <= 0 || duration <= 0) return 0;
    return totalWorkingMinutes ~/ duration;
  }

  String _formatTime(TimeOfDay t) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return DateFormat('h:mm a').format(dt);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime(bool isFrom) async {
    final current = isFrom ? _fromTime : _toTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: isFrom ? "SELECT FROM TIME (AM/PM)" : "SELECT TO TIME (AM/PM)",
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromTime = picked;
        else _toTime = picked;
      });
    }
  }

  void _saveOrUpdateSchedule() {
    final slots = _calculatedTotalSlots;
    if (slots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please make sure To Time is later than From Time and duration is greater than 0."),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final duration = int.tryParse(_durationController.text.trim()) ?? 4;

    if (_editingScheduleId != null) {
      // Edit existing schedule
      final idx = _schedules.indexWhere((s) => s.id == _editingScheduleId);
      if (idx != -1) {
        setState(() {
          _schedules[idx].date = _selectedDate;
          _schedules[idx].fromTime = _fromTime;
          _schedules[idx].toTime = _toTime;
          _schedules[idx].durationMinutes = duration;
          _schedules[idx].totalSlots = slots;
          _editingScheduleId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Schedule updated successfully!"),
            backgroundColor: Color(0xFF15803D),
          ),
        );
      }
    } else {
      // Create new schedule
      final newSched = CustomSlotSchedule(
        id: "sched_${DateTime.now().millisecondsSinceEpoch}",
        date: _selectedDate,
        fromTime: _fromTime,
        toTime: _toTime,
        durationMinutes: duration,
        totalSlots: slots,
      );

      setState(() {
        _schedules.insert(0, newSched);
      });

      if (newSched.isToday) {
        _tabController.animateTo(0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✓ Schedule created for TODAY (${newSched.formattedDate}) and active in Slots tab!"),
            backgroundColor: const Color(0xFF15803D),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✓ Schedule created for ${newSched.formattedDate}! It will automatically appear in Slots tab on that date."),
            backgroundColor: const Color(0xFF0F766E),
          ),
        );
      }
    }
  }

  void _startEditing(CustomSlotSchedule schedule) {
    setState(() {
      _editingScheduleId = schedule.id;
      _selectedDate = schedule.date;
      _fromTime = schedule.fromTime;
      _toTime = schedule.toTime;
      _durationController.text = schedule.durationMinutes.toString();
    });
  }

  void _confirmDelete(CustomSlotSchedule schedule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete this slot schedule?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text("Are you sure you want to delete the schedule for ${schedule.formattedDate} (${_formatTime(schedule.fromTime)} – ${_formatTime(schedule.toTime)})?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _schedules.removeWhere((s) => s.id == schedule.id);
                if (_editingScheduleId == schedule.id) {
                  _editingScheduleId = null;
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✓ Schedule deleted."),
                  backgroundColor: Color(0xFFDC2626),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Doctor Slot Management",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0F766E),
          indicatorWeight: 3,
          labelColor: const Color(0xFF0F766E),
          unselectedLabelColor: AppColors.muted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: "Slots"),
            Tab(text: "Manage Slots"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1 — SLOTS (Today's Schedules Only)
          _buildTodaySlotsTab(),

          // TAB 2 — MANAGE SLOTS (Direct Date Selection & Management)
          _buildManageSlotsTab(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1 — SLOTS (TODAY'S SCHEDULES ONLY)
  // ==========================================
  Widget _buildTodaySlotsTab() {
    final now = DateTime.now();
    final todayFormatted = DateFormat('MMMM d, yyyy').format(now);
    final todaySchedules = _schedules.where((s) => s.isToday).toList();

    if (todaySchedules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy_outlined, size: 48, color: AppColors.muted),
              const SizedBox(height: AppSpacing.md),
              Text(
                "No Schedule for Today ($todayFormatted)",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                "Go to 'Manage Slots' to create a schedule for today.",
                style: TextStyle(fontSize: 13, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () {
                  setState(() => _selectedDate = DateTime.now());
                  _tabController.animateTo(1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Create Schedule for Today", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: todaySchedules.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final plan = todaySchedules[index];
        return _buildTodayCard(plan, todayFormatted);
      },
    );
  }

  Widget _buildTodayCard(CustomSlotSchedule plan, String todayFormatted) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date: September 3, 2026
          Row(
            children: [
              const Text("Date: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onSurface)),
              Text(todayFormatted, style: const TextStyle(fontSize: 14, color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),

          // From: 6:00 AM
          Row(
            children: [
              const Text("From: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onSurface)),
              Text(_formatTime(plan.fromTime), style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 6),

          // To: 8:00 AM
          Row(
            children: [
              const Text("To: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onSurface)),
              Text(_formatTime(plan.toTime), style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 6),

          // Consultation Duration: 4 minutes
          Row(
            children: [
              const Text("Consultation Duration: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onSurface)),
              Text("${plan.durationMinutes} minutes", style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 6),

          // Total Slots: 30
          Row(
            children: [
              const Text("Total Slots: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onSurface)),
              Text(
                "${plan.totalSlots}",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2 — MANAGE SLOTS (CREATE & MANAGE)
  // ==========================================
  Widget _buildManageSlotsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create / Edit Custom Slots Form Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _editingScheduleId != null ? "Edit Schedule" : "Create Custom Slots",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface),
                    ),
                    if (_editingScheduleId != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _editingScheduleId = null;
                            _selectedDate = DateTime.now();
                            _fromTime = const TimeOfDay(hour: 6, minute: 0);
                            _toTime = const TimeOfDay(hour: 8, minute: 0);
                            _durationController.text = "4";
                          });
                        },
                        child: const Text("Cancel Edit", style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Date Picker Direct Field
                const Text("Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E)),
                        ),
                        const Icon(Icons.calendar_month, color: Color(0xFF0F766E), size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // From Time Field
                const Text("From Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _pickTime(true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatTime(_fromTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Icon(Icons.access_time, size: 18, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // To Time Field
                const Text("To Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _pickTime(false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatTime(_toTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Icon(Icons.access_time, size: 18, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Consultation Duration Field
                const Text("Consultation Duration (minutes)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
                const SizedBox(height: 6),
                TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "e.g. 4",
                    suffixText: "minutes",
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.md),

                // Live Total Slots Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Slots",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onSurface),
                    ),
                    Text(
                      "$_calculatedTotalSlots",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // [ Create Slots ] Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    key: const Key("create-slots-button"),
                    onPressed: _saveOrUpdateSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(
                      _editingScheduleId != null ? "Update Schedule" : "Create Slots",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Existing Custom Schedules Header
          const Text(
            "Existing Custom Schedules",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Existing Schedules List
          if (_schedules.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text("No custom schedules created yet.", style: TextStyle(color: AppColors.muted)),
              ),
            )
          else
            ..._schedules.map((schedule) {
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: schedule.isToday ? const Color(0xFF0F766E) : AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          schedule.formattedDate,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onSurface),
                        ),
                        if (schedule.isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "Active in Slots (Today)",
                              style: TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${_formatTime(schedule.fromTime)} – ${_formatTime(schedule.toTime)}",
                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Duration: ${schedule.durationMinutes} minutes",
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Total Slots: ${schedule.totalSlots}",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 6),

                    // Edit & Delete Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _startEditing(schedule),
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0F766E)),
                          label: const Text("Edit", style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _confirmDelete(schedule),
                          icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                          label: const Text("Delete", style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
