import 'package:flutter/material.dart';

class StatusMeta {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;

  const StatusMeta({
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });

  static const Map<String, StatusMeta> map = {
    'available': StatusMeta(
      label: 'Available',
      color: Color(0xFF065F46),
      bg: Color(0xFFD1FAE5),
      icon: Icons.check_circle_outline,
    ),
    'running_late': StatusMeta(
      label: 'Running Late',
      color: Color(0xFF92400E),
      bg: Color(0xFFFEF3C7),
      icon: Icons.access_time,
    ),
    'in_surgery': StatusMeta(
      label: 'In Surgery',
      color: Color(0xFF1E3A8A),
      bg: Color(0xFFDBEAFE),
      icon: Icons.medical_services_outlined,
    ),
    'emergency': StatusMeta(
      label: 'Emergency Case',
      color: Color(0xFF991B1B),
      bg: Color(0xFFFEE2E2),
      icon: Icons.warning_amber_rounded,
    ),
    'closed': StatusMeta(
      label: 'Clinic Closed',
      color: Color(0xFF374151),
      bg: Color(0xFFE5E7EB),
      icon: Icons.lock_outline,
    ),
  };

  static StatusMeta get(String? status) {
    return map[status] ?? map['available']!;
  }
}
