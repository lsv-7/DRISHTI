import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vulnerability_profile.dart';
import '../services/offline_service.dart';
import '../widgets/educational_disclaimer_card.dart';
import 'profile_screen.dart';
import 'emergency_reporting_screen.dart';
import 'emergency_tracking_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final offlineService = Provider.of<OfflineService>(context);
    final profile = offlineService.vulnerabilityProfile;
    final profileStatus = offlineService.profileStatus;
    final connectivity = offlineService.connectivity;
    final queueCount = offlineService.localQueue.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "DRISHTI AI",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: 1.2,
                color: Color(0xFFF8FAFC),
              ),
            ),
            Text(
              "SEE EARLY • RESPOND BETTER • SAFER TOMORROW",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFF60A5FA)),
            tooltip: "Edit Profile",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connectivity Banner & Network Simulator Bar
            _buildConnectivityCard(context, offlineService, connectivity),
            const SizedBox(height: 14),

            // Profile Summary Card
            _buildProfileSummaryCard(context, profile, profileStatus),
            const SizedBox(height: 16),

            // Active or Pending Emergency Tracking Card
            if (offlineService.hasActiveEmergency || queueCount > 0) ...[
              _buildActiveEmergencyCard(context, offlineService),
              const SizedBox(height: 16),
            ],

            // Prominent SOS / Emergency Section
            _buildEmergencyTriggerCard(context, offlineService),
            const SizedBox(height: 16),

            // Offline Queue & Sync Status
            _buildQueueStatusCard(context, offlineService, queueCount, connectivity),
            const SizedBox(height: 16),

            // Educational Heuristics Notice
            const EducationalDisclaimerCard(compact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectivityCard(
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
        badgeColor = const Color(0xFF10B981);
        statusText = "ONLINE";
        statusSubtitle = "Connection available";
        statusIcon = Icons.wifi_rounded;
        break;
      case ConnectivityState.intermittent:
        badgeColor = const Color(0xFFF59E0B);
        statusText = "INTERMITTENT";
        statusSubtitle = "Connection unstable";
        statusIcon = Icons.network_check_rounded;
        break;
      case ConnectivityState.offline:
        badgeColor = const Color(0xFFEF4444);
        statusText = "OFFLINE (Local Queue Mode)";
        statusSubtitle = "No network connection";
        statusIcon = Icons.wifi_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
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
                        color: Color(0xFF94A3B8),
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
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
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
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
      backgroundColor: const Color(0xFF0F172A),
      side: BorderSide(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155)),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
        fontSize: 11,
      ),
      onSelected: (_) => service.setConnectivity(state),
    );
  }

  Widget _buildProfileSummaryCard(
    BuildContext context,
    VulnerabilityProfile profile,
    ProfileStatus status,
  ) {
    Color statusColor = status == ProfileStatus.completed
        ? const Color(0xFF10B981)
        : status == ProfileStatus.defaultProfile
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    String statusLabel = status == ProfileStatus.completed
        ? "Completed"
        : status == ProfileStatus.defaultProfile
            ? "Default Profile"
            : "Not Completed";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Vulnerability Profile",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
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
              _buildTraitBadge(profile.canSwim ? "Can Swim" : "Cannot Swim (High Flood Risk)",
                  isAlert: !profile.canSwim),
              _buildTraitBadge("Mobility: ${profile.mobilityStatus}"),
              if (profile.medicalConditions.isNotEmpty)
                _buildTraitBadge("Conditions: ${profile.medicalConditions.join(', ')}"),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF60A5FA),
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text("Edit Profile Traits", style: TextStyle(fontSize: 12)),
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
        color: isAlert ? const Color(0xFFEF4444).withValues(alpha: 0.2) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAlert ? const Color(0xFFEF4444).withValues(alpha: 0.4) : const Color(0xFF334155),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isAlert ? const Color(0xFFF87171) : const Color(0xFFCBD5E1),
          fontSize: 11,
        ),
      ),
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
    switch (status) {
      case 'LOCAL_PENDING':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'ASSIGNED':
        statusColor = const Color(0xFF8B5CF6);
        break;
      case 'IN_PROGRESS':
        statusColor = const Color(0xFF06B6D4);
        break;
      case 'RESOLVED':
        statusColor = const Color(0xFF10B981);
        break;
      default:
        statusColor = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.6), width: 1.5),
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
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            "ID: $emergencyId",
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
              SizedBox(width: 8),
              Text(
                "Emergency Assistance",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Sends emergency report with your current vulnerability profile snapshot attached. Operates seamlessly offline or online.",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
            ),
            icon: const Icon(Icons.sos_rounded, size: 24),
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

  Widget _buildQueueStatusCard(
    BuildContext context,
    OfflineService service,
    int queueCount,
    ConnectivityState connectivity,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Icon(
            queueCount > 0 ? Icons.pending_actions_rounded : Icons.cloud_done_outlined,
            color: queueCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Offline Sync Queue: $queueCount Pending",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  queueCount > 0
                      ? "Emergencies queued offline retain their original vulnerability snapshot."
                      : "All emergency reports are synchronized.",
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
                if (service.lastSyncError != null && queueCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Sync warning: ${service.lastSyncError!}",
                    style: const TextStyle(color: Color(0xFFF87171), fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          if (queueCount > 0)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: connectivity == ConnectivityState.online
                  ? () => service.syncPendingQueue()
                  : null,
              child: const Text("Sync Now", style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
