import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/citizen_profile.dart';
import '../models/vulnerability_profile.dart';
import '../services/offline_service.dart';
import '../widgets/educational_disclaimer_card.dart';
import '../theme/drishti_theme.dart';
import 'profile_screen.dart';
import 'emergency_reporting_screen.dart';
import 'emergency_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final offlineService = Provider.of<OfflineService>(context);
    final profile = offlineService.vulnerabilityProfile;
    final profileStatus = offlineService.profileStatus;
    final connectivity = offlineService.connectivity;
    final queueCount = offlineService.localQueue.length;

    return Scaffold(
      backgroundColor: DrishtiColors.background,
      appBar: AppBar(
        backgroundColor: DrishtiColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: DrishtiColors.lightBlue,
                shape: BoxShape.circle,
                border: Border.all(color: DrishtiColors.primaryBlue.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: DrishtiColors.primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi, ${offlineService.citizenProfile.fullName.isNotEmpty ? offlineService.citizenProfile.fullName.split(' ').first : 'Citizen'}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: DrishtiColors.darkNavyText,
                  ),
                ),
                const Text(
                  "Stay Safe, Help Others",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: DrishtiColors.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: DrishtiColors.darkNavyText),
            tooltip: "Alerts & Notifications",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No critical regional alerts at this moment."),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: DrishtiColors.primaryBlue),
            tooltip: "Edit Profile",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. DRISHTI Branding Header Banner
            _buildBrandingHeader(),
            const SizedBox(height: 14),

            // 2. Active or Queued Emergency Tracking Card (High Priority)
            if (offlineService.hasActiveEmergency || queueCount > 0) ...[
              _buildActiveEmergencyCard(context, offlineService),
              const SizedBox(height: 14),
            ],

            // 3. 2x2 Hero Action Cards (Mockup Screen 4)
            _buildHeroActionGrid(context),
            const SizedBox(height: 12),

            // 4. View Alerts & Map Banner Card
            _buildAlertsAndMapCard(context),
            const SizedBox(height: 14),

            // 5. T059 — Local Pending & Offline Sync Status Card
            _buildQueueStatusCard(context, offlineService, queueCount, connectivity),
            const SizedBox(height: 14),

            // 6. Prominent Emergency Trigger Card (Preserving existing action & tests)
            _buildEmergencyTriggerCard(context, offlineService),
            const SizedBox(height: 14),

            // 7. Profile Summary Card
            _buildProfileSummaryCard(context, profile, profileStatus, offlineService.citizenProfile),
            const SizedBox(height: 14),

            // 8. Connectivity Simulator Bar
            _buildConnectivitySimulatorCard(context, offlineService, connectivity),
            const SizedBox(height: 14),

            // 9. Educational Disclaimer Notice
            const EducationalDisclaimerCard(compact: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBrandingHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DrishtiColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DrishtiColors.border),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: DrishtiColors.primaryBlue, size: 20),
              SizedBox(width: 8),
              Text(
                "DRISHTI AI",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1.0,
                  color: DrishtiColors.deepNavy,
                ),
              ),
            ],
          ),
          Text(
            "SEE EARLY • RESPOND BETTER",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: DrishtiColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  /// 2x2 Hero Action Grid directly matching Mockup Screen 4
  Widget _buildHeroActionGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                context: context,
                title: "SOS\nEmergency",
                icon: Icons.emergency_rounded,
                bgColor: DrishtiColors.medicalLightRed,
                borderColor: DrishtiColors.emergencyRed,
                accentColor: DrishtiColors.emergencyRed,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EmergencyReportingScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                context: context,
                title: "Request\nHelp",
                icon: Icons.support_agent_rounded,
                bgColor: DrishtiColors.lightBlue,
                borderColor: DrishtiColors.primaryBlue,
                accentColor: DrishtiColors.primaryBlue,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EmergencyReportingScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                context: context,
                title: "Report Missing\nPerson",
                icon: Icons.person_search_rounded,
                bgColor: DrishtiColors.accidentLightPurple,
                borderColor: DrishtiColors.purple,
                accentColor: DrishtiColors.purple,
                onTap: () {
                  _showFeatureModal(
                    context,
                    title: "Report Missing Person",
                    subtitle: "Log unaccounted persons with photo, location, and physical descriptors.",
                    color: DrishtiColors.purple,
                    icon: Icons.person_search_rounded,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                context: context,
                title: "Find Shelter\nNearby",
                icon: Icons.night_shelter_rounded,
                bgColor: DrishtiColors.softGreen,
                borderColor: DrishtiColors.successGreen,
                accentColor: DrishtiColors.successGreen,
                onTap: () {
                  _showFeatureModal(
                    context,
                    title: "Nearby Shelters",
                    subtitle: "View real-time relief shelters, capacity, medical resources, and directions.",
                    color: DrishtiColors.successGreen,
                    icon: Icons.night_shelter_rounded,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 106,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            Text(
              title,
              style: const TextStyle(
                color: DrishtiColors.darkNavyText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsAndMapCard(BuildContext context) {
    return InkWell(
      onTap: () {
        _showFeatureModal(
          context,
          title: "Map & Live Alerts",
          subtitle: "Explore interactive flood inundation zones, response team assignments, and evacuation corridors.",
          color: DrishtiColors.primaryBlue,
          icon: Icons.map_rounded,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: DrishtiColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DrishtiColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DrishtiColors.warningLightYellow,
                shape: BoxShape.circle,
                border: Border.all(color: DrishtiColors.alertYellow.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.map_rounded, color: DrishtiColors.warningOrange, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "View Alerts & Map",
                    style: TextStyle(
                      color: DrishtiColors.darkNavyText,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Real-time hazard perimeter and road blockages",
                    style: TextStyle(color: DrishtiColors.secondaryText, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: DrishtiColors.secondaryText, size: 14),
          ],
        ),
      ),
    );
  }

  /// T059: Local Pending and Offline Sync Status UI
  Widget _buildQueueStatusCard(
    BuildContext context,
    OfflineService service,
    int queueCount,
    ConnectivityState connectivity,
  ) {
    final isOffline = connectivity == ConnectivityState.offline;

    // 1. Offline Mode Experience matching Mockup Screen 7
    if (isOffline) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DrishtiColors.lightBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DrishtiColors.primaryBlue.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi_off_rounded, color: DrishtiColors.emergencyRed, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "You're Offline",
                        style: TextStyle(
                          color: DrishtiColors.darkNavyText,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "No internet connection. Don't worry!",
                        style: TextStyle(
                          color: DrishtiColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DrishtiColors.warningLightYellow,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: DrishtiColors.alertYellow),
                  ),
                  child: Text(
                    "$queueCount Pending",
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DrishtiColors.border),
              ),
              child: Column(
                children: [
                  _buildOfflineCheckRow(
                    Icons.check_circle_rounded,
                    DrishtiColors.successGreen,
                    "Request saved locally",
                  ),
                  const SizedBox(height: 6),
                  _buildOfflineCheckRow(
                    queueCount > 0 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    queueCount > 0 ? DrishtiColors.successGreen : DrishtiColors.secondaryText,
                    "Stored in offline queue ($queueCount Pending)",
                  ),
                  const SizedBox(height: 6),
                  _buildOfflineCheckRow(
                    Icons.sync_rounded,
                    DrishtiColors.primaryBlue,
                    "Will sync automatically when connection returns",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Preserved exact search string for automated tests
            Text(
              "Offline Sync Queue: $queueCount Pending",
              style: const TextStyle(
                color: DrishtiColors.deepNavy,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // 2. Online Mode Queue Card (Pending, Syncing, or Synced)
    final Color stateColor = queueCount > 0
        ? DrishtiColors.alertYellow
        : DrishtiColors.successGreen;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DrishtiColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DrishtiColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: queueCount > 0 ? DrishtiColors.warningLightYellow : DrishtiColors.softGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              queueCount > 0 ? Icons.pending_actions_rounded : Icons.cloud_done_rounded,
              color: stateColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preserved exact string required by tests
                Text(
                  "Offline Sync Queue: $queueCount Pending",
                  style: const TextStyle(
                    color: DrishtiColors.darkNavyText,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  queueCount > 0
                      ? "Emergencies queued offline retain their original vulnerability snapshot."
                      : "All emergency reports are synchronized.",
                  style: const TextStyle(color: DrishtiColors.secondaryText, fontSize: 11),
                ),
                if (service.lastSyncError != null && queueCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: DrishtiColors.medicalLightRed,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: DrishtiColors.emergencyRed.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      "Sync warning: ${service.lastSyncError!}",
                      style: const TextStyle(
                        color: DrishtiColors.emergencyRed,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (queueCount > 0) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DrishtiColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(80, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: connectivity == ConnectivityState.online
                  ? () => service.syncPendingQueue()
                  : null,
              child: const Text("Sync Now", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfflineCheckRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: DrishtiColors.darkNavyText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveEmergencyCard(BuildContext context, OfflineService service) {
    final active = service.activeEmergency ?? (service.localQueue.isNotEmpty ? service.localQueue.first : null);
    if (active == null) return const SizedBox.shrink();

    final emergencyId = active['id'] as String? ?? active['idempotency_key'] as String? ?? 'DR-LOCAL';
    final title = active['title'] as String? ?? 'Emergency Incident';
    final status = (active['status'] as String? ?? 'PENDING').toUpperCase();
    final isLocalPending = status == 'LOCAL_PENDING' || active['sync_status'] == 'PENDING_SYNC';

    Color statusColor;
    Color bgStatusColor;
    switch (status) {
      case 'LOCAL_PENDING':
        statusColor = DrishtiColors.alertYellow;
        bgStatusColor = DrishtiColors.warningLightYellow;
        break;
      case 'ASSIGNED':
        statusColor = DrishtiColors.purple;
        bgStatusColor = DrishtiColors.accidentLightPurple;
        break;
      case 'IN_PROGRESS':
        statusColor = DrishtiColors.primaryBlue;
        bgStatusColor = DrishtiColors.lightBlue;
        break;
      case 'RESOLVED':
        statusColor = DrishtiColors.successGreen;
        bgStatusColor = DrishtiColors.softGreen;
        break;
      default:
        statusColor = DrishtiColors.emergencyRed;
        bgStatusColor = DrishtiColors.medicalLightRed;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DrishtiColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isLocalPending ? Icons.pending_actions_rounded : Icons.radar_rounded,
                    color: statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLocalPending ? "OFFLINE EMERGENCY QUEUED" : "ACTIVE EMERGENCY",
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bgStatusColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: DrishtiColors.darkNavyText,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "ID: $emergencyId",
            style: const TextStyle(color: DrishtiColors.secondaryText, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: const Size(120, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.track_changes_rounded, size: 16),
              label: Text(
                isLocalPending ? "View Local Status" : "Track Response",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EmergencyTrackingScreen(emergencyId: emergencyId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTriggerCard(BuildContext context, OfflineService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DrishtiColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DrishtiColors.emergencyRed.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: DrishtiColors.emergencyRed.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: DrishtiColors.emergencyRed, size: 22),
              SizedBox(width: 8),
              Text(
                "Emergency Assistance",
                style: TextStyle(
                  color: DrishtiColors.darkNavyText,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Sends emergency report with your current vulnerability profile snapshot attached. Operates seamlessly offline or online.",
            style: TextStyle(color: DrishtiColors.secondaryText, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: DrishtiTheme.sosButtonStyle,
            icon: const Icon(Icons.sos_rounded, size: 22),
            label: const Text(
              "REPORT EMERGENCY / SOS",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.8),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EmergencyReportingScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSummaryCard(
    BuildContext context,
    VulnerabilityProfile profile,
    ProfileStatus status, [
    CitizenProfile? citizenProfile,
  ]) {
    Color statusColor = status == ProfileStatus.completed
        ? DrishtiColors.successGreen
        : status == ProfileStatus.defaultProfile
            ? DrishtiColors.alertYellow
            : DrishtiColors.emergencyRed;

    String statusLabel = status == ProfileStatus.completed
        ? "Completed"
        : status == ProfileStatus.defaultProfile
            ? "Default Profile"
            : "Not Completed";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DrishtiColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DrishtiColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (citizenProfile != null && citizenProfile.fullName.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: DrishtiColors.primaryBlue),
                    const SizedBox(width: 6),
                    Text(
                      citizenProfile.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: DrishtiColors.darkNavyText,
                      ),
                    ),
                  ],
                ),
                Text(
                  citizenProfile.phoneNumber,
                  style: const TextStyle(fontSize: 12, color: DrishtiColors.secondaryText),
                ),
              ],
            ),
            if (citizenProfile.city != null && citizenProfile.city!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: DrishtiColors.secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    citizenProfile.city!,
                    style: const TextStyle(fontSize: 11, color: DrishtiColors.secondaryText),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1, color: DrishtiColors.border),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Vulnerability Profile",
                style: TextStyle(
                  color: DrishtiColors.darkNavyText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildTraitBadge("Age: ${profile.age ?? 30} (${profile.ageGroup})"),
              _buildTraitBadge(
                profile.canSwim ? "Can Swim" : "Cannot Swim (High Flood Risk)",
                isAlert: !profile.canSwim,
              ),
              _buildTraitBadge("Mobility: ${profile.mobilityStatus}"),
              if (profile.medicalConditions.isNotEmpty)
                _buildTraitBadge("Conditions: ${profile.medicalConditions.join(', ')}"),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: DrishtiColors.primaryBlue,
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text("Edit Profile Traits", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitBadge(String text, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAlert ? DrishtiColors.medicalLightRed : DrishtiColors.neutralLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAlert ? DrishtiColors.emergencyRed.withValues(alpha: 0.3) : DrishtiColors.border,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isAlert ? DrishtiColors.emergencyRed : DrishtiColors.darkNavyText,
          fontSize: 11,
          fontWeight: isAlert ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildConnectivitySimulatorCard(
    BuildContext context,
    OfflineService service,
    ConnectivityState connectivity,
  ) {
    Color badgeColor;
    String statusText;
    String statusSubtitle;
    IconData statusIcon;

    switch (connectivity) {
      case ConnectivityState.online:
        badgeColor = DrishtiColors.successGreen;
        statusText = "ONLINE";
        statusSubtitle = "Connection available";
        statusIcon = Icons.wifi_rounded;
        break;
      case ConnectivityState.intermittent:
        badgeColor = DrishtiColors.warningOrange;
        statusText = "INTERMITTENT";
        statusSubtitle = "Connection unstable";
        statusIcon = Icons.network_check_rounded;
        break;
      case ConnectivityState.offline:
        badgeColor = DrishtiColors.emergencyRed;
        statusText = "OFFLINE (Local Queue Mode)";
        statusSubtitle = "No network connection";
        statusIcon = Icons.wifi_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DrishtiColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DrishtiColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: badgeColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Network State: $statusText",
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      statusSubtitle,
                      style: const TextStyle(
                        color: DrishtiColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Simulate Network Condition:",
            style: TextStyle(color: DrishtiColors.secondaryText, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildNetworkChip(service, ConnectivityState.online, "Online", Icons.wifi),
              const SizedBox(width: 6),
              _buildNetworkChip(service, ConnectivityState.intermittent, "Intermittent", Icons.network_check),
              const SizedBox(width: 6),
              _buildNetworkChip(service, ConnectivityState.offline, "Offline", Icons.wifi_off),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkChip(
    OfflineService service,
    ConnectivityState state,
    String label,
    IconData icon,
  ) {
    final isSelected = service.connectivity == state;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : DrishtiColors.secondaryText,
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: DrishtiColors.primaryBlue,
      backgroundColor: DrishtiColors.neutralLight,
      side: BorderSide(
        color: isSelected ? DrishtiColors.primaryBlue : DrishtiColors.border,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : DrishtiColors.darkNavyText,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => service.setConnectivity(state),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DrishtiColors.surface,
        border: Border(top: BorderSide(color: DrishtiColors.border, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        elevation: 0,
        backgroundColor: DrishtiColors.surface,
        selectedItemColor: DrishtiColors.primaryBlue,
        unselectedItemColor: DrishtiColors.secondaryText,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        onTap: (index) {
          setState(() => _selectedNavIndex = index);
          if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          } else if (index == 1) {
            _showFeatureModal(
              context,
              title: "Disaster Zones & Shelters Map",
              subtitle: "Live map of active flooding perimeters, shelters, and relief distribution points.",
              color: DrishtiColors.primaryBlue,
              icon: Icons.map_rounded,
            );
          } else if (index == 2) {
            final offlineService = Provider.of<OfflineService>(context, listen: false);
            final active = offlineService.activeEmergency ??
                (offlineService.localQueue.isNotEmpty ? offlineService.localQueue.first : null);
            final emgId = active?['id'] as String? ?? active?['idempotency_key'] as String? ?? '';
            if (emgId.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EmergencyTrackingScreen(emergencyId: emgId)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No incident reports to display. Report an emergency to begin tracking."),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showFeatureModal(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DrishtiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: DrishtiColors.darkNavyText,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "DRISHTI Community Network",
                        style: TextStyle(color: DrishtiColors.secondaryText, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              subtitle,
              style: const TextStyle(color: DrishtiColors.darkNavyText, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }
}
