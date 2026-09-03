import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class DoctorLoginScreen extends ConsumerStatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  ConsumerState<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends ConsumerState<DoctorLoginScreen> {
  bool isRegister = false;

  // Login & Credentials
  final _emailController = TextEditingController(text: "dr.smith@cure.app");
  final _passwordController = TextEditingController(text: "doctor123");

  // Registration Specific Controllers
  final _nameController = TextEditingController();
  final _degreeController = TextEditingController(text: "MBBS, MD");
  final _specialtyController = TextEditingController(text: "Cardiology");
  final _subSpecialtyController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _councilController = TextEditingController(text: "Karnataka Medical Council");
  final _experienceController = TextEditingController(text: "8");
  final _clinicController = TextEditingController(text: "Cure Medical Center");
  final _clinicAddressController = TextEditingController();

  // Profile Photo (Base64 data or image url)
  String? _profilePhotoBase64;
  final ImagePicker _picker = ImagePicker();

  // Selected Languages
  final List<String> _selectedLanguages = ["English", "Hindi"];
  final List<String> _availableLanguages = [
    "English",
    "Hindi",
    "Kannada",
    "Tamil",
    "Telugu",
    "Malayalam",
    "Marathi",
    "Bengali",
    "Gujarati",
    "Punjabi",
  ];

  final List<String> _commonDegrees = [
    "MBBS",
    "MBBS, MD",
    "MBBS, MS",
    "MBBS, DNB",
    "MD, DM",
    "MS, MCh",
    "BDS",
    "BDS, MDS",
    "Other",
  ];

  final List<String> _commonSpecialties = [
    "General Medicine",
    "Cardiology",
    "Dermatology",
    "Pediatrics",
    "Orthopedics",
    "Neurology",
    "Gynecology & Obstetrics",
    "ENT / Otorhinolaryngology",
    "Ophthalmology",
    "Psychiatry",
    "Gastroenterology",
    "Pulmonology",
    "Oncology",
    "Endocrinology",
    "Other",
  ];

  final List<String> _commonCouncils = [
    "Karnataka Medical Council",
    "Maharashtra Medical Council",
    "Delhi Medical Council",
    "Tamil Nadu Medical Council",
    "Kerala State Medical Council",
    "Andhra Pradesh Medical Council",
    "Telangana State Medical Council",
    "Uttar Pradesh Medical Council",
    "West Bengal Medical Council",
    "National Medical Commission (NMC / MCI)",
    "Other State Medical Council",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _degreeController.dispose();
    _specialtyController.dispose();
    _subSpecialtyController.dispose();
    _regNumberController.dispose();
    _councilController.dispose();
    _experienceController.dispose();
    _clinicController.dispose();
    _clinicAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Profile Photo",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFF0F766E)),
                  title: const Text("Choose from Gallery"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setState(() {
                          _profilePhotoBase64 = "data:image/jpeg;base64,${base64Encode(bytes)}";
                        });
                      }
                    } catch (_) {}
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFF0F766E)),
                  title: const Text("Take a Photo with Camera"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final picked = await _picker.pickImage(source: ImageSource.camera, maxWidth: 600, maxHeight: 600);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setState(() {
                          _profilePhotoBase64 = "data:image/jpeg;base64,${base64Encode(bytes)}";
                        });
                      }
                    } catch (_) {}
                  },
                ),
                if (_profilePhotoBase64 != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text("Remove Photo", style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _profilePhotoBase64 = null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit() async {
    if (isRegister) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your Full Name.")));
        return;
      }
      if (_regNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your Medical Council Registration Number.")));
        return;
      }
    }

    final expYears = int.tryParse(_experienceController.text.trim()) ?? 0;
    final languagesString = _selectedLanguages.join(", ");

    final success = await ref.read(authProvider.notifier).doctorAuth(
          isRegister: isRegister,
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : "Dr. Doctor",
          specialty: _specialtyController.text.trim(),
          clinicName: _clinicController.text.trim().isNotEmpty ? _clinicController.text.trim() : "Cure Medical Center",
          clinicAddress: _clinicAddressController.text.trim(),
          profilePhoto: _profilePhotoBase64,
          medicalDegree: _degreeController.text.trim(),
          subSpecialization: _subSpecialtyController.text.trim(),
          registrationNumber: _regNumberController.text.trim(),
          registrationCouncil: _councilController.text.trim(),
          experienceYears: expYears,
          languagesSpoken: languagesString,
        );

    if (success && mounted) {
      context.go('/doctor/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              InkWell(
                key: const Key("back-button"),
                onTap: () => context.go('/'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.chevron_left, color: AppColors.onSurface, size: 22),
                    SizedBox(width: 4),
                    Text(
                      "Back",
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Header Badge & Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      color: Color(0xFF0F766E),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRegister ? "Doctor Registration" : "Doctor Sign In",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          isRegister
                              ? "Enter your credentials & medical council details"
                              : "Welcome back to Cure clinical portal",
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Registration Form
              if (isRegister) ...[
                // Profile Photo Picker Card
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickProfilePhoto,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F766E).withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0F766E), width: 2),
                              ),
                              child: _profilePhotoBase64 != null
                                  ? ClipOval(
                                      child: Image.memory(
                                        base64Decode(_profilePhotoBase64!.split(",").last),
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.person, size: 50, color: Color(0xFF0F766E)),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickProfilePhoto,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0F766E),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: _pickProfilePhoto,
                        child: const Text(
                          "Upload Profile Photo",
                          style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // SECTION 1: Personal & Degree
                _buildSectionHeader("1. Personal & Professional Details"),
                _Field(
                  key: const Key("reg-name"),
                  label: "Full name *",
                  hint: "Dr. Sarah Mitchell",
                  controller: _nameController,
                  icon: Icons.person_outline,
                ),

                // Medical Degree Selector
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Medical degree (MBBS, MD, etc.) *",
                        style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _commonDegrees.contains(_degreeController.text) ? _degreeController.text : "Other",
                            isExpanded: true,
                            items: _commonDegrees.map((deg) {
                              return DropdownMenuItem(value: deg, child: Text(deg, style: const TextStyle(fontSize: 14)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _degreeController.text = val);
                              }
                            },
                          ),
                        ),
                      ),
                      if (_degreeController.text == "Other") ...[
                        const SizedBox(height: 6),
                        TextField(
                          controller: _degreeController,
                          decoration: InputDecoration(
                            hintText: "Enter custom medical degree",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Years of experience
                _Field(
                  key: const Key("reg-experience"),
                  label: "Years of experience *",
                  hint: "e.g. 8",
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  icon: Icons.history,
                ),

                const SizedBox(height: AppSpacing.lg),

                // SECTION 2: Specialization & Sub-specialization
                _buildSectionHeader("2. Specialization & Clinical Focus"),

                // Specialization Dropdown
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Specialization *",
                        style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _commonSpecialties.contains(_specialtyController.text) ? _specialtyController.text : "Other",
                            isExpanded: true,
                            items: _commonSpecialties.map((spec) {
                              return DropdownMenuItem(value: spec, child: Text(spec, style: const TextStyle(fontSize: 14)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _specialtyController.text = val);
                              }
                            },
                          ),
                        ),
                      ),
                      if (_specialtyController.text == "Other") ...[
                        const SizedBox(height: 6),
                        TextField(
                          controller: _specialtyController,
                          decoration: InputDecoration(
                            hintText: "Enter custom specialization",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                _Field(
                  key: const Key("reg-sub-specialty"),
                  label: "Sub-specialization",
                  hint: "e.g. Interventional Cardiology, Spine Surgery (Optional)",
                  controller: _subSpecialtyController,
                  icon: Icons.biotech_outlined,
                ),

                const SizedBox(height: AppSpacing.lg),

                // SECTION 3: Medical Council Registration
                _buildSectionHeader("3. Medical Council Registration"),

                _Field(
                  key: const Key("reg-number"),
                  label: "Medical council registration number *",
                  hint: "e.g. KMC-84920 / MCI-19283",
                  controller: _regNumberController,
                  icon: Icons.verified_user_outlined,
                ),

                // Registration State / Council Dropdown
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Registration state/council *",
                        style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _commonCouncils.contains(_councilController.text) ? _councilController.text : "Other State Medical Council",
                            isExpanded: true,
                            items: _commonCouncils.map((coun) {
                              return DropdownMenuItem(value: coun, child: Text(coun, style: const TextStyle(fontSize: 14)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _councilController.text = val);
                              }
                            },
                          ),
                        ),
                      ),
                      if (_councilController.text == "Other State Medical Council") ...[
                        const SizedBox(height: 6),
                        TextField(
                          controller: _councilController,
                          decoration: InputDecoration(
                            hintText: "Enter state or medical council name",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // SECTION 4: Languages Spoken
                _buildSectionHeader("4. Languages Spoken"),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableLanguages.map((lang) {
                    final isSelected = _selectedLanguages.contains(lang);
                    return FilterChip(
                      label: Text(lang),
                      selected: isSelected,
                      selectedColor: const Color(0xFF0F766E).withOpacity(0.18),
                      checkmarkColor: const Color(0xFF0F766E),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF475569),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedLanguages.add(lang);
                          } else {
                            _selectedLanguages.remove(lang);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.lg),

                // SECTION 5: Clinic Info & Login Credentials
                _buildSectionHeader("5. Clinic & Login Credentials"),
                _Field(
                  key: const Key("reg-clinic"),
                  label: "Clinic name",
                  hint: "Cure Medical Center",
                  controller: _clinicController,
                  icon: Icons.local_hospital_outlined,
                ),
                _Field(
                  key: const Key("reg-clinic-address"),
                  label: "Clinic address / Location",
                  hint: "Suite 402, Medical Plaza, City",
                  controller: _clinicAddressController,
                  icon: Icons.location_on_outlined,
                ),
              ],

              // Email & Password Fields
              _Field(
                key: const Key("login-email"),
                label: "Email *",
                hint: "doctor@clinic.com",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email_outlined,
              ),

              _Field(
                key: const Key("login-password"),
                label: "Password *",
                hint: "••••••••",
                controller: _passwordController,
                obscureText: true,
                icon: Icons.lock_outline,
              ),

              if (authState.error != null && authState.error!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key("doctor-login-submit"),
                  onPressed: authState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isRegister ? "Submit & Register Doctor Profile" : "Sign In",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Toggle Mode
              Center(
                child: TextButton(
                  key: const Key("toggle-auth-mode"),
                  onPressed: () {
                    ref.read(authProvider.notifier).clearError();
                    setState(() {
                      isRegister = !isRegister;
                    });
                  },
                  child: Text(
                    isRegister ? "Already registered? Sign In" : "New doctor? Create Doctor Account",
                    style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Demo credentials box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Demo doctor login",
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "dr.smith@cure.app · doctor123",
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? icon;

  const _Field({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
            decoration: InputDecoration(
              prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF0F766E)) : null,
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
