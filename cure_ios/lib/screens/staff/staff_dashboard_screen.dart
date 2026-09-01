import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class StaffPatientItem {
  final String id;
  final String tokenNumber;
  final String name;
  final String phone;
  final int age;
  final String gender;
  final String scheduledTime;
  final String reason;
  final String doctorName;
  final bool isWalkIn;
  String status; // 'scheduled', 'arrived', 'checked_in', 'with_doctor', 'completed'
  String? arrivedAt;
  String? checkedInAt;
  String priority; // 'Normal', 'Priority', 'Urgent'
  String? bp;
  String? heartRate;
  String? temp;
  String? spO2;
  String? glucose;
  String? weight;
  String? staffNotes;

  StaffPatientItem({
    required this.id,
    required this.tokenNumber,
    required this.name,
    required this.phone,
    required this.age,
    required this.gender,
    required this.scheduledTime,
    required this.reason,
    this.doctorName = 'Dr. Robert Smith',
    this.isWalkIn = false,
    this.status = 'scheduled',
    this.arrivedAt,
    this.checkedInAt,
    this.priority = 'Normal',
    this.bp,
    this.heartRate,
    this.temp,
    this.spO2,
    this.glucose,
    this.weight,
    this.staffNotes,
  });
}

class StaffDashboardScreen extends ConsumerStatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  ConsumerState<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends ConsumerState<StaffDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatusFilter = 'all';
  String _searchQuery = '';

  final List<StaffPatientItem> _patients = [
    StaffPatientItem(
      id: 'apt_01',
      tokenNumber: '01',
      name: 'James Wilson',
      phone: '+1 (555) 234-8901',
      age: 45,
      gender: 'Male',
      scheduledTime: '09:00 AM',
      reason: 'Hypertension Follow-up & Prescription Refill',
      doctorName: 'Dr. Robert Smith',
      status: 'checked_in',
      arrivedAt: '08:48 AM',
      checkedInAt: '08:55 AM',
      priority: 'Normal',
      bp: '130/85',
      heartRate: '72',
      temp: '98.4',
      spO2: '99',
      weight: '78',
      staffNotes: 'Patient took morning medications on time.',
    ),
    StaffPatientItem(
      id: 'apt_02',
      tokenNumber: '02',
      name: 'Emily Davis',
      phone: '+1 (555) 781-4321',
      age: 32,
      gender: 'Female',
      scheduledTime: '09:30 AM',
      reason: 'Severe Migraine with Nausea',
      doctorName: 'Dr. Robert Smith',
      status: 'arrived',
      arrivedAt: '09:12 AM',
      priority: 'Urgent',
      bp: '118/76',
      heartRate: '88',
      temp: '99.1',
      spO2: '98',
      staffNotes: 'Photophobia reported. Needs quiet lobby area.',
    ),
    StaffPatientItem(
      id: 'apt_03',
      tokenNumber: '03',
      name: 'Robert Chen',
      phone: '+1 (555) 902-6543',
      age: 58,
      gender: 'Male',
      scheduledTime: '10:00 AM',
      reason: 'Chest Tightness & Shortness of Breath',
      doctorName: 'Dr. Robert Smith',
      status: 'arrived',
      arrivedAt: '09:40 AM',
      priority: 'Urgent',
      bp: '145/92',
      heartRate: '94',
      temp: '98.6',
      spO2: '95',
      glucose: '138',
      staffNotes: 'High priority. Patient seated in Triage Bay 1.',
    ),
    StaffPatientItem(
      id: 'apt_04',
      tokenNumber: '04',
      name: 'Sophia Patel',
      phone: '+1 (555) 456-7890',
      age: 26,
      gender: 'Female',
      scheduledTime: '10:30 AM',
      reason: 'Seasonal Allergic Rhinitis',
      doctorName: 'Dr. Robert Smith',
      status: 'scheduled',
      priority: 'Normal',
    ),
    StaffPatientItem(
      id: 'apt_05',
      tokenNumber: '05',
      name: 'Michael Brown',
      phone: '+1 (555) 678-1234',
      age: 64,
      gender: 'Male',
      scheduledTime: '11:00 AM',
      reason: 'Post-op Knee Dressing & Suture Check',
      doctorName: 'Dr. Robert Smith',
      status: 'scheduled',
      priority: 'Normal',
    ),
    StaffPatientItem(
      id: 'apt_06',
      tokenNumber: '06',
      name: 'Amanda Taylor',
      phone: '+1 (555) 345-6789',
      age: 29,
      gender: 'Female',
      scheduledTime: '11:30 AM',
      reason: 'Walk-In: Acute Rash & Itching',
      doctorName: 'Dr. Robert Smith',
      isWalkIn: true,
      status: 'arrived',
      arrivedAt: '10:15 AM',
      priority: 'Priority',
      bp: '120/80',
      heartRate: '76',
      temp: '98.6',
      spO2: '99',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final staff = authState.currentUser is StaffUser
        ? authState.currentUser as StaffUser
        : StaffUser(
            id: 'staff_default',
            email: 'nurse.sarah@cure.app',
            name: 'Nurse Sarah Mitchell',
            designation: 'Triage & Clinical Nurse',
            clinicName: 'Cure Medical Center',
          );

    final todayStr = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    final totalScheduled = _patients.length;
    final arrivedCount = _patients.where((p) => p.status == 'arrived').length;
    final checkedInCount = _patients.where((p) => p.status == 'checked_in').length;
    final completedCount = _patients.where((p) => p.status == 'completed').length;
    final awaitingArrivalCount = _patients.where((p) => p.status == 'scheduled').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.assignment_ind_outlined,
                color: Color(0xFF0F766E),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  "${staff.designation} · ${staff.clinicName}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Color(0xFF16A34A), size: 8),
                SizedBox(width: 5),
                Text(
                  "Shift Active",
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key("staff-logout-button"),
            icon: const Icon(Icons.logout, color: AppColors.muted, size: 20),
            tooltip: "Log Out",
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/');
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0F766E),
          unselectedLabelColor: AppColors.muted,
          indicatorColor: const Color(0xFF0F766E),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              text: "Today's Appointments ($totalScheduled)",
            ),
            Tab(
              icon: const Icon(Icons.transfer_within_a_station_outlined, size: 18),
              text: "Arrived / In Lobby ($arrivedCount)",
            ),
            Tab(
              icon: const Icon(Icons.how_to_reg_outlined, size: 18),
              text: "Checked In ($checkedInCount)",
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key("add-walkin-fab"),
        onPressed: _openWalkInModal,
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(
          "+ New Walk-In Patient",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      body: Column(
        children: [
          // Date & Quick Stats Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.today, size: 16, color: Color(0xFF0F766E)),
                        const SizedBox(width: 6),
                        Text(
                          todayStr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      key: const Key("quick-walkin-top-btn"),
                      onPressed: _openWalkInModal,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        "Walk-In Patient",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 4 Status Counters
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: "Total Today",
                        value: totalScheduled.toString(),
                        color: const Color(0xFF3B82F6),
                        bgColor: const Color(0xFFEFF6FF),
                        icon: Icons.event_note,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: "Awaiting",
                        value: awaitingArrivalCount.toString(),
                        color: const Color(0xFF6B7280),
                        bgColor: const Color(0xFFF3F4F6),
                        icon: Icons.hourglass_empty,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: "Arrived",
                        value: arrivedCount.toString(),
                        color: const Color(0xFFD97706),
                        bgColor: const Color(0xFFFEF3C7),
                        icon: Icons.location_on_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: "Checked In",
                        value: checkedInCount.toString(),
                        color: const Color(0xFF15803D),
                        bgColor: const Color(0xFFDCFCE7),
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search and Status Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search patient by name, phone #, or complaint...",
                    prefixIcon: const Icon(Icons.search, color: AppColors.muted, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("All Patients (${_patients.length})", "all"),
                      _buildFilterChip("Scheduled ($awaitingArrivalCount)", "scheduled"),
                      _buildFilterChip("Marked Arrived ($arrivedCount)", "arrived"),
                      _buildFilterChip("Checked In ($checkedInCount)", "checked_in"),
                      _buildFilterChip("Completed ($completedCount)", "completed"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Today's Appointments
                _buildPatientListView(_getFilteredList(null)),

                // Tab 2: Arrived in Lobby
                _buildPatientListView(_getFilteredList('arrived')),

                // Tab 3: Checked In (Ready for Doctor)
                _buildPatientListView(_getFilteredList('checked_in')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<StaffPatientItem> _getFilteredList(String? tabStatus) {
    return _patients.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.phone.contains(_searchQuery) ||
          p.tokenNumber.contains(_searchQuery) ||
          p.reason.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (tabStatus != null && p.status != tabStatus) return false;

      if (_selectedStatusFilter != 'all') {
        if (p.status != _selectedStatusFilter) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildPatientListView(List<StaffPatientItem> list) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_search_outlined, size: 56, color: AppColors.muted),
              const SizedBox(height: 12),
              const Text(
                "No patients found",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
              ),
              const SizedBox(height: 4),
              const Text(
                "Try adjusting your search query or status filter.",
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _openWalkInModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Register Walk-In Patient"),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0F766E)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.md, bottom: 90),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        return _buildPatientCard(p);
      },
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatusFilter = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(StaffPatientItem p) {
    Color statusBg = const Color(0xFFF3F4F6);
    Color statusColor = AppColors.muted;
    String statusLabel = "Scheduled";
    IconData statusIcon = Icons.event;

    if (p.status == 'arrived') {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFD97706);
      statusLabel = "Arrived (In Lobby)";
      statusIcon = Icons.location_on_outlined;
    } else if (p.status == 'checked_in') {
      statusBg = const Color(0xFFDCFCE7);
      statusColor = const Color(0xFF15803D);
      statusLabel = "Checked In · Ready";
      statusIcon = Icons.check_circle;
    } else if (p.status == 'with_doctor') {
      statusBg = const Color(0xFFEDE9FE);
      statusColor = const Color(0xFF6D28D9);
      statusLabel = "In Consultation";
      statusIcon = Icons.meeting_room;
    } else if (p.status == 'completed') {
      statusBg = const Color(0xFFF3F4F6);
      statusColor = AppColors.muted;
      statusLabel = "Completed";
      statusIcon = Icons.task_alt;
    }

    Color priorityColor = const Color(0xFF15803D);
    Color priorityBg = const Color(0xFFDCFCE7);
    if (p.priority == 'Urgent') {
      priorityColor = const Color(0xFFDC2626);
      priorityBg = const Color(0xFFFEE2E2);
    } else if (p.priority == 'Priority') {
      priorityColor = const Color(0xFFD97706);
      priorityBg = const Color(0xFFFEF3C7);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Token + Name + Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Token Box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "TOKEN",
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.muted),
                      ),
                      Text(
                        "#${p.tokenNumber}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        if (p.isWalkIn) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Text(
                              "WALK-IN",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${p.age}y · ${p.gender} · ${p.phone}",
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Chief Complaint: ${p.reason}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // Status & Urgency Badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      p.priority,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: priorityColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Timestamps & Doctor assigned
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 13, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                "Slot: ${p.scheduledTime}",
                style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
              ),
              if (p.arrivedAt != null) ...[
                const SizedBox(width: 10),
                const Icon(Icons.directions_walk, size: 13, color: Color(0xFFD97706)),
                const SizedBox(width: 4),
                Text(
                  "Arrived: ${p.arrivedAt}",
                  style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
                ),
              ],
              if (p.checkedInAt != null) ...[
                const SizedBox(width: 10),
                const Icon(Icons.check, size: 13, color: Color(0xFF15803D)),
                const SizedBox(width: 4),
                Text(
                  "Checked In: ${p.checkedInAt}",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),

          // Vitals Summary Row if recorded
          if (p.bp != null || p.heartRate != null || p.temp != null || p.spO2 != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (p.bp != null) _buildVitalTag("BP", "${p.bp} mmHg", Icons.speed),
                  if (p.heartRate != null) _buildVitalTag("HR", "${p.heartRate} bpm", Icons.favorite_border),
                  if (p.temp != null) _buildVitalTag("Temp", "${p.temp} °F", Icons.thermostat_outlined),
                  if (p.spO2 != null) _buildVitalTag("SpO2", "${p.spO2}%", Icons.air),
                  if (p.glucose != null) _buildVitalTag("Glucose", "${p.glucose} mg/dL", Icons.water_drop_outlined),
                  if (p.weight != null) _buildVitalTag("Weight", "${p.weight} kg", Icons.fitness_center),
                ],
              ),
            ),
          ],

          if (p.staffNotes != null && p.staffNotes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              "Staff Note: ${p.staffNotes!}",
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.muted),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),

          // Action Buttons: Mark Arrived, Check In, Edit Vitals, Send to Doctor
          Row(
            children: [
              // 1. Mark Arrived Button (if still scheduled)
              if (p.status == 'scheduled') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    key: Key("mark-arrived-${p.id}"),
                    onPressed: () => _markPatientArrived(p),
                    icon: const Icon(Icons.location_on_outlined, size: 16),
                    label: const Text(
                      "Mark Arrived",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // 2. Check In Button (if arrived or scheduled)
              if (p.status == 'scheduled' || p.status == 'arrived') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    key: Key("check-in-${p.id}"),
                    onPressed: () => _openCheckInVitalsModal(p),
                    icon: const Icon(Icons.how_to_reg, size: 16),
                    label: Text(
                      p.status == 'arrived' ? "Check In Patient" : "Direct Check-In",
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],

              // 3. Edit Vitals & Mark Ready for Doctor (if checked in)
              if (p.status == 'checked_in') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    key: Key("edit-vitals-${p.id}"),
                    onPressed: () => _openCheckInVitalsModal(p),
                    icon: const Icon(Icons.favorite_border, size: 16),
                    label: const Text(
                      "Update Vitals",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      side: const BorderSide(color: Color(0xFF0F766E)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    key: Key("send-doctor-${p.id}"),
                    onPressed: () {
                      setState(() {
                        p.status = 'with_doctor';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${p.name} called into Doctor's Room!"),
                          backgroundColor: const Color(0xFF6D28D9),
                        ),
                      );
                    },
                    icon: const Icon(Icons.meeting_room_outlined, size: 16),
                    label: const Text(
                      "Call to Doctor",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],

              // 4. In Consultation -> Complete
              if (p.status == 'with_doctor') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        p.status = 'completed';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Consultation completed for ${p.name}."),
                          backgroundColor: const Color(0xFF15803D),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text(
                      "Mark Consultation Completed",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D28D9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalTag(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF0F766E)),
        const SizedBox(width: 3),
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.onSurface),
        ),
      ],
    );
  }

  void _markPatientArrived(StaffPatientItem patient) {
    final nowTime = DateFormat('hh:mm a').format(DateTime.now());
    setState(() {
      patient.status = 'arrived';
      patient.arrivedAt = nowTime;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ ${patient.name} marked ARRIVED in clinic lobby at $nowTime!"),
        backgroundColor: const Color(0xFFD97706),
        action: SnackBarAction(
          label: "CHECK IN NOW",
          textColor: Colors.white,
          onPressed: () => _openCheckInVitalsModal(patient),
        ),
      ),
    );
  }

  void _openCheckInVitalsModal(StaffPatientItem patient) {
    final bpCtrl = TextEditingController(text: patient.bp ?? "120/80");
    final hrCtrl = TextEditingController(text: patient.heartRate ?? "72");
    final tempCtrl = TextEditingController(text: patient.temp ?? "98.6");
    final spO2Ctrl = TextEditingController(text: patient.spO2 ?? "98");
    final glucoseCtrl = TextEditingController(text: patient.glucose ?? "");
    final weightCtrl = TextEditingController(text: patient.weight ?? "");
    final notesCtrl = TextEditingController(text: patient.staffNotes ?? "");
    String priority = patient.priority;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.xl,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Patient Check-In & Vitals",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              "${patient.name} (Token #${patient.tokenNumber}) · ${patient.reason}",
                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: AppSpacing.sm),

                    // Priority Level
                    const Text(
                      "Triage Urgency Level",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: ['Normal', 'Priority', 'Urgent'].map((lvl) {
                        final isSel = priority == lvl;
                        Color col = lvl == 'Urgent'
                            ? const Color(0xFFDC2626)
                            : (lvl == 'Priority' ? const Color(0xFFD97706) : const Color(0xFF15803D));
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                priority = lvl;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? col.withOpacity(0.12) : AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border: Border.all(
                                  color: isSel ? col : AppColors.border,
                                  width: isSel ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  lvl,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: isSel ? col : AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Vitals Grid
                    Row(
                      children: [
                        Expanded(child: _buildModalField("Blood Pressure (mmHg)", bpCtrl, "120/80")),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildModalField("Heart Rate (bpm)", hrCtrl, "72")),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(child: _buildModalField("Body Temp (°F)", tempCtrl, "98.6")),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildModalField("Oxygen SpO2 (%)", spO2Ctrl, "98")),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(child: _buildModalField("Blood Sugar (mg/dL)", glucoseCtrl, "Optional")),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildModalField("Weight (kg)", weightCtrl, "Optional")),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildModalField("Staff / Triage Clinical Notes", notesCtrl, "e.g. Allergies verified, patient seated in Bay 2", maxLines: 2),
                    const SizedBox(height: AppSpacing.lg),

                    // Check In Complete Action
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const Key("confirm-checkin-btn"),
                        onPressed: () {
                          final nowTime = DateFormat('hh:mm a').format(DateTime.now());
                          setState(() {
                            patient.bp = bpCtrl.text.trim();
                            patient.heartRate = hrCtrl.text.trim();
                            patient.temp = tempCtrl.text.trim();
                            patient.spO2 = spO2Ctrl.text.trim();
                            patient.glucose = glucoseCtrl.text.trim().isEmpty ? null : glucoseCtrl.text.trim();
                            patient.weight = weightCtrl.text.trim().isEmpty ? null : weightCtrl.text.trim();
                            patient.staffNotes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();
                            patient.priority = priority;
                            patient.status = 'checked_in';
                            patient.checkedInAt = nowTime;
                            if (patient.arrivedAt == null) {
                              patient.arrivedAt = nowTime;
                            }
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("✅ ${patient.name} CHECKED IN successfully! Ready for Doctor."),
                              backgroundColor: const Color(0xFF15803D),
                            ),
                          );
                        },
                        icon: const Icon(Icons.how_to_reg, size: 18),
                        label: const Text(
                          "Complete Check-In & Send to Doctor Queue",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openWalkInModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: "+1 (555) ");
    final ageCtrl = TextEditingController(text: "35");
    final reasonCtrl = TextEditingController();
    String gender = "Female";
    String priority = "Normal";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.xl,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Register Walk-In Patient",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              "Instant walk-in registration, token generation & check-in",
                              style: TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: AppSpacing.sm),

                    _buildModalField("Patient Full Name *", nameCtrl, "e.g. David Miller"),
                    const SizedBox(height: AppSpacing.sm),
                    _buildModalField("Phone Number *", phoneCtrl, "+1 (555) 000-0000"),
                    const SizedBox(height: AppSpacing.sm),

                    Row(
                      children: [
                        Expanded(child: _buildModalField("Age", ageCtrl, "e.g. 35")),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Gender",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: gender,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceSecondary,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: "Female", child: Text("Female")),
                                  DropdownMenuItem(value: "Male", child: Text("Male")),
                                  DropdownMenuItem(value: "Other", child: Text("Other")),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      gender = val;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    _buildModalField("Chief Complaint / Reason *", reasonCtrl, "e.g. Fever, acute abdominal pain"),
                    const SizedBox(height: AppSpacing.sm),

                    // Priority
                    const Text(
                      "Initial Triage Priority",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: ['Normal', 'Priority', 'Urgent'].map((lvl) {
                        final isSel = priority == lvl;
                        Color col = lvl == 'Urgent'
                            ? const Color(0xFFDC2626)
                            : (lvl == 'Priority' ? const Color(0xFFD97706) : const Color(0xFF15803D));
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                priority = lvl;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? col.withOpacity(0.12) : AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border: Border.all(
                                  color: isSel ? col : AppColors.border,
                                  width: isSel ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  lvl,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: isSel ? col : AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Submit Buttons: 1. Mark Arrived | 2. Immediate Check In
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key("walkin-mark-arrived-btn"),
                            onPressed: () {
                              if (nameCtrl.text.trim().isEmpty) return;
                              final nextNum = (_patients.length + 1).toString().padLeft(2, '0');
                              final nowTime = DateFormat('hh:mm a').format(DateTime.now());

                              final newPatient = StaffPatientItem(
                                id: 'walkin_$nextNum',
                                tokenNumber: nextNum,
                                name: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                age: int.tryParse(ageCtrl.text.trim()) ?? 30,
                                gender: gender,
                                scheduledTime: 'Walk-In ($nowTime)',
                                reason: reasonCtrl.text.trim().isEmpty ? "General Consultation" : reasonCtrl.text.trim(),
                                isWalkIn: true,
                                status: 'arrived',
                                arrivedAt: nowTime,
                                priority: priority,
                              );

                              setState(() {
                                _patients.add(newPatient);
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Walk-in Token #$nextNum created & marked ARRIVED in lobby!"),
                                  backgroundColor: const Color(0xFFD97706),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD97706),
                              side: const BorderSide(color: Color(0xFFD97706)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            ),
                            child: const Text(
                              "Mark Arrived (In Lobby)",
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            key: const Key("walkin-checkin-now-btn"),
                            onPressed: () {
                              if (nameCtrl.text.trim().isEmpty) return;
                              final nextNum = (_patients.length + 1).toString().padLeft(2, '0');
                              final nowTime = DateFormat('hh:mm a').format(DateTime.now());

                              final newPatient = StaffPatientItem(
                                id: 'walkin_$nextNum',
                                tokenNumber: nextNum,
                                name: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                age: int.tryParse(ageCtrl.text.trim()) ?? 30,
                                gender: gender,
                                scheduledTime: 'Walk-In ($nowTime)',
                                reason: reasonCtrl.text.trim().isEmpty ? "General Consultation" : reasonCtrl.text.trim(),
                                isWalkIn: true,
                                status: 'checked_in',
                                arrivedAt: nowTime,
                                checkedInAt: nowTime,
                                priority: priority,
                              );

                              setState(() {
                                _patients.add(newPatient);
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Walk-in Token #$nextNum CHECKED IN & Ready for Doctor!"),
                                  backgroundColor: const Color(0xFF15803D),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Direct Check-In",
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surfaceSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }
}
