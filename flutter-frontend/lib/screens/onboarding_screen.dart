import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final _formKey = GlobalKey<FormState>();
  
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
    _notesController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final offlineService = Provider.of<OfflineService>(context, listen: false);
    
    final profile = VulnerabilityProfile(
      age: _age,
      ageGroup: VulnerabilityProfile.deriveAgeGroup(_age),
      canSwim: _canSwim,
      mobilityStatus: _mobilityStatus,
      medicalConditions: _selectedConditions,
      disabilityNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      status: ProfileStatus.completed,
    );

    await offlineService.saveVulnerabilityProfile(profile);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _skipOnboarding() async {
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
    final derivedGroup = VulnerabilityProfile.deriveAgeGroup(_age);

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DrishtiColors.lightBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: DrishtiColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Vulnerability Profile",
                            style: TextStyle(
                              color: DrishtiColors.darkNavyText,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "One-time setup for priority disaster assistance",
                            style: TextStyle(
                              color: DrishtiColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Mandatory Educational Notice (RULES.md Rule 12, 16)
                const EducationalDisclaimerCard(),
                const SizedBox(height: 24),

                // 1. Age Field
                _buildSectionHeader(
                  icon: Icons.cake_outlined,
                  title: "Age & Category",
                  subtitle: "Elderly and children receive specific priority consideration",
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: DrishtiColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DrishtiColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Age: $_age years",
                        style: const TextStyle(color: DrishtiColors.darkNavyText, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: derivedGroup == 'ELDERLY'
                              ? DrishtiColors.medicalLightRed
                              : derivedGroup == 'CHILD'
                                  ? DrishtiColors.fireLightOrange
                                  : DrishtiColors.lightBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          derivedGroup,
                          style: TextStyle(
                            color: derivedGroup == 'ELDERLY'
                                ? DrishtiColors.emergencyRed
                                : derivedGroup == 'CHILD'
                                    ? DrishtiColors.warningOrange
                                    : DrishtiColors.primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: DrishtiColors.secondaryText),
                        onPressed: _age > 1 ? () => setState(() => _age--) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: DrishtiColors.primaryBlue),
                        onPressed: _age < 110 ? () => setState(() => _age++) : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Swimming Ability
                _buildSectionHeader(
                  icon: Icons.waves_outlined,
                  title: "Swimming Ability",
                  subtitle: "Crucial for flood rescue boats and water evacuation",
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectableCard(
                        label: "Can Swim",
                        selected: _canSwim,
                        icon: Icons.pool_outlined,
                        onTap: () => setState(() => _canSwim = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSelectableCard(
                        label: "Cannot Swim",
                        badge: "High Flood Risk",
                        selected: !_canSwim,
                        icon: Icons.not_interested_outlined,
                        color: DrishtiColors.emergencyRed,
                        onTap: () => setState(() => _canSwim = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Mobility Status
                _buildSectionHeader(
                  icon: Icons.accessible_outlined,
                  title: "Mobility Status",
                  subtitle: "Ensures vehicle & stretcher dispatch compatibility",
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMobilityChip("FULL", "Full Mobility", Icons.directions_walk),
                    _buildMobilityChip("LIMITED", "Limited Mobility", Icons.nordic_walking),
                    _buildMobilityChip("WHEELCHAIR", "Wheelchair User", Icons.accessible_forward),
                    _buildMobilityChip("BEDRIDDEN", "Bedridden / Immobile", Icons.airline_seat_flat),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. Medical Conditions
                _buildSectionHeader(
                  icon: Icons.medical_services_outlined,
                  title: "Pre-existing Medical Conditions",
                  subtitle: "Select conditions that require critical medical supplies or power",
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
                      checkmarkColor: DrishtiColors.primaryBlue,
                      backgroundColor: DrishtiColors.surface,
                      side: BorderSide(
                        color: isSelected ? DrishtiColors.primaryBlue : DrishtiColors.border,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? DrishtiColors.primaryBlue : DrishtiColors.darkNavyText,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedConditions.add(condition);
                          } else {
                            _selectedConditions.remove(condition);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 5. Disability & Assistance Notes
                _buildSectionHeader(
                  icon: Icons.edit_note_outlined,
                  title: "Disability & Assistance Notes",
                  subtitle: "Optional respectful notes for relief workers",
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(color: DrishtiColors.darkNavyText, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "e.g., Uses hearing aid, requires oxygen concentrator, diabetic insulin...",
                    hintStyle: const TextStyle(color: DrishtiColors.secondaryText, fontSize: 12),
                    filled: true,
                    fillColor: DrishtiColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: DrishtiColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: DrishtiColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: DrishtiColors.primaryBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Primary Save Button
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DrishtiColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  child: const Text(
                    "SAVE VULNERABILITY PROFILE",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 12),

                // Skip / Default Button
                OutlinedButton(
                  onPressed: _skipOnboarding,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DrishtiColors.secondaryText,
                    side: const BorderSide(color: DrishtiColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    "Skip for Now (Use Default Profile)",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: DrishtiColors.primaryBlue),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: DrishtiColors.darkNavyText,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: DrishtiColors.secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableCard({
    required String label,
    required bool selected,
    required IconData icon,
    required VoidCallback onTap,
    String? badge,
    Color? color,
  }) {
    final activeColor = color ?? DrishtiColors.primaryBlue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.12) : DrishtiColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? activeColor : DrishtiColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? activeColor : DrishtiColors.secondaryText, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? activeColor : DrishtiColors.darkNavyText,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (badge != null && selected) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobilityChip(String value, String label, IconData icon) {
    final isSelected = _mobilityStatus == value;
    final color = value == 'BEDRIDDEN' || value == 'WHEELCHAIR'
        ? DrishtiColors.emergencyRed
        : DrishtiColors.primaryBlue;

    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? color : DrishtiColors.secondaryText),
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.15),
      backgroundColor: DrishtiColors.surface,
      side: BorderSide(
        color: isSelected ? color : DrishtiColors.border,
      ),
      labelStyle: TextStyle(
        color: isSelected ? color : DrishtiColors.darkNavyText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _mobilityStatus = value),
    );
  }
}
