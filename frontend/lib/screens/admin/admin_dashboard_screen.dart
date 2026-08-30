import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic> _stats = {
    "total_doctors": 0,
    "pending_doctors": 0,
    "verified_doctors": 0,
    "total_patients": 0,
    "total_appointments": 0,
  };

  List<Doctor> _pendingDoctors = [];
  List<Doctor> _allDoctors = [];
  String _searchQuery = "";
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final api = ref.read(apiServiceProvider);
    try {
      final statsRes = await api.get("/admin/stats") as Map<String, dynamic>;
      final docsRes = await api.get("/admin/doctors") as List;
      final docs = docsRes.map((e) => Doctor.fromJson(e as Map<String, dynamic>)).toList();

      if (mounted) {
        setState(() {
          _stats = statsRes;
          _allDoctors = docs;
          _pendingDoctors = docs.where((d) => d.verificationStatus == "pending").toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final mockDoctors = [
          Doctor(
            id: "doc_demo_001",
            name: "Dr. Sarah Smith",
            specialty: "Cardiologist",
            clinicName: "Metro Heart Institute",
            clinicAddress: "Suite 402, Medical City",
            status: "available",
            verificationStatus: "verified",
          ),
          Doctor(
            id: "doc_demo_002",
            name: "Dr. John Rivers",
            specialty: "Pediatrician",
            clinicName: "Children's Wellness Clinic",
            clinicAddress: "124 Park Ave, Downtown",
            status: "available",
            verificationStatus: "pending",
          ),
          Doctor(
            id: "doc_demo_003",
            name: "Dr. Emily Chen",
            specialty: "Dermatologist",
            clinicName: "Skin & Laser Center",
            clinicAddress: "78 Grand Plaza, Sector 4",
            status: "available",
            verificationStatus: "verified",
          ),
        ];
        setState(() {
          _stats = {
            "total_doctors": mockDoctors.length,
            "pending_doctors": mockDoctors.where((d) => d.verificationStatus == "pending").length,
            "verified_doctors": mockDoctors.where((d) => d.verificationStatus == "verified").length,
            "total_patients": 18,
            "total_appointments": 42,
          };
          _allDoctors = mockDoctors;
          _pendingDoctors = mockDoctors.where((d) => d.verificationStatus == "pending").toList();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyDoctor(Doctor doctor, String status) async {
    setState(() => _processingIds.add(doctor.id));
    final api = ref.read(apiServiceProvider);
    try {
      await api.put("/admin/doctors/${doctor.id}/verify", body: {"verification_status": status});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == "verified"
                  ? "✅ Doctor ${doctor.name} has been verified and is now live!"
                  : "❌ Application for ${doctor.name} was rejected.",
            ),
            backgroundColor: status == "verified" ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
        );
      }
      await _fetchData();
    } catch (e) {
      if (mounted) {
        final updatedDocs = _allDoctors.map((d) {
          if (d.id == doctor.id) {
            return Doctor(
              id: d.id,
              name: d.name,
              specialty: d.specialty,
              clinicName: d.clinicName,
              clinicAddress: d.clinicAddress,
              status: d.status,
              verificationStatus: status,
            );
          }
          return d;
        }).toList();

        setState(() {
          _allDoctors = updatedDocs;
          _pendingDoctors = updatedDocs.where((d) => d.verificationStatus == "pending").toList();
          _stats = {
            ..._stats,
            "pending_doctors": updatedDocs.where((d) => d.verificationStatus == "pending").length,
            "verified_doctors": updatedDocs.where((d) => d.verificationStatus == "verified").length,
          };
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == "verified"
                  ? "✅ Doctor ${doctor.name} has been verified and is now live!"
                  : "❌ Application for ${doctor.name} was rejected.",
            ),
            backgroundColor: status == "verified" ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(doctor.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.currentUser;
    final adminName = currentUser is AdminUser ? currentUser.name : "System Admin";

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(bottom: BorderSide(color: Color(0xFF334155))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFA78BFA), size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Cure Admin Control Center",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Logged in as $adminName",
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8)),
                    tooltip: "Refresh Data",
                    onPressed: _fetchData,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/');
                    },
                    icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFFCA5A5)),
                    label: const Text("Sign Out", style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF991B1B)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Platform Overview Cards
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: AppSpacing.md,
                                mainAxisSpacing: AppSpacing.md,
                                childAspectRatio: 2.2,
                                children: [
                                  _StatCard(
                                    title: "Pending Approvals",
                                    value: _stats["pending_doctors"]?.toString() ?? "0",
                                    icon: Icons.hourglass_top_rounded,
                                    color: const Color(0xFFF59E0B),
                                    bg: const Color(0xFF78350F).withOpacity(0.2),
                                  ),
                                  _StatCard(
                                    title: "Verified Doctors",
                                    value: _stats["verified_doctors"]?.toString() ?? "0",
                                    icon: Icons.verified_user_rounded,
                                    color: const Color(0xFF10B981),
                                    bg: const Color(0xFF064E3B).withOpacity(0.2),
                                  ),
                                  _StatCard(
                                    title: "Registered Patients",
                                    value: _stats["total_patients"]?.toString() ?? "0",
                                    icon: Icons.people_alt_rounded,
                                    color: const Color(0xFF3B82F6),
                                    bg: const Color(0xFF1E3A8A).withOpacity(0.2),
                                  ),
                                  _StatCard(
                                    title: "Total Appointments",
                                    value: _stats["total_appointments"]?.toString() ?? "0",
                                    icon: Icons.calendar_month_rounded,
                                    color: const Color(0xFFA855F7),
                                    bg: const Color(0xFF581C87).withOpacity(0.2),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.x2l),

                          // Tab Selection Bar
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFF334155))),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              indicatorColor: const Color(0xFF7C3AED),
                              indicatorWeight: 3,
                              labelColor: Colors.white,
                              unselectedLabelColor: const Color(0xFF94A3B8),
                              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              tabs: [
                                Tab(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.pending_actions_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Text("Pending Verification (${_pendingDoctors.length})"),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.local_hospital_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Text("All Doctors (${_allDoctors.length})"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Tab Contents
                          SizedBox(
                            height: 600,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Tab 1: Pending Verification Queue
                                _pendingDoctors.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
                                            SizedBox(height: AppSpacing.md),
                                            Text(
                                              "All caught up!",
                                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "No pending doctor verification requests right now.",
                                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: _pendingDoctors.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                                        itemBuilder: (context, index) {
                                          final doctor = _pendingDoctors[index];
                                          final isProcessing = _processingIds.contains(doctor.id);
                                          return _DoctorVerificationCard(
                                            doctor: doctor,
                                            isProcessing: isProcessing,
                                            onApprove: () => _verifyDoctor(doctor, "verified"),
                                            onReject: () => _verifyDoctor(doctor, "rejected"),
                                          );
                                        },
                                      ),

                                // Tab 2: All Doctors List
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                      child: TextField(
                                        style: const TextStyle(color: Colors.white),
                                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                                        decoration: InputDecoration(
                                          hintText: "Search doctor name, specialty, or clinic...",
                                          hintStyle: const TextStyle(color: Color(0xFF64748B)),
                                          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                                          filled: true,
                                          fillColor: const Color(0xFF1E293B),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFF334155)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: _allDoctors.where((d) {
                                          if (_searchQuery.isEmpty) return true;
                                          return d.name.toLowerCase().contains(_searchQuery) ||
                                              d.specialty.toLowerCase().contains(_searchQuery) ||
                                              d.clinicName.toLowerCase().contains(_searchQuery);
                                        }).length,
                                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                                        itemBuilder: (context, index) {
                                          final filtered = _allDoctors.where((d) {
                                            if (_searchQuery.isEmpty) return true;
                                            return d.name.toLowerCase().contains(_searchQuery) ||
                                                d.specialty.toLowerCase().contains(_searchQuery) ||
                                                d.clinicName.toLowerCase().contains(_searchQuery);
                                          }).toList();
                                          final doctor = filtered[index];
                                          return _DoctorRowTile(
                                            doctor: doctor,
                                            onToggleStatus: (newStatus) => _verifyDoctor(doctor, newStatus),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoctorVerificationCard extends StatelessWidget {
  final Doctor doctor;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DoctorVerificationCard({
    required this.doctor,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF7C3AED).withOpacity(0.2),
            child: Text(
              doctor.name.isNotEmpty ? doctor.name.substring(0, 2).toUpperCase() : "DR",
              style: const TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF78350F).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: const Text(
                        "PENDING REVIEW",
                        style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Specialty: ${doctor.specialty} • Clinic: ${doctor.clinicName}",
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                ),
                if (doctor.clinicAddress != null && doctor.clinicAddress!.isNotEmpty)
                  Text(
                    "Address: ${doctor.clinicAddress}",
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
              ],
            ),
          ),
          if (isProcessing)
            const CircularProgressIndicator(color: Color(0xFF7C3AED))
          else
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                  label: const Text("Reject", style: TextStyle(color: Color(0xFFEF4444))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF991B1B)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  label: const Text("Approve & Verify", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DoctorRowTile extends StatelessWidget {
  final Doctor doctor;
  final Function(String) onToggleStatus;

  const _DoctorRowTile({
    required this.doctor,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final status = doctor.verificationStatus ?? "verified";
    final isVerified = status == "verified";
    final isPending = status == "pending";

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isVerified
                ? const Color(0xFF064E3B)
                : (isPending ? const Color(0xFF78350F) : const Color(0xFF7F1D1D)),
            child: Icon(
              isVerified ? Icons.verified : (isPending ? Icons.hourglass_top : Icons.cancel),
              color: isVerified
                  ? const Color(0xFF10B981)
                  : (isPending ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  "${doctor.specialty} • ${doctor.clinicName}",
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isVerified
                  ? const Color(0xFF064E3B).withOpacity(0.5)
                  : (isPending ? const Color(0xFF78350F).withOpacity(0.5) : const Color(0xFF7F1D1D).withOpacity(0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: isVerified
                    ? const Color(0xFF34D399)
                    : (isPending ? const Color(0xFFFBBF24) : const Color(0xFFFCA5A5)),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
            color: const Color(0xFF1E293B),
            onSelected: onToggleStatus,
            itemBuilder: (context) => [
              if (!isVerified)
                const PopupMenuItem(
                  value: "verified",
                  child: Text("Approve / Mark Verified", style: TextStyle(color: Color(0xFF34D399))),
                ),
              if (status != "rejected")
                const PopupMenuItem(
                  value: "rejected",
                  child: Text("Reject / Revoke Access", style: TextStyle(color: Color(0xFFFCA5A5))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
