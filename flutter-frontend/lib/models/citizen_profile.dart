// Strongly typed Citizen Profile model for DRISHTI AI
//
// Represents basic citizen identification and contact details.
// Kept strictly separate from the vulnerability profile heuristics (ADR-008).

enum CitizenProfileStatus {
  incomplete,
  complete,
}

class CitizenProfileValidationResult {
  final bool isValid;
  final String? primaryError;
  final Map<String, String> fieldErrors;

  const CitizenProfileValidationResult({
    required this.isValid,
    this.primaryError,
    this.fieldErrors = const {},
  });

  static const valid = CitizenProfileValidationResult(isValid: true);
}

class CitizenProfile {
  final String fullName;
  final String phoneNumber;
  final String? email;
  final int? age;
  final String? gender;
  final String? address;
  final String? city;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final CitizenProfileStatus status;

  const CitizenProfile({
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.age,
    this.gender,
    this.address,
    this.city,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.status = CitizenProfileStatus.complete,
  });

  bool get isComplete => status == CitizenProfileStatus.complete;

  /// Default fallback profile when profile is not yet configured or for tests.
  factory CitizenProfile.defaultProfile() {
    return const CitizenProfile(
      fullName: 'Citizen User',
      phoneNumber: '9876543210',
      email: null,
      age: 30,
      gender: null,
      address: null,
      city: 'Vijayawada',
      emergencyContactName: null,
      emergencyContactPhone: null,
      status: CitizenProfileStatus.complete,
    );
  }

  /// Empty profile for initial onboarding form state.
  factory CitizenProfile.empty() {
    return const CitizenProfile(
      fullName: '',
      phoneNumber: '',
      email: null,
      age: null,
      gender: null,
      address: null,
      city: 'Vijayawada',
      emergencyContactName: null,
      emergencyContactPhone: null,
      status: CitizenProfileStatus.incomplete,
    );
  }

  static String? validateFullName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Full name is required.';
    if (trimmed.length < 2) return 'Full name must be at least 2 characters.';
    if (trimmed.length > 100) return 'Full name cannot exceed 100 characters.';
    return null;
  }

  static String? validatePhoneNumber(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (trimmed.isEmpty) return 'Phone number is required.';
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(trimmed)) {
      return 'Enter a valid phone number (8-15 digits).';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    if (!RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? validateEmergencyPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(trimmed)) {
      return 'Enter a valid emergency contact phone number.';
    }
    return null;
  }

  /// Validates all citizen profile fields deterministically.
  CitizenProfileValidationResult validate() {
    final errors = <String, String>{};

    final nameErr = validateFullName(fullName);
    if (nameErr != null) errors['fullName'] = nameErr;

    final phoneErr = validatePhoneNumber(phoneNumber);
    if (phoneErr != null) errors['phoneNumber'] = phoneErr;

    final emailErr = validateEmail(email);
    if (emailErr != null) errors['email'] = emailErr;

    final emPhoneErr = validateEmergencyPhone(emergencyContactPhone);
    if (emPhoneErr != null) errors['emergencyContactPhone'] = emPhoneErr;

    if (errors.isNotEmpty) {
      return CitizenProfileValidationResult(
        isValid: false,
        primaryError: errors.values.first,
        fieldErrors: errors,
      );
    }

    return CitizenProfileValidationResult.valid;
  }

  CitizenProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? email,
    int? age,
    String? gender,
    String? address,
    String? city,
    String? emergencyContactName,
    String? emergencyContactPhone,
    CitizenProfileStatus? status,
  }) {
    return CitizenProfile(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      city: city ?? this.city,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName.trim(),
      'phone': phoneNumber.trim(),
      'email': email?.trim().isEmpty == true ? null : email?.trim(),
      'age': age,
      'gender': gender?.trim().isEmpty == true ? null : gender?.trim(),
      'address': address?.trim().isEmpty == true ? null : address?.trim(),
      'city': city?.trim().isEmpty == true ? null : city?.trim(),
      'emergency_contact_name': emergencyContactName?.trim().isEmpty == true ? null : emergencyContactName?.trim(),
      'emergency_contact_phone': emergencyContactPhone?.trim().isEmpty == true ? null : emergencyContactPhone?.trim(),
    };
  }

  Map<String, dynamic> toPersistenceJson() {
    final map = toJson();
    map['status'] = status.name;
    return map;
  }

  factory CitizenProfile.fromJson(Map<String, dynamic> json) {
    CitizenProfileStatus st = CitizenProfileStatus.complete;
    if (json.containsKey('status')) {
      final s = json['status'] as String?;
      if (s == 'incomplete') {
        st = CitizenProfileStatus.incomplete;
      }
    }

    return CitizenProfile(
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      phoneNumber: json['phone'] as String? ?? json['phoneNumber'] as String? ?? '',
      email: json['email'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String? ?? json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String? ?? json['emergencyContactPhone'] as String?,
      status: st,
    );
  }
}
