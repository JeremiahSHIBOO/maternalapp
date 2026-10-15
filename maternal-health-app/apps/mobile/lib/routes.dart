import 'package:flutter/material.dart';
import 'screens/start_screen.dart';
import 'screens/login_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/mother_home_screen.dart';
import 'screens/partner_home_screen.dart';
import 'screens/doctor_portal_screen.dart';

class AppRoutes {
  static const String start = '/';
  static const String login = '/login';
  static const String roleSelection = '/role-selection';
  static const String motherHome = '/mother-home';
  static const String partnerHome = '/partner-home';
  static const String doctorPortal = '/doctor-portal';
  static const String patientDetails = '/patient-details';

  static Route<dynamic>? onGenerate(RouteSettings settings) {
    switch (settings.name) {
      case start:
        return MaterialPageRoute(builder: (_) => const StartScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      case motherHome:
        return MaterialPageRoute(builder: (_) => const MotherHomeScreen());
      case partnerHome:
        return MaterialPageRoute(builder: (_) => const PartnerHomeScreen());
      case doctorPortal:
        return MaterialPageRoute(builder: (_) => const DoctorPortalScreen());
      case patientDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PatientDetailsScreen(
            patient: args ?? {},
          ),
        );
      default:
        return null;
    }
  }
}

class PatientDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDetailsScreen({required this.patient, super.key});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;
    return MaterialPageRoute(
      builder: (_) => PatientDetailsScreen(patient: args ?? {}),
    );
  }
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    return Scaffold(
      appBar: AppBar(
        title: Text(patient['name'] ?? 'Patient Details'),
        backgroundColor: const Color(0xFF880E4F),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${patient['name'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Age: ${patient['age'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestational Age: ${patient['gestationalAge'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${patient['status'] ?? 'Unknown'}',
              style: TextStyle(
                color: patient['status'] == 'high-risk'
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Patients'),
            ),
          ],
        ),
      ),
    );
  }
}