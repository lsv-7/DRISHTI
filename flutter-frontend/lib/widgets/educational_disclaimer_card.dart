import 'package:flutter/material.dart';
import '../theme/drishti_theme.dart';

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
        color: DrishtiColors.lightBlue.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: DrishtiColors.primaryBlue.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: DrishtiColors.primaryBlue,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Operational Priority Heuristic Notice",
                  style: TextStyle(
                    color: DrishtiColors.darkNavyText,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Vulnerability factors are used strictly as operational priority heuristics for emergency response and resource allocation, not clinical medical triage.",
                  style: TextStyle(
                    color: DrishtiColors.secondaryText,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  const Text(
                    "This information ensures response coordinators dispatch suitable resources (e.g., medical boat teams, wheelchair transport) to citizens who need them most.",
                    style: TextStyle(
                      color: DrishtiColors.secondaryText,
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
