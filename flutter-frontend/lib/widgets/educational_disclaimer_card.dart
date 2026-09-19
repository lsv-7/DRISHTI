import 'package:flutter/material.dart';

/// Mandatory Educational Notice Widget for DRISHTI AI
/// 
/// Complies with RULES.md (Rule 12, Rule 16) and Prompt constraints:
/// Discloses that vulnerability scoring is an operational decision heuristic,
/// NOT medical diagnosis or clinical triage.
class EducationalDisclaimerCard extends StatelessWidget {
  final bool compact;

  const EducationalDisclaimerCard({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10.0 : 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate 800
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.4), // Accent blue
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF60A5FA), // Light blue 400
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Operational Priority Heuristic Notice",
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Vulnerability factors are used strictly as operational priority heuristics for emergency response and resource allocation, not clinical medical triage.",
                  style: TextStyle(
                    color: Color(0xFF94A3B8), // Slate 400
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  const Text(
                    "This information ensures response coordinators dispatch suitable resources (e.g., medical boat teams, wheelchair transport) to citizens who need them most.",
                    style: TextStyle(
                      color: Color(0xFF64748B), // Slate 500
                      fontSize: 11,
                      height: 1.3,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
