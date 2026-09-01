import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class SimplePatientItem {
  final String id;
  final String tokenNumber;
  final String name;
  final String gender;
  final int age;
  final String time;
  final bool isWalkIn;
  String status; // 'scheduled', 'arrived', 'checked_in', 'completed'

  SimplePatientItem({
    required this.id,
    required this.tokenNumber,
    required this.name,
    required this.gender,
    required this.age,
    required this.time,
    this.isWalkIn = false,
    this.status = 'scheduled',
  });
}

class StaffDashboardScreen extends ConsumerStatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  ConsumerState<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends ConsumerState<StaffDashboardScreen> {
  String _activeFilter = 'all'; // 'all', 'scheduled', 'arrived', 'checked_in'
  String _searchQuery = '';

  final List<SimplePatientItem> _patients = [
    SimplePatientItem(
      id: 'p_01',
      tokenNumber: '01',
      name: 'James Wilson',
      gender: 'Male',
      age: 45,
      time: '09:00 AM',
      status: 'checked_in',
    ),
    SimplePatientItem(
      id: 'p_02',
      tokenNumber: '02',
      name: 'Emily Davis',
      gender: 'Female',
      age: 32,
      time: '09:30 AM',
      status: 'arrived',
    ),
    SimplePatientItem(
      id: 'p_03',
      tokenNumber: '03',
      name: 'Robert Chen',
      gender: 'Male',
      age: 58,
      time: '10:00 AM',
      status: 'arrived',
    ),
    SimplePatientItem(
      id: 'p_04',
      tokenNumber: '04',
      name: 'Sophia Patel',
      gender: 'Female',
      age: 26,
      time: '10:30 AM',
      status: 'scheduled',
    ),
    SimplePatientItem(
      id: 'p_05',
      tokenNumber: '05',
      name: 'Michael Brown',
      gender: 'Male',
      age: 64,
      time: '11:00 AM',
      status: 'scheduled',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final staff = authState.currentUser is StaffUser
        ? authState.currentUser as StaffUser
        : StaffUser(
            id: 'staff_demo',
            email: 'staff@cure.app',
            name: 'Clinical Staff Member',
            designation: 'Staff',
            clinicName: 'Cure Clinic',
          );

    final totalCount = _patients.length;
    final scheduledCount = _patients.where((p) => p.status == 'scheduled').length;
    final arrivedCount = _patients.where((p) => p.status == 'arrived').length;
    final checkedInCount = _patients.where((p) => p.status == 'checked_in').length;

    final filteredList = _patients.where((p) {
      final matchSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.tokenNumber.contains(_searchQuery);
      if (!matchSearch) return false;

      if (_activeFilter == 'scheduled') return p.status == 'scheduled';
      if (_activeFilter == 'arrived') return p.status == 'arrived';
      if (_activeFilter == 'checked_in') return p.status == 'checked_in';
      return true;
    }).toList();

    final todayDate = DateFormat('EEEE, MMM d').format(DateTime.now());

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
              child: const Icon(Icons.assignment_ind_outlined, color: Color(0xFF0F766E), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                Text(
                  "Clinical Staff · $todayDate",
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.muted),
            tooltip: "Log Out",
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/');
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key("simple-walkin-fab"),
        onPressed: _openSimpleWalkInModal,
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text(
          "+ Add Walk-In Patient",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Simple Top Stats Summary
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _buildSimpleCard("Total Today", totalCount.toString(), const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSimpleCard("Waiting", scheduledCount.toString(), AppColors.muted, const Color(0xFFF3F4F6)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSimpleCard("Arrived", arrivedCount.toString(), const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSimpleCard("Checked In", checkedInCount.toString(), const Color(0xFF15803D), const Color(0xFFDCFCE7)),
                ),
              ],
            ),
          ),

          // Search & Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search patient by name or token #...",
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.muted),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterPill("All ($totalCount)", 'all'),
                      _buildFilterPill("Scheduled ($scheduledCount)", 'scheduled'),
                      _buildFilterPill("Arrived ($arrivedCount)", 'arrived'),
                      _buildFilterPill("Checked In ($checkedInCount)", 'checked_in'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Patient List View
          Expanded(
            child: filteredList.isEmpty
                ? const Center(
                    child: Text(
                      "No patients found",
                      style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: 4, bottom: 90),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final p = filteredList[index];
                      return _buildPatientCard(p);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleCard(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String title, String key) {
    final isSelected = _activeFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = key;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: isSelected ? const Color(0xFF0F766E) : AppColors.border),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(SimplePatientItem p) {
    Color statusBg = const Color(0xFFF3F4F6);
    Color statusColor = AppColors.muted;
    String statusText = "Scheduled";

    if (p.status == 'arrived') {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFD97706);
      statusText = "Arrived in Lobby";
    } else if (p.status == 'checked_in') {
      statusBg = const Color(0xFFDCFCE7);
      statusColor = const Color(0xFF15803D);
      statusText = "Checked In";
    } else if (p.status == 'completed') {
      statusBg = const Color(0xFFF3F4F6);
      statusColor = AppColors.muted;
      statusText = "Completed";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Token Box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(
                "#${p.tokenNumber}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.onSurface),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Simple Info: Name, Gender, Age
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                      ),
                    ),
                    if (p.isWalkIn) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Text(
                          "WALK-IN",
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF6D28D9)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "Gender: ${p.gender}  ·  Age: ${p.age} years",
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  "Time: ${p.time}",
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),

          // Actions / Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                ),
              ),
              const SizedBox(height: 8),

              // 1. If Scheduled -> Show "Mark Arrived"
              if (p.status == 'scheduled')
                ElevatedButton(
                  key: Key("mark-arrived-${p.id}"),
                  onPressed: () {
                    setState(() {
                      p.status = 'arrived';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${p.name} marked Arrived in Lobby!"), backgroundColor: const Color(0xFFD97706)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  ),
                  child: const Text("Mark Arrived", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                )

              // 2. If Arrived -> Show "Check In"
              else if (p.status == 'arrived')
                ElevatedButton(
                  key: Key("check-in-${p.id}"),
                  onPressed: () {
                    setState(() {
                      p.status = 'checked_in';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${p.name} Checked In successfully!"), backgroundColor: const Color(0xFF15803D)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  ),
                  child: const Text("Check In", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                )

              // 3. If Checked In -> Show "Completed" toggle
              else if (p.status == 'checked_in')
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      p.status = 'completed';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF15803D),
                    side: const BorderSide(color: Color(0xFF15803D)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  ),
                  child: const Text("Complete", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openSimpleWalkInModal() {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String gender = "Female";

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Add Walk-In Patient",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Name input
                  const Text("Patient Name *", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: "Enter full name",
                      filled: true,
                      fillColor: AppColors.surfaceSecondary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Gender & Age Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Gender", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: gender,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surfaceSecondary,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Age (years) *", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: ageCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "e.g. 35",
                                filled: true,
                                fillColor: AppColors.surfaceSecondary,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Submit Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (nameCtrl.text.trim().isEmpty) return;
                            final nextToken = (_patients.length + 1).toString().padLeft(2, '0');
                            final nowTime = DateFormat('hh:mm a').format(DateTime.now());

                            setState(() {
                              _patients.add(
                                SimplePatientItem(
                                  id: 'walkin_$nextToken',
                                  tokenNumber: nextToken,
                                  name: nameCtrl.text.trim(),
                                  gender: gender,
                                  age: int.tryParse(ageCtrl.text.trim()) ?? 30,
                                  time: 'Walk-In ($nowTime)',
                                  isWalkIn: true,
                                  status: 'arrived',
                                ),
                              );
                            });

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Patient ${nameCtrl.text.trim()} added with Token #$nextToken (Arrived)!"),
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
                          child: const Text("Mark Arrived", style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameCtrl.text.trim().isEmpty) return;
                            final nextToken = (_patients.length + 1).toString().padLeft(2, '0');
                            final nowTime = DateFormat('hh:mm a').format(DateTime.now());

                            setState(() {
                              _patients.add(
                                SimplePatientItem(
                                  id: 'walkin_$nextToken',
                                  tokenNumber: nextToken,
                                  name: nameCtrl.text.trim(),
                                  gender: gender,
                                  age: int.tryParse(ageCtrl.text.trim()) ?? 30,
                                  time: 'Walk-In ($nowTime)',
                                  isWalkIn: true,
                                  status: 'checked_in',
                                ),
                              );
                            });

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Patient ${nameCtrl.text.trim()} Checked In with Token #$nextToken!"),
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
                          child: const Text("Direct Check-In", style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
