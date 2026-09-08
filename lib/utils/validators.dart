/// Form validation utilities for authentication and registration
class AuthValidator {
  /// Validates full name: required, min 3 characters, valid characters
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Full name must be at least 3 characters';
    }
    final nameRegex = RegExp(r"^[a-zA-Z\s\.\-']+$");
    if (!nameRegex.hasMatch(trimmed)) {
      return 'Full name should only contain letters and spaces';
    }
    return null;
  }

  /// Validates email format: required, standard email regex
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address (e.g. name@example.com)';
    }
    return null;
  }

  /// Validates phone number: strictly required to be 10 numeric digits
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your 10-digit mobile number';
    }
    // Remove spaces, dashes, or parentheses
    final cleanPhone = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\d+$').hasMatch(cleanPhone)) {
      return 'Phone number must contain only numbers';
    }
    if (cleanPhone.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    return null;
  }

  /// Validates password: required, minimum 4 characters (standard allows 4-6, checks min 4)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 4) {
      return 'Password must be at least 4 characters';
    }
    return null;
  }

  /// Validates password confirmation
  static String? validateConfirmPassword(
      String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates login identifier: can be either a valid email OR a 10-digit phone
  static String? validateLoginIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email or 10-digit mobile number';
    }
    final trimmed = value.trim();
    if (trimmed.contains('@')) {
      return validateEmail(trimmed);
    } else {
      final clean = trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (clean.length == 10 && RegExp(r'^\d{10}$').hasMatch(clean)) {
        return null;
      }
      return 'Enter a valid email or 10-digit mobile number';
    }
  }

  /// Returns true if the identifier is a valid 10-digit phone number
  static bool isPhone(String value) {
    final clean = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return clean.length == 10 && RegExp(r'^\d{10}$').hasMatch(clean);
  }

  /// Cleans phone number to plain 10 digits
  static String cleanPhone(String value) {
    return value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }
}
