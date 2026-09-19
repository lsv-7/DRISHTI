import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/citizen_profile.dart';
import '../models/vulnerability_profile.dart';
import '../services/offline_service.dart';
import '../theme/drishti_theme.dart';
import '../widgets/educational_disclaimer_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Citizen Identity Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _emergencyContactNameController;
  late TextEditingController _emergencyContactPhoneController;
  String? _gender;

  // Vulnerability Profile State
  late int _age;
  late bool _canSwim;
  late String _mobilityStatus;
  late List<String> _selectedConditions;
  late TextEditingController _notesController;
  bool _isSaving = false;

  final List<String> _availableConditions = [
    'Asthma / Respiratory',
    'Diabetes',
    'Hypertension',
    'Cardiac Condition',
    'Dialysis Dependent',
    'Pregnancy',
  ];

  @override
  void initState() {
    super.initState();
    final offlineService = Provider.of<OfflineService>(context, listen: false);
    final citizen = offlineService.citizenProfile;
    final vuln = offlineService.vulnerabilityProfile;

    _fullNameController = TextEditingController(text: citizen.fullName);
    _phoneController = TextEditingController(text: citizen.phoneNumber);
    _emailController = TextEditingController(text: citizen.email ?? '');
    _addressController = TextEditingController(text: citizen.address ?? '');
    _cityController = TextEditingController(text: citizen.city ?? 'Vijayawada');
    _emergencyContactNameController = TextEditingController(text: citizen.emergencyContactName ?? '');
    _emergencyContactPhoneController = TextEditingController(text: citizen.emergencyContactPhone ?? '');
    _gender = citizen.gender;

    _age = vuln.age ?? citizen.age ?? 30;
    _canSwim = vuln.canSwim;
    _mobilityStatus = vuln.mobilityStatus;
    _selectedConditions = List<String>.from(vuln.medicalConditions);
    _notesController = TextEditingController(text: vuln.disabilityNotes ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);
    final offlineService = Provider.of<OfflineService>(context, listen: false);

    final updatedCitizen = CitizenProfile(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      age: _age,
      gender: _gender,
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      emergencyContactName: _emergencyContactNameController.text.trim().isEmpty
          ? null
          : _emergencyContactNameController.text.trim(),
      emergencyContactPhone: _emergencyContactPhoneController.text.trim().isEmpty
          ? null
          : _emergencyContactPhoneController.text.trim(),
      status: CitizenProfileStatus.complete,
    );

    final updatedVuln = VulnerabilityProfile(
      age: _age,
      ageGroup: VulnerabilityProfile.deriveAgeGroup(_age),
      canSwim: _canSwim,
      mobilityStatus: _mobilityStatus,
      medicalConditions: _selectedConditions,
      disabilityNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      status: ProfileStatus.completed,
    );

    await offlineService.saveCitizenProfile(updatedCitizen);
    await offlineService.saveVulnerabilityProfile(updatedVuln);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: DrishtiColors.successGreen,
          content: Text("Profile details updated successfully. Applied to future emergency reports."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final derivedGroup = VulnerabilityProfile.deriveAgeGroup(_age);

    return Scaffold(
      backgroundColor: DrishtiColors.background,
      appBar: AppBar(
        backgroundColor: DrishtiColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: DrishtiColors.darkNavyText),
        title: const Text(
          "My Citizen Profile",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DrishtiColors.darkNavyText),
        ),
        shape: const Border(
          bottom: BorderSide(color: DrishtiColors.border, width: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Basic Information
              _buildSectionHeader("Basic Information", Icons.badge_outlined),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: "Full Name *",
                  prefixIcon: Icon(Icons.person_outline, color: DrishtiColors.primaryBlue),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Full name is required.";
                  if (val.trim().length < 2) return "Full name must be at least 2 characters.";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number *",
                  prefixIcon: Icon(Icons.phone_outlined, color: DrishtiColors.primaryBlue),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Phone number is required.";
                  final clean = val.trim().replaceAll(RegExp(r'[\s\-]'), '');
                  if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(clean)) {
                    return "Enter a valid phone number (8-15 digits).";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: Icon(Icons.email_outlined, color: DrishtiColors.secondaryText),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(val.trim())) {
                      return "Enter a valid email address.";
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section 2: Personal & Location Details
              _buildSectionHeader("Location & Personal Details", Icons.location_on_outlined),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: "City",
                        prefixIcon: Icon(Icons.location_city, color: DrishtiColors.secondaryText),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: "Gender",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: "MALE", child: Text("Male")),
                        DropdownMenuItem(value: "FEMALE", child: Text("Female")),
                        DropdownMenuItem(value: "OTHER", child: Text("Other")),
                        DropdownMenuItem(value: "PREFER_NOT_TO_SAY", child: Text("Undisclosed")),
                      ],
                      onChanged: (val) => setState(() => _gender = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "Address / Locality",
                  prefixIcon: Icon(Icons.home_outlined, color: DrishtiColors.secondaryText),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Section 3: Emergency Contact
              _buildSectionHeader("Emergency Contact", Icons.contact_emergency_outlined),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergencyContactNameController,
                decoration: const InputDecoration(
                  labelText: "Contact Person Name",
                  hintText: "e.g. Family member, neighbor",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergencyContactPhoneController,
                decoration: const InputDecoration(
                  labelText: "Contact Person Phone",
                  hintText: "e.g. 9876543211",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final clean = val.trim().replaceAll(RegExp(r'[\s\-]'), '');
                    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(clean)) {
                      return "Enter a valid emergency contact phone.";
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Section 4: Vulnerability Profile (Kept Strictly Separate)
              _buildSectionHeader("Vulnerability Profile", Icons.shield_outlined),
              const SizedBox(height: 8),
              const Text(
                "Vulnerability indicators are used strictly as operational priority heuristics for emergency dispatch, never for identity or medical triage.",
                style: TextStyle(fontSize: 12, color: DrishtiColors.secondaryText),
              ),
              const SizedBox(height: 12),
              const EducationalDisclaimerCard(),
              const SizedBox(height: 16),

              // Age Slider
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DrishtiColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DrishtiColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Age", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("$_age yrs ($derivedGroup)", style: const TextStyle(color: DrishtiColors.deepNavy, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: _age.toDouble(),
                      min: 1,
                      max: 100,
                      divisions: 99,
                      activeColor: DrishtiColors.primaryBlue,
                      onChanged: (val) => setState(() => _age = val.round()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Swimming Ability
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DrishtiColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DrishtiColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Swimming Ability", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text("Can Swim"),
                            selected: _canSwim,
                            selectedColor: DrishtiColors.lightBlue,
                            onSelected: (val) => setState(() => _canSwim = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text("Cannot Swim"),
                            selected: !_canSwim,
                            selectedColor: const Color(0xFFFFEDD5),
                            onSelected: (val) => setState(() => _canSwim = false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mobility Level
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DrishtiColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DrishtiColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Mobility Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['FULL', 'LIMITED', 'WHEELCHAIR', 'BEDRIDDEN'].map((status) {
                        final selected = _mobilityStatus == status;
                        return ChoiceChip(
                          label: Text(status),
                          selected: selected,
                          selectedColor: DrishtiColors.lightBlue,
                          onSelected: (val) => setState(() => _mobilityStatus = status),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Medical Conditions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DrishtiColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DrishtiColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Pre-existing Medical Conditions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableConditions.map((condition) {
                        final isSelected = _selectedConditions.contains(condition);
                        return FilterChip(
                          label: Text(condition),
                          selected: isSelected,
                          selectedColor: DrishtiColors.lightBlue,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedConditions.add(condition);
                              } else {
                                _selectedConditions.remove(condition);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Disability Notes
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: "Disability / Care Notes",
                  hintText: "Optional details for dispatchers",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 28),

              // Save button
              ElevatedButton(
                onPressed: _isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DrishtiColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        "Save Profile Changes",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: DrishtiColors.primaryBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: DrishtiColors.darkNavyText,
          ),
        ),
      ],
    );
  }
}
