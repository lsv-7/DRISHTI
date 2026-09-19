import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/citizen_profile.dart';
import '../models/vulnerability_profile.dart';
import '../services/offline_service.dart';
import '../theme/drishti_theme.dart';
import '../widgets/educational_disclaimer_card.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  int _currentStep = 0; // 0 = Basic Citizen Details, 1 = Vulnerability Profile

  // Step 1: Citizen Details Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController(text: 'Vijayawada');
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactPhoneController = TextEditingController();
  String? _gender;

  // Step 2: Vulnerability Profile State
  int _age = 30;
  bool _canSwim = true;
  String _mobilityStatus = 'FULL';
  final List<String> _selectedConditions = [];
  final TextEditingController _notesController = TextEditingController();

  final List<String> _availableConditions = [
    'Asthma / Respiratory',
    'Diabetes',
    'Hypertension',
    'Cardiac Condition',
    'Dialysis Dependent',
    'Pregnancy',
  ];

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

  void _proceedToStep2() {
    if (_step1FormKey.currentState?.validate() ?? false) {
      setState(() {
        _currentStep = 1;
      });
    }
  }

  CitizenProfile _buildCitizenProfile() {
    return CitizenProfile(
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
  }

  void _saveProfile() async {
    final offlineService = Provider.of<OfflineService>(context, listen: false);

    final citizenProfile = _buildCitizenProfile();
    final vulnerabilityProfile = VulnerabilityProfile(
      age: _age,
      ageGroup: VulnerabilityProfile.deriveAgeGroup(_age),
      canSwim: _canSwim,
      mobilityStatus: _mobilityStatus,
      medicalConditions: _selectedConditions,
      disabilityNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      status: ProfileStatus.completed,
    );

    await offlineService.saveCitizenProfile(citizenProfile);
    await offlineService.saveVulnerabilityProfile(vulnerabilityProfile);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _skipVulnerabilityProfile() async {
    final offlineService = Provider.of<OfflineService>(context, listen: false);

    // Save valid basic citizen profile
    final citizenProfile = _buildCitizenProfile();
    await offlineService.saveCitizenProfile(citizenProfile);

    // Assign standard default vulnerability profile
    await offlineService.skipOnboarding();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _skipAllOnboarding() async {
    final offlineService = Provider.of<OfflineService>(context, listen: false);
    await offlineService.skipOnboarding();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DrishtiColors.background,
      appBar: AppBar(
        backgroundColor: DrishtiColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              "DRISHTI AI",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 1.2,
                color: DrishtiColors.deepNavy,
              ),
            ),
            Text(
              "SEE EARLY • RESPOND BETTER • SAFER TOMORROW",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
                color: DrishtiColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 20),
              if (_currentStep == 0) _buildStep1BasicDetails() else _buildStep2VulnerabilityDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: DrishtiColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DrishtiColors.border),
      ),
      child: Row(
        children: [
          _buildStepCircle(0, "1", "Citizen Details"),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 1 ? DrishtiColors.primaryBlue : DrishtiColors.border,
            ),
          ),
          _buildStepCircle(1, "2", "Vulnerability Profile"),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepIndex, String number, String label) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? DrishtiColors.successGreen
                : isActive
                    ? DrishtiColors.primaryBlue
                    : DrishtiColors.lightBlue,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  number,
                  style: TextStyle(
                    color: isActive ? Colors.white : DrishtiColors.darkNavyText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? DrishtiColors.darkNavyText : DrishtiColors.secondaryText,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 1: Basic Citizen Details
  // ===========================================================================
  Widget _buildStep1BasicDetails() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, color: DrishtiColors.primaryBlue, size: 24),
              SizedBox(width: 8),
              Text(
                "Step 1: Citizen Identification",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DrishtiColors.darkNavyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Essential for identification, emergency communication, and responder coordination.",
            style: TextStyle(fontSize: 12, color: DrishtiColors.secondaryText),
          ),
          const SizedBox(height: 20),

          // Full Name
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: "Full Name *",
              hintText: "Enter your full name",
              prefixIcon: Icon(Icons.badge_outlined, color: DrishtiColors.primaryBlue),
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return "Full name is required.";
              }
              if (val.trim().length < 2) {
                return "Full name must be at least 2 characters.";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone Number
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: "Phone Number *",
              hintText: "e.g. 9876543210",
              prefixIcon: Icon(Icons.phone_outlined, color: DrishtiColors.primaryBlue),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return "Phone number is required.";
              }
              final clean = val.trim().replaceAll(RegExp(r'[\s\-]'), '');
              if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(clean)) {
                return "Enter a valid phone number (8-15 digits).";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: "Email Address (Optional)",
              hintText: "e.g. citizen@example.com",
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
          const SizedBox(height: 16),

          // City and Address
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: "City / District",
                    prefixIcon: Icon(Icons.location_city_outlined, color: DrishtiColors.secondaryText),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: "Residential / Locality Address (Optional)",
              hintText: "Street, Ward, Landmark",
              prefixIcon: Icon(Icons.home_outlined, color: DrishtiColors.secondaryText),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Emergency Contact Sub-section
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
                const Row(
                  children: [
                    Icon(Icons.contact_emergency_outlined, color: DrishtiColors.warningOrange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Emergency Contact (Optional)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: DrishtiColors.darkNavyText,
                      ),
                    ),
                  ],
                ),
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
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action: Continue to Step 2
          ElevatedButton(
            onPressed: _proceedToStep2,
            style: ElevatedButton.styleFrom(
              backgroundColor: DrishtiColors.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Continue to Vulnerability Setup",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Skip onboarding shortcut
          TextButton(
            onPressed: _skipAllOnboarding,
            child: const Text(
              "Skip setup for now (Use Default Citizen Profile)",
              style: TextStyle(color: DrishtiColors.secondaryText, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 2: Vulnerability Profile Setup
  // ===========================================================================
  Widget _buildStep2VulnerabilityDetails() {
    final derivedGroup = VulnerabilityProfile.deriveAgeGroup(_age);

    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: DrishtiColors.primaryBlue),
                onPressed: () => setState(() => _currentStep = 0),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Step 2: Vulnerability Profile",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DrishtiColors.darkNavyText,
                      ),
                    ),
                    Text(
                      "Operational priority heuristics for disaster dispatch",
                      style: TextStyle(fontSize: 12, color: DrishtiColors.secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mandatory Educational Disclaimer
          const EducationalDisclaimerCard(),
          const SizedBox(height: 20),

          // Age & Age Group
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
                    const Text(
                      "Age",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DrishtiColors.darkNavyText),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: derivedGroup == 'ELDERLY' || derivedGroup == 'CHILD'
                            ? DrishtiColors.lightBlue
                            : DrishtiColors.border,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "$_age yrs ($derivedGroup)",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: DrishtiColors.deepNavy, fontSize: 12),
                      ),
                    ),
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

          // Swimming Capability
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
                const Text(
                  "Swimming Ability (Critical in Flood Zones)",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DrishtiColors.darkNavyText),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pool, size: 16),
                            SizedBox(width: 6),
                            Text("Can Swim"),
                          ],
                        ),
                        selected: _canSwim,
                        selectedColor: DrishtiColors.lightBlue,
                        onSelected: (val) => setState(() => _canSwim = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16),
                            SizedBox(width: 6),
                            Text("Cannot Swim"),
                          ],
                        ),
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

          // Mobility Status
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
                const Text(
                  "Mobility Level",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DrishtiColors.darkNavyText),
                ),
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
                const Text(
                  "Pre-existing Medical Conditions",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DrishtiColors.darkNavyText),
                ),
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
              labelText: "Additional Disability / Medical Notes (Optional)",
              hintText: "e.g. Uses hearing aid, requires continuous oxygen",
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Submit button
          ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: DrishtiColors.successGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Save & Complete Setup",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Skip vulnerability button
          OutlinedButton(
            onPressed: _skipVulnerabilityProfile,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: DrishtiColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              "Skip Vulnerability Info (Save Basic Details Only)",
              style: TextStyle(color: DrishtiColors.darkNavyText, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
