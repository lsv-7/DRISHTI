import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/emergency_tracking.dart';
import '../services/offline_service.dart';
import 'home_screen.dart';

class EmergencyTrackingScreen extends StatefulWidget {
  final String emergencyId;
  final EmergencyTracking? initialData;

  const EmergencyTrackingScreen({
    super.key,
    required this.emergencyId,
    this.initialData,
  });

  @override
  State<EmergencyTrackingScreen> createState() => _EmergencyTrackingScreenState();
}

class _EmergencyTrackingScreenState extends State<EmergencyTrackingScreen> {
  EmergencyTracking? _tracking;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tracking = widget.initialData;
    _fetchTracking();
  }

  Future<void> _fetchTracking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final offlineService = Provider.of<OfflineService>(context, listen: false);

    try {
      final result = await offlineService.fetchEmergencyTracking(widget.emergencyId);
      if (mounted) {
        setState(() {
          _tracking = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          final errStr = e.toString();
          if (errStr.contains("not found")) {
            _errorMessage = "Emergency report not found on server.";
          } else if (errStr.contains("offline")) {
            _errorMessage = "Device is offline. Showing locally available status.";
          } else {
            _errorMessage = "Unable to refresh emergency status: Network error.";
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final offlineService = Provider.of<OfflineService>(context);
    final isOffline = offlineService.connectivity == ConnectivityState.offline;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              "DRISHTI EMERGENCY TRACKING",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.8, color: Colors.white),
            ),
            Text(
              "REAL-TIME INCIDENT MONITORING",
              style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF60A5FA)),
                  )
                : const Icon(Icons.refresh_rounded, color: Color(0xFF60A5FA)),
            tooltip: "Refresh Status",
            onPressed: _isLoading ? null : _fetchTracking,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: _buildBody(isOffline),
      ),
    );
  }

  Widget _buildBody(bool isOffline) {
    if (_tracking == null && _isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFF3B82F6)),
              SizedBox(height: 16),
              Text(
                "Retrieving emergency tracking data...",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_tracking == null && _errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEF4444)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 40),
            const SizedBox(height: 12),
            const Text(
              "Tracking Unavailable",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              onPressed: _fetchTracking,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text("Retry Connection"),
            ),
          ],
        ),
      );
    }

    final tracking = _tracking!;
    final isLocalPending = tracking.isLocalPending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Error banner if refresh failed while displaying stale data
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 1. Status Header Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: tracking.statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tracking.statusColor.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      isLocalPending ? "LOCAL QUEUE" : "ID: ${tracking.id}",
                      style: const TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tracking.statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tracking.status.toUpperCase(),
                      style: TextStyle(color: tracking.statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Icon(tracking.statusIcon, color: tracking.statusColor, size: 44),
              const SizedBox(height: 10),
              Text(
                tracking.statusDisplay,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tracking.statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tracking.statusDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. Status Progression Timeline
        _buildStatusTimeline(tracking),
        const SizedBox(height: 18),

        // 3. Incident Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Incident Information",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Divider(color: Color(0xFF334155), height: 18),
              _buildDetailRow("Title", tracking.title),
              _buildDetailRow("Category", tracking.category.replaceAll('_', ' ')),
              if (tracking.description != null && tracking.description!.isNotEmpty)
                _buildDetailRow("Details", tracking.description!),
              _buildDetailRow("People Affected", "${tracking.affectedCount} person(s)"),
              _buildDetailRow("Coordinates", "${tracking.latitude.toStringAsFixed(4)}° N, ${tracking.longitude.toStringAsFixed(4)}° E"),
              _buildDetailRow("Transmission", isLocalPending ? "SAVED LOCALLY (Offline Queue)" : "TRANSMITTED (Server Synced)",
                  valueColor: isLocalPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Priority Evaluation (only when returned by backend)
        if (tracking.priorityLevel != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Priority Evaluation",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${tracking.priorityLevel} (${tracking.priorityScore ?? 0} pts)",
                        style: const TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                if (tracking.priorityReasons.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    "Decision Engine Contributing Factors:",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  ...tracking.priorityReasons.map((reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ", style: TextStyle(color: Color(0xFF60A5FA))),
                            Expanded(
                              child: Text(
                                reason,
                                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 5. Vulnerability Snapshot Attachment Confirmation (Rule 15 Privacy Compliant)
        if (tracking.hasVulnerabilitySnapshot)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF60A5FA), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "VULNERABILITY PROFILE ATTACHED (Directs Dispatch Equipment)",
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // 6. Last Updated Timestamp & Refresh Action
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Last Updated",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                  ),
                  Text(
                    _formatDate(tracking.updatedAt),
                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isLoading ? null : _fetchTracking,
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text("Refresh", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Return to Home Dashboard
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF94A3B8),
            side: const BorderSide(color: Color(0xFF334155)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
          child: const Text("RETURN TO HOME DASHBOARD"),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatusTimeline(EmergencyTracking tracking) {
    final currentStep = tracking.timelineStep;
    final isCancelled = tracking.status.toUpperCase() == 'CANCELLED';

    final steps = [
      {'title': 'Report Created', 'subtitle': 'Logged on device'},
      {'title': 'Received', 'subtitle': 'Queued by server'},
      {'title': 'Assigned', 'subtitle': 'Unit allocated'},
      {'title': 'In Response', 'subtitle': 'Operations underway'},
      {'title': 'Resolved', 'subtitle': 'Incident closed'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Response Progression",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (isCancelled)
            const Text(
              "Incident report was cancelled.",
              style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
            )
          else
            ...List.generate(steps.length, (index) {
              final isCompleted = currentStep > index;
              final isCurrent = currentStep == index;
              final isLast = index == steps.length - 1;

              Color stepColor;
              if (isCurrent) {
                stepColor = tracking.statusColor;
              } else if (isCompleted) {
                stepColor = const Color(0xFF10B981);
              } else {
                stepColor = const Color(0xFF475569);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isCurrent || isCompleted ? stepColor.withValues(alpha: 0.2) : const Color(0xFF0F172A),
                          shape: BoxShape.circle,
                          border: Border.all(color: stepColor, width: isCurrent ? 2 : 1.2),
                        ),
                        child: Center(
                          child: Icon(
                            isCompleted
                                ? Icons.check
                                : (isCurrent ? Icons.circle : Icons.circle_outlined),
                            color: stepColor,
                            size: 11,
                          ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 26,
                          color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF334155),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[index]['title']!,
                            style: TextStyle(
                              color: isCurrent ? Colors.white : (isCompleted ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            steps[index]['subtitle']!,
                            style: TextStyle(
                              color: isCurrent ? stepColor : const Color(0xFF64748B),
                              fontSize: 10,
                            ),
                          ),
                          if (!isLast) const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? const Color(0xFFF1F5F9),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$y-$m-$d $h:$min";
  }
}
