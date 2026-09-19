import 'package:flutter/material.dart';
import 'home_screen.dart';

class EmergencyConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> submissionResult;

  const EmergencyConfirmationScreen({
    super.key,
    required this.submissionResult,
  });

  @override
  Widget build(BuildContext context) {
    final status = submissionResult['status'] as String? ?? 'SAVED_LOCALLY';
    final isOnline = status == 'SUCCESS';
    final item = (submissionResult['item'] as Map<String, dynamic>?) ?? {};

    final emergencyId = item['id'] as String? ?? item['idempotency_key'] as String? ?? 'DR-LOCAL';
    final title = item['title'] as String? ?? 'Emergency Incident';
    final category = item['category'] as String? ?? 'FLOOD_RESCUE';
    final affectedCount = item['affected_count'] as int? ?? 1;
    final lat = item['latitude'] as double? ?? 16.5062;
    final lon = item['longitude'] as double? ?? 80.6480;
    final priorityLevel = item['priority_level'] as String?;
    final priorityScore = item['priority_score'] as num?;
    final reasons = item['priority_reasons'] as List?;
    final snapshot = item['vulnerability_snapshot'] as Map<String, dynamic>?;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: const Text(
            "Incident Confirmation",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOnline
                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isOnline ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                      color: isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isOnline ? "EMERGENCY REPORTED & TRANSMITTED" : "EMERGENCY SAVED LOCALLY",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isOnline
                          ? "Received by Command Center Decision Engine."
                          : "Stored in offline device queue. Will auto-sync when network or radio is available.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Incident Details Card
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
                      "Incident Report Summary",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Divider(color: Color(0xFF334155), height: 20),
                    _buildDetailRow("Emergency ID", emergencyId),
                    _buildDetailRow("Category", category.replaceAll('_', ' ')),
                    _buildDetailRow("Summary", title),
                    _buildDetailRow("People Affected", "$affectedCount person(s)"),
                    _buildDetailRow("GPS Coordinates", "${lat.toStringAsFixed(4)}° N, ${lon.toStringAsFixed(4)}° E"),
                    _buildDetailRow(
                      "Transmission State",
                      isOnline ? "SYNCED (Online)" : "LOCAL_PENDING (Offline Queue)",
                      valueColor: isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Priority Details (if calculated and returned by backend)
              if (isOnline && priorityLevel != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Priority Evaluation",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "$priorityLevel (${priorityScore ?? 0} pts)",
                              style: const TextStyle(
                                color: Color(0xFFF87171),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (reasons != null && reasons.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text(
                          "Contributing Decision Engine Factors:",
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        ...reasons.map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("• ", style: TextStyle(color: Color(0xFF60A5FA))),
                                  Expanded(
                                    child: Text(
                                      r.toString(),
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

              // Attached Vulnerability Snapshot Summary
              if (snapshot != null) ...[
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
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Color(0xFF60A5FA), size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Attached Vulnerability Snapshot",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Immutable traits captured at submission time to direct suitable dispatch equipment:",
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildTraitChip("Age: ${snapshot['age'] ?? 'N/A'} (${snapshot['age_group'] ?? 'ADULT'})"),
                          _buildTraitChip(
                            snapshot['can_swim'] == true ? "Can Swim" : "Cannot Swim",
                            isAlert: snapshot['can_swim'] == false,
                          ),
                          _buildTraitChip("Mobility: ${snapshot['mobility_status'] ?? 'FULL'}"),
                          if (snapshot['medical_conditions'] is List &&
                              (snapshot['medical_conditions'] as List).isNotEmpty)
                            _buildTraitChip("Conditions: ${(snapshot['medical_conditions'] as List).join(', ')}"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Return to Home Action Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6), // Accent Blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  "RETURN TO HOME DASHBOARD",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
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

  Widget _buildTraitChip(String text, {bool isAlert = false}) {
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
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
