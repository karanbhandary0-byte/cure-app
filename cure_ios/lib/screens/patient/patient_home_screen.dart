import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../config/status_meta.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../models/appointment.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientHomeProvider);

    if (state.isLoading || state.patient == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator(color: AppColors.brand)),
      );
    }

    final patient = state.patient!;
    final location = ref.watch(patientLocationProvider);
    final next = state.appointments.cast<Appointment?>().firstWhere(
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
                // Top Location Bar & Header
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            key: const Key("patient-location-bar"),
                            onTap: () => _showLocationSelectorModal(context, ref),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.brandTertiary,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: AppColors.brand),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Location: $location",
                                    style: const TextStyle(
                                      color: AppColors.brand,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.brand),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            patient.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
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

                // Doctor Status Banner
                if (next != null && doctorMeta != null) ...[
                  Builder(
                    builder: (context) {
                      final docName = (next.doctor?.name.isNotEmpty == true)
                          ? next.doctor!.name
                          : (next.doctorName?.isNotEmpty == true ? next.doctorName! : 'Doctor');
                      final delay = next.doctor?.delayMinutes ?? 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: doctorMeta.bg,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Row(
                            children: [
                              Icon(doctorMeta.icon, size: 22, color: doctorMeta.color),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "$docName is ${doctorMeta.label}",
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: doctorMeta.color),
                                    ),
                                    const SizedBox(height: 2),
                                    if (delay > 0)
                                      Text(
                                        "Running $delay mins late · Expected visit at ${DateFormat.jm().format(next.scheduledAt)}",
                                        style: TextStyle(fontSize: 13, color: doctorMeta.color),
                                      )
                                    else
                                      Text(
                                        "Your next visit: ${DateFormat('MMM d, h:mm a').format(next.scheduledAt)}",
                                        style: TextStyle(fontSize: 13, color: doctorMeta.color),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],

                // Pending Feedback Card
                if (state.pendingFeedbackAppts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: InkWell(
                      key: const Key("pending-feedback-card"),
                      onTap: () => context.push('/patient/feedback'),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("How are you feeling?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Share post-visit feedback (${state.pendingFeedbackAppts.length} pending)",
                                    style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Quick Actions Section
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.lg, bottom: AppSpacing.sm),
                  child: Text("Quick actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Row(
                    children: [
                      _ActionTile(
                        key: const Key("book-action"),
                        icon: Icons.add_circle,
                        color: AppColors.brand,
                        label: "Book visit",
                        onTap: () => context.push('/patient/book'),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _ActionTile(
                        key: const Key("records-action"),
                        icon: Icons.description,
                        color: AppColors.success,
                        label: "Records",
                        onTap: () => context.push('/patient/records'),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _ActionTile(
                        key: const Key("feedback-action"),
                        icon: Icons.favorite,
                        color: AppColors.error,
                        label: "Feedback",
                        onTap: () => context.push('/patient/feedback'),
                      ),
                    ],
                  ),
                ),

                // Appointments Section
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl, top: AppSpacing.lg, bottom: AppSpacing.sm),
                  child: Text("Your appointments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                ),

                if (state.appointments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                    child: Text("No appointments yet.", style: TextStyle(color: AppColors.muted)),
                  )
                else
                  ...state.appointments.take(5).map((a) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.doctor?.name ?? "Doctor", style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${DateFormat('MMM d, h:mm a').format(a.scheduledAt)}${a.reason != null && a.reason!.isNotEmpty ? ' · ${a.reason}' : ''}",
                                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            _StatusTag(status: a.status),
                          ],
                        ),
                      )),
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
      "Hyderabad",
      "Chennai",
      "Kolkata",
      "Pune",
      "New York",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
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
                      SizedBox(width: 8),
                      Text(
                        "Select Your Location",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface),
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
                  hintText: "e.g. Bandra West, Mumbai or Connaught Place",
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
