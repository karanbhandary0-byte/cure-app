import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../config/status_meta.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(patientHomeProvider.notifier).load();
    });
  }

  void _showPatientMemberSelectorModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final membersState = ref.watch(patientMembersProvider);
            final members = membersState.members;
            final selected = membersState.selectedMember;
            final location = ref.watch(patientLocationProvider);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Drag Indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Select Patient Profile",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Action Buttons Row (Swiggy Style)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            key: const Key("add-member-action-card"),
                            onTap: () {
                              Navigator.pop(ctx);
                              _showAddMemberModal(context, ref);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_add_alt_1, color: Color(0xFF0F766E), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "Add New Member",
                                    style: TextStyle(
                                      color: Color(0xFF0F766E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              _showLocationSelectorModal(context, ref);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.location_on, color: Color(0xFFE11D48), size: 18),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      location,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF334155),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section Title
                    const Text(
                      "SAVED PATIENT PROFILES",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Members List
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: members.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final isSelected = member.id == selected.id;

                          return InkWell(
                            key: Key("member-card-${member.id}"),
                            onTap: () {
                              ref.read(patientMembersProvider.notifier).selectMember(member);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Active patient profile switched to ${member.name}"),
                                  backgroundColor: const Color(0xFF0F766E),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x04000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Left Avatar container
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF0F766E).withOpacity(0.12)
                                          : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        member.relation.toLowerCase().contains("friend")
                                            ? Icons.people_outline
                                            : member.relation.toLowerCase().contains("child")
                                                ? Icons.child_care
                                                : Icons.person_outline,
                                        color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name & Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              member.name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                member.relation,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF475569),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          "${member.ageOrDob} · ${member.gender}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Selected Badge
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "SELECTED",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF16A34A),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    )
                                  else
                                    const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
                                ],
                              ),
                            ),
                          );
                        },
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

  void _showAddMemberModal(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final ageDobController = TextEditingController();
    String selectedGender = "Male";
    String selectedRelation = "Family";

    final genderOptions = ["Male", "Female", "Other"];
    final relationOptions = [
      "Family",
      "Friend",
      "Family (Spouse)",
      "Family (Child)",
      "Family (Parent)",
      "Family (Sibling)",
      "Other",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Add Member",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 8),

                    // 1. Full Name
                    const Text(
                      "Full name *",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      key: const Key("add-member-name-input"),
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "e.g. Roy Kumar / Priya Kumar",
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Date of birth / age
                    const Text(
                      "Date of birth / age *",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      key: const Key("add-member-age-input"),
                      controller: ageDobController,
                      decoration: InputDecoration(
                        hintText: "e.g. 35 yrs or 14/05/1991",
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3. Gender
                    const Text(
                      "Gender *",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: genderOptions.map((g) {
                        final isSelected = selectedGender == g;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(g),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0F766E),
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            onSelected: (_) {
                              setModalState(() => selectedGender = g);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // 4. Relation
                    const Text(
                      "Relation whether family or friend *",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRelation,
                          isExpanded: true,
                          items: relationOptions.map((rel) {
                            return DropdownMenuItem(value: rel, child: Text(rel, style: const TextStyle(fontSize: 14)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedRelation = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        key: const Key("save-member-submit-btn"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          final name = nameController.text.trim();
                          final age = ageDobController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter member full name.")),
                            );
                            return;
                          }

                          ref.read(patientMembersProvider.notifier).addMember(
                                name: name,
                                ageOrDob: age.isNotEmpty ? age : "Age not specified",
                                gender: selectedGender,
                                relation: selectedRelation,
                                selectAfterAdd: true,
                              );

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Member '$name' added & selected as active patient."),
                              backgroundColor: const Color(0xFF0F766E),
                            ),
                          );
                        },
                        child: const Text(
                          "Save & Set Active Member",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientHomeProvider);

    if (state.isLoading || state.patient == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator(color: AppColors.brand)),
      );
    }

    final location = ref.watch(patientLocationProvider);
    final membersState = ref.watch(patientMembersProvider);
    final activeMember = membersState.selectedMember;

    // Filter appointments strictly for activeMember
    final memberAppointments = state.appointments.where((a) {
      if (a.patientName != null && a.patientName!.trim().isNotEmpty) {
        return a.patientName!.trim().toLowerCase() == activeMember.name.trim().toLowerCase();
      }
      if (a.patientId.isNotEmpty) {
        return a.patientId.contains(activeMember.id);
      }
      return activeMember.isPrimary;
    }).toList();

    final next = memberAppointments.cast<Appointment?>().firstWhere(
          (a) => a?.status == "scheduled" || a?.status == "delayed" || a?.status == "booked",
          orElse: () => null,
        );
    final doctorMeta = (next != null && (next.doctor != null || next.doctorName != null))
        ? StatusMeta.get(next.doctor?.status)
        : null;

    return Scaffold(
      key: const Key("patient-home-screen"),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(patientHomeProvider.notifier).load(),
          color: AppColors.brand,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.x3l),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Swiggy-Style Top Patient Member Switcher & Location Bar
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Active Member & Switcher Tap Area
                      Expanded(
                        child: InkWell(
                          key: const Key("patient-switcher-bar"),
                          onTap: () => _showPatientMemberSelectorModal(context, ref),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top location tag
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 12, color: Color(0xFFE11D48)),
                                    const SizedBox(width: 3),
                                    Text(
                                      location,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),

                                // Main Member Name Row (Like Swiggy's Location title)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        activeMember.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.onSurface,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down, size: 22, color: Color(0xFF0F766E)),
                                  ],
                                ),
                                const SizedBox(height: 2),

                                // Subtitle: Relation & Age/Gender
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F766E).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        activeMember.relation.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${activeMember.ageOrDob} · ${activeMember.gender}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Logout / Profile icon
                      IconButton(
                        key: const Key("logout-button"),
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          context.go('/');
                        },
                        icon: const Icon(Icons.logout, color: AppColors.onSurface, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceSecondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Search Bar for Disease / Symptom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                  child: InkWell(
                    key: const Key("disease-search-bar"),
                    onTap: () => context.push('/patient/book'),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: AppColors.brand, size: 20),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              "Search disease (e.g. Fever, Heart pain) & nearby doctors...",
                              style: TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Active Appointment Hero Banner
                if (next != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "NEXT APPOINTMENT FOR ${activeMember.name.toUpperCase()}",
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              _StatusTag(status: next.status),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            next.doctorName ?? "Dr. Consultation",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            next.doctor?.specialty ?? next.reason ?? "General Physician",
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: AppColors.brand),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                DateFormat("EEE, MMM d · h:mm a").format(next.scheduledAt),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          if (doctorMeta != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: doctorMeta.bg,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.circle, size: 8, color: doctorMeta.color),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    doctorMeta.label,
                                    style: TextStyle(
                                      color: doctorMeta.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                // Quick Navigation Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Row(
                    children: [
                      _ActionTile(
                        icon: Icons.calendar_today,
                        color: const Color(0xFF0F766E),
                        label: "Book Visit",
                        onTap: () => context.push('/patient/book'),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _ActionTile(
                        icon: Icons.history,
                        color: const Color(0xFF4F46E5),
                        label: "Medical History",
                        onTap: () => context.push('/patient/records'),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _ActionTile(
                        icon: Icons.rate_review_outlined,
                        color: const Color(0xFFEA580C),
                        label: "Feedback",
                        onTap: () => context.push('/patient/feedback'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Past / Scheduled Appointments Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Appointments for ${activeMember.name}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/patient/records'),
                        child: const Text("View all", style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                if (memberAppointments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          "No appointments booked for ${activeMember.name} yet.",
                          style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: memberAppointments.length > 3 ? 3 : memberAppointments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final appt = memberAppointments[index];
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.brandTertiary,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: const Icon(Icons.medical_services_outlined, color: AppColors.brand, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appt.doctorName ?? "Doctor",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      appt.doctor?.specialty ?? appt.reason ?? "Consultation",
                                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              _StatusTag(status: appt.status),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationSelectorModal(BuildContext context, WidgetRef ref) {
    final currentLocation = ref.read(patientLocationProvider);
    final controller = TextEditingController(text: currentLocation);

    final popularCities = [
      "Mumbai",
      "Delhi",
      "Bangalore",
      "Indiranagar, Bangalore",
      "Hyderabad",
      "Chennai",
      "Kolkata",
      "Pune",
      "Ahmedabad",
      "Mangaluru",
      "Manipal",
      "Udupi",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.xl,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.brand, size: 22),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        "Select Your Location",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
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
              const Text(
                "Enter your city, area, or locality manually:",
                style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "e.g. Indiranagar, Bengaluru or Bandra West, Mumbai",
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                "POPULAR CITIES",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.5),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: popularCities.map((city) {
                  final isSelected = currentLocation.toLowerCase() == city.toLowerCase();
                  return ChoiceChip(
                    label: Text(city),
                    selected: isSelected,
                    selectedColor: AppColors.brand,
                    backgroundColor: AppColors.surfaceSecondary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      ref.read(patientLocationProvider.notifier).state = city;
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      ref.read(patientLocationProvider.notifier).state = text;
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text("Set Location", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String status;

  const _StatusTag({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.brandTertiary;
    Color color = AppColors.brand;

    if (status == "completed") {
      bg = AppColors.successBg;
      color = const Color(0xFF065F46);
    } else if (status == "delayed") {
      bg = AppColors.warningBg;
      color = const Color(0xFF92400E);
    } else if (status == "cancelled") {
      bg = AppColors.errorBg;
      color = const Color(0xFF991B1B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
