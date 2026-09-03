import 'package:flutter/material.dart';
import '../../config/theme.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Schedule",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          "Schedule",
          style: TextStyle(
            fontSize: 16,
            color: AppColors.muted,
          ),
        ),
      ),
    );
  }
}
