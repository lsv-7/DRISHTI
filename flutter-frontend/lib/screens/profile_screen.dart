import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vulnerability_profile.dart';
import '../services/offline_service.dart';
import '../widgets/educational_disclaimer_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    final profile = Provider.of<OfflineService>(context, listen: false).vulnerabilityProfile;
    _age = profile.age ?? 30;
    _canSwim = profile.canSwim;
    _mobilityStatus = profile.mobilityStatus;
    _selectedConditions = List<String>.from(profile.medicalConditions);
    _notesController = TextEditingController(text: profile.disabilityNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    setState(() => _isSaving = true);
    final offlineService = Provider.of<OfflineService>(context, listen: false);

    final updatedProfile = VulnerabilityProfile(
      age: _age,
      ageGroup: VulnerabilityProfile.deriveAgeGroup(_age),
      canSwim: _canSwim,
      mobilityStatus: _mobilityStatus,
      medicalConditions: _selectedConditions,
      disabilityNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      status: ProfileStatus.completed,
    );

    await offlineService.saveVulnerabilityProfile(updatedProfile);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981), // Emerald Green
          content: Text("Vulnerability profile updated. Applied to future emergency dispatches."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final offlineService = Provider.of<OfflineService>(context);
    final currentStatus = offlineService.profileStatus;
    final derivedGroup = VulnerabilityProfile.deriveAgeGroup(_age);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "My Vulnerability Profile",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            _buildStatusHeader(currentStatus),
            const SizedBox(height: 16),

            // Why this information is collected
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.help_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Why this information is collected: During flood or crisis response, command centers match specialized rescue resources (medical boat teams, wheelchair vans, high-priority dispatch) based on your individual mobility and health requirements.",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Heuristic Disclaimer
            const EducationalDisclaimerCard(compact: true),
            const SizedBox(height: 20),

            // Historical Immutability Reminder
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.history_toggle_off_rounded, color: Color(0xFF64748B), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Note: Updates apply to future emergency reports. Past emergency records retain their original historical snapshots.",
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Age & Category
            _buildSectionLabel("Age & Category"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Text(
                    "$_age years",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      derivedGroup,
                      style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF94A3B8)),
                    onPressed: _age > 1 ? () => setState(() => _age--) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF60A5FA)),
                    onPressed: _age < 110 ? () => setState(() => _age++) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Swimming Ability
            _buildSectionLabel("Swimming Ability (Flood Evacuation)"),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceButton(
                    label: "Can Swim",
                    selected: _canSwim,
                    icon: Icons.pool_outlined,
                    onTap: () => setState(() => _canSwim = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildChoiceButton(
                    label: "Cannot Swim",
                    selected: !_canSwim,
                    icon: Icons.not_interested_outlined,
                    color: const Color(0xFFEF4444),
                    onTap: () => setState(() => _canSwim = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Mobility Status
            _buildSectionLabel("Mobility Status"),
            const SizedBox(height: 8),
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
            const SizedBox(height: 18),

            // Medical Conditions
            _buildSectionLabel("Pre-existing Medical Conditions"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableConditions.map((condition) {
                final isSelected = _selectedConditions.contains(condition);
                return FilterChip(
                  label: Text(condition),
                  selected: isSelected,
                  selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  checkmarkColor: const Color(0xFF60A5FA),
                  backgroundColor: const Color(0xFF1E293B),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 12,
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
            const SizedBox(height: 18),

            // Disability Notes
            _buildSectionLabel("Disability & Specific Assistance Notes"),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: "e.g., Uses walking cane, requires continuous dialysis, etc.",
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Save Changes Button
            ElevatedButton(
              onPressed: _isSaving ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      "SAVE PROFILE CHANGES",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(ProfileStatus status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case ProfileStatus.completed:
        statusColor = const Color(0xFF10B981);
        statusText = "Completed";
        statusIcon = Icons.check_circle_outline;
        break;
      case ProfileStatus.defaultProfile:
        statusColor = const Color(0xFFF59E0B);
        statusText = "Default Profile (Onboarding Skipped)";
        statusIcon = Icons.info_outline;
        break;
      case ProfileStatus.notCompleted:
        statusColor = const Color(0xFFEF4444);
        statusText = "Not Completed";
        statusIcon = Icons.warning_amber_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Profile State", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFF1F5F9),
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  Widget _buildChoiceButton({
    required String label,
    required bool selected,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? const Color(0xFF3B82F6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.15) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? activeColor : const Color(0xFF334155),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? activeColor : const Color(0xFF94A3B8), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF94A3B8),
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilityChip(String value, String label, IconData icon) {
    final isSelected = _mobilityStatus == value;
    final color = value == 'BEDRIDDEN' || value == 'WHEELCHAIR'
        ? const Color(0xFFEF4444)
        : const Color(0xFF3B82F6);

    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.25),
      backgroundColor: const Color(0xFF1E293B),
      side: BorderSide(color: isSelected ? color : const Color(0xFF334155)),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _mobilityStatus = value),
    );
  }
}
