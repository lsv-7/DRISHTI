import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/offline_service.dart';
import '../services/location_service.dart';
import '../models/emergency_report.dart';
import 'emergency_confirmation_screen.dart';

class EmergencyReportingScreen extends StatefulWidget {
  const EmergencyReportingScreen({super.key});

  @override
  State<EmergencyReportingScreen> createState() => _EmergencyReportingScreenState();
}

class _EmergencyReportingScreenState extends State<EmergencyReportingScreen> {
  final _formKey = GlobalKey<FormState>();

  String _category = 'FLOOD_RESCUE';
  int _affectedCount = 1;
  final TextEditingController _titleController = TextEditingController(text: "Immediate Flood Rescue Required");
  final TextEditingController _descriptionController = TextEditingController();

  LocationResult _location = LocationResult.defaultVijayawada();
  bool _isAcquiringLocation = false;
  bool _isSubmitting = false;
  String? _formValidationError;
  String? _submissionError;

  final List<Map<String, dynamic>> _categories = const [
    {
      'id': 'FLOOD_RESCUE',
      'label': 'Flood Rescue',
      'desc': 'Rising waters, boat needed',
      'icon': Icons.waves_rounded,
      'color': Color(0xFF3B82F6),
    },
    {
      'id': 'MEDICAL_EMERGENCY',
      'label': 'Medical Emergency',
      'desc': 'Life-threatening injury/illness',
      'icon': Icons.medical_services_rounded,
      'color': Color(0xFFEF4444),
    },
    {
      'id': 'TRAPPED_CITIZENS',
      'label': 'Trapped in Building',
      'desc': 'Collapsed exit or roof trapped',
      'icon': Icons.home_work_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'id': 'SHELTER_EVACUATION',
      'label': 'Shelter Needed',
      'desc': 'Displaced, needs transport',
      'icon': Icons.night_shelter_rounded,
      'color': Color(0xFF10B981),
    },
    {
      'id': 'RELIEF_SUPPLY',
      'label': 'Food & Water',
      'desc': 'Isolated without essentials',
      'icon': Icons.inventory_2_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'id': 'OTHER',
      'label': 'Other Incident',
      'desc': 'General disaster assistance',
      'icon': Icons.emergency_rounded,
      'color': Color(0xFF64748B),
    },
  ];

  final List<String> _quickPresets = [
    "Water level rising rapidly",
    "Trapped on upper floor / roof",
    "Elderly person requires stretcher",
    "Power cut & oxygen supply low",
    "Infant needing food / formula",
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _refreshLocation({
    LocationPermissionState mockPermission = LocationPermissionState.granted,
    GpsHardwareState mockHardware = GpsHardwareState.enabled,
    bool forceFail = false,
  }) async {
    setState(() => _isAcquiringLocation = true);
    final result = await LocationService.acquireCoordinates(
      mockPermission: mockPermission,
      mockHardware: mockHardware,
      forceFail: forceFail,
    );
    if (mounted) {
      setState(() {
        _location = result;
        _isAcquiringLocation = false;
      });
    }
  }

  void _showSectorSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.share_location_rounded, color: Color(0xFF60A5FA), size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Select Operational Sector",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Text(
                  "Choose a known Vijayawada disaster operational zone if device GPS is degraded or unavailable:",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: LocationService.vijayawadaDisasterSectors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final sector = LocationService.vijayawadaDisasterSectors[index];
                      final isSelected = _location.isValid &&
                          (_location.latitude - (sector['latitude'] as double)).abs() < 0.0001 &&
                          (_location.longitude - (sector['longitude'] as double)).abs() < 0.0001;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _location = LocationService.selectSector(index);
                          });
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF1E293B),
                              content: Text("Selected: ${sector['shortName']}"),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.location_on_outlined,
                                color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sector['name'] as String,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${(sector['latitude'] as double).toStringAsFixed(4)}° N, ${(sector['longitude'] as double).toStringAsFixed(4)}° E • ${sector['risk']}",
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitReport() async {
    setState(() {
      _formValidationError = null;
      _submissionError = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _formValidationError = "Please fix the highlighted form errors before submitting.";
      });
      return;
    }

    if (!_location.isValid) {
      const locationMsg = "Valid incident location is required. Please acquire GPS or select an emergency sector.";
      setState(() {
        _formValidationError = locationMsg;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFEF4444),
          content: Text(locationMsg),
        ),
      );
      return;
    }

    final offlineService = Provider.of<OfflineService>(context, listen: false);

    // Validate using EmergencyReport domain model
    final reportModel = EmergencyReport(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      category: _category,
      latitude: _location.latitude,
      longitude: _location.longitude,
      affectedCount: _affectedCount,
      vulnerabilitySnapshot: offlineService.vulnerabilityProfile.toSnapshot(),
      createdAt: DateTime.now(),
    );

    final validationResult = reportModel.validateDetailed();
    if (!validationResult.isValid) {
      final msg = validationResult.primaryError ?? "Validation error";
      setState(() {
        _formValidationError = msg;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text(msg),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await offlineService.submitEmergency(
        title: reportModel.title,
        description: reportModel.description ?? "",
        category: reportModel.category,
        latitude: reportModel.latitude,
        longitude: reportModel.longitude,
        affectedCount: reportModel.affectedCount,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EmergencyConfirmationScreen(submissionResult: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final cleanMsg = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _isSubmitting = false;
          _submissionError = cleanMsg;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text("Submission error: $cleanMsg"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final offlineService = Provider.of<OfflineService>(context);
    final profile = offlineService.vulnerabilityProfile;
    final isOffline = offlineService.connectivity == ConnectivityState.offline;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          "Report Emergency / SOS",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isOffline ? const Color(0xFFEF4444).withValues(alpha: 0.2) : const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOffline ? Icons.wifi_off : Icons.wifi,
                  color: isOffline ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  isOffline ? "OFFLINE" : "ONLINE",
                  style: TextStyle(
                    color: isOffline ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Validation Error Banner
              if (_formValidationError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formValidationError!,
                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Color(0xFFFCA5A5)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _formValidationError = null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submission Error Banner
              if (_submissionError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            "Submission Notice",
                            style: TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Color(0xFFFBBF24)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _submissionError = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _submissionError!,
                        style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Emergency Category Selection
              const Text(
                "1. Select Emergency Type",
                style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _category == cat['id'];
                  final Color catColor = cat['color'] as Color;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _category = cat['id'] as String;
                        if (_category == 'FLOOD_RESCUE') {
                          _titleController.text = "Immediate Flood Rescue Required";
                        } else if (_category == 'MEDICAL_EMERGENCY') {
                          _titleController.text = "Urgent Medical Assistance Required";
                        } else if (_category == 'TRAPPED_CITIZENS') {
                          _titleController.text = "Citizens Trapped in Flooded Structure";
                        } else if (_category == 'SHELTER_EVACUATION') {
                          _titleController.text = "Emergency Shelter & Evacuation Transport";
                        } else if (_category == 'RELIEF_SUPPLY') {
                          _titleController.text = "Critical Food and Drinking Water Request";
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? catColor.withValues(alpha: 0.2) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? catColor : const Color(0xFF334155),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(cat['icon'] as IconData, color: isSelected ? catColor : const Color(0xFF94A3B8), size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cat['label'] as String,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  cat['desc'] as String,
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 2. People Affected Stepper
              const Text(
                "2. Number of People Affected",
                style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, color: Color(0xFF60A5FA), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "$_affectedCount person(s) needing rescue",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF94A3B8)),
                      onPressed: _affectedCount > 1 ? () => setState(() => _affectedCount--) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF60A5FA)),
                      onPressed: _affectedCount < 50 ? () => setState(() => _affectedCount++) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Location Capture & Verification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "3. Incident Location",
                    style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF60A5FA),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: const Size(60, 24),
                        ),
                        onPressed: _showSectorSelectionModal,
                        icon: const Icon(Icons.map_outlined, size: 13),
                        label: const Text("Choose Sector", style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF60A5FA),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: const Size(60, 24),
                        ),
                        onPressed: _isAcquiringLocation ? null : () => _refreshLocation(),
                        icon: _isAcquiringLocation
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF60A5FA)),
                              )
                            : const Icon(Icons.my_location_rounded, size: 13),
                        label: const Text("Refresh GPS", style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location State Card
              if (_isAcquiringLocation)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF60A5FA)),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Acquiring high-precision GPS lock...",
                          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )
              else if (!_location.isValid)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF4444), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_disabled_rounded, color: Color(0xFFEF4444), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _location.permissionState == LocationPermissionState.permanentlyDenied
                                  ? "Location Permission Permanently Denied"
                                  : (_location.permissionState == LocationPermissionState.denied
                                      ? "Location Permission Denied"
                                      : (_location.hardwareState == GpsHardwareState.disabled
                                          ? "Device GPS Hardware Turned Off"
                                          : "GPS Acquisition Unavailable")),
                              style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "ACTION REQUIRED",
                              style: TextStyle(color: Color(0xFFF87171), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _location.errorMessage ??
                            "Coordinates are required to dispatch emergency units. Please enable GPS or select an operational sector.",
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF60A5FA),
                                side: const BorderSide(color: Color(0xFF3B82F6)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => _refreshLocation(),
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: Text(
                                _location.permissionState == LocationPermissionState.permanentlyDenied
                                    ? "Retry / Check"
                                    : "Retry GPS",
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: _showSectorSelectionModal,
                              icon: const Icon(Icons.share_location_rounded, size: 14),
                              label: const Text("Choose Sector", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: _location.source == LocationSource.gps
                            ? const Color(0xFF10B981)
                            : const Color(0xFF60A5FA),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${_location.latitude.toStringAsFixed(4)}° N, ${_location.longitude.toStringAsFixed(4)}° E",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              "${_location.label} • ${_location.accuracy}${_location.source == LocationSource.gps ? '' : ' (Nominal)'}",
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _location.source == LocationSource.gps
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _location.sourceBadge,
                          style: TextStyle(
                            color: _location.source == LocationSource.gps
                                ? const Color(0xFF34D399)
                                : const Color(0xFF60A5FA),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // 4. Description & Details
              const Text(
                "4. Details & Landmarks",
                style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                maxLength: 150,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: "Title / Short Summary *",
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  counterStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  ),
                ),
                validator: (val) {
                  final trimmed = val?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return "Emergency title or summary is required.";
                  }
                  if (trimmed.length < 5) {
                    return "Emergency title must be at least 5 characters.";
                  }
                  if (trimmed.length > 150) {
                    return "Emergency title cannot exceed 150 characters.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                maxLength: 500,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Specific hazards (e.g. electrical wire submerged, water at waist level, elderly trapped)...",
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  counterStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val != null && val.trim().length > 500) {
                    return "Description cannot exceed 500 characters.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Quick Preset Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickPresets.map((preset) {
                  return ActionChip(
                    label: Text(preset),
                    backgroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFF334155)),
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                    onPressed: () {
                      final current = _descriptionController.text.trim();
                      if (current.isEmpty) {
                        _descriptionController.text = preset;
                      } else {
                        _descriptionController.text = "$current; $preset";
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 5. Attached Vulnerability Snapshot Preview (T043 Integration)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Color(0xFF60A5FA), size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Attached Vulnerability Snapshot",
                          style: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Immutable profile snapshot attached: Age ${profile.age ?? 30} (${profile.ageGroup}) • ${profile.canSwim ? 'Can Swim' : 'Cannot Swim'} • Mobility: ${profile.mobilityStatus}${profile.medicalConditions.isNotEmpty ? ' • Conditions: ${profile.medicalConditions.join(', ')}' : ''}",
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Submit SOS Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _location.isValid ? const Color(0xFFEF4444) : const Color(0xFF475569),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF334155),
                  disabledForegroundColor: const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: _location.isValid ? 4 : 0,
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(
                  _isSubmitting
                      ? "TRANSMITTING SOS..."
                      : (_location.isValid
                          ? "TRANSMIT EMERGENCY REPORT / SOS"
                          : "LOCATION REQUIRED TO TRANSMIT SOS"),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8),
                ),
                onPressed: (_isSubmitting || !_location.isValid) ? null : _submitReport,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF94A3B8),
                  side: const BorderSide(color: Color(0xFF334155)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
