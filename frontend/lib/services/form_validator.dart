import 'package:flutter/foundation.dart';

class FormValidator {
  // Email validation regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Password validation patterns
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  // Name validation regex (letters, spaces, hyphens, apostrophes)
  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");

  // Minimum password length
  static const int _minPasswordLength = 8;
  static const int _maxPasswordLength = 128;

  // Name constraints
  static const int _minNameLength = 2;
  static const int _maxNameLength = 50;

  /// Validate email address
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    // Trim whitespace
    email = email.trim();

    if (email.isEmpty) {
      return 'Email is required';
    }

    if (email.length > 254) {
      return 'Email is too long';
    }

    if (!_emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    // Additional checks for common email issues
    if (email.startsWith('.') || email.endsWith('.')) {
      return 'Email cannot start or end with a period';
    }

    if (email.contains('..')) {
      return 'Email cannot contain consecutive periods';
    }

    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < _minPasswordLength) {
      return 'Password must be at least $_minPasswordLength characters long';
    }

    if (password.length > _maxPasswordLength) {
      return 'Password is too long (max $_maxPasswordLength characters)';
    }

    if (!_uppercaseRegex.hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!_lowercaseRegex.hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!_digitRegex.hasMatch(password)) {
      return 'Password must contain at least one number';
    }

    // Check for common weak passwords
    if (_isCommonPassword(password)) {
      return 'This password is too common. Please choose a stronger password';
    }

    return null;
  }

  /// Validate password with special character requirement
  static String? validateStrongPassword(String? password) {
    final basicValidation = validatePassword(password);
    if (basicValidation != null) return basicValidation;

    if (!_specialCharRegex.hasMatch(password!)) {
      return 'Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)';
    }

    return null;
  }

  /// Validate name
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name is required';
    }

    // Trim whitespace
    name = name.trim();

    if (name.isEmpty) {
      return 'Name is required';
    }

    if (name.length < _minNameLength) {
      return 'Name must be at least $_minNameLength characters long';
    }

    if (name.length > _maxNameLength) {
      return 'Name is too long (max $_maxNameLength characters)';
    }

    if (!_nameRegex.hasMatch(name)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    // Check for excessive spaces
    if (name.contains(RegExp(r'\s{2,}'))) {
      return 'Name cannot contain multiple consecutive spaces';
    }

    return null;
  }

  /// Validate password confirmation
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate terms acceptance
  static String? validateTermsAcceptance(bool? accepted) {
    if (accepted != true) {
      return 'You must accept the terms and conditions to continue';
    }
    return null;
  }

  /// Check if email format is valid (without error message)
  static bool isValidEmail(String email) {
    return validateEmail(email) == null;
  }

  /// Check if password is strong (without error message)
  static bool isStrongPassword(String password) {
    return validatePassword(password) == null;
  }

  /// Check if name is valid (without error message)
  static bool isValidName(String name) {
    return validateName(name) == null;
  }

  /// Sanitize input to prevent injection attacks
  static String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input
        .replaceAll(RegExp(r'[<>"\'']'), '') // Remove HTML/script injection chars
        .replaceAll(RegExp(r'[;&|`]'), '') // Remove command injection chars
        .trim();
  }

  /// Get password strength score (0-4)
  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int score = 0;

    // Length check
    if (password.length >= _minPasswordLength) score++;

    // Character variety checks
    if (_uppercaseRegex.hasMatch(password)) score++;
    if (_lowercaseRegex.hasMatch(password)) score++;
    if (_digitRegex.hasMatch(password)) score++;
    if (_specialCharRegex.hasMatch(password)) score++;

    // Bonus for longer passwords
    if (password.length >= 12) score++;

    // Penalty for common passwords
    if (_isCommonPassword(password)) score = score > 0 ? score - 1 : 0;

    return score.clamp(0, 4);
  }

  /// Get password strength description
  static String getPasswordStrengthDescription(int strength) {
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Unknown';
    }
  }

  /// Real-time email validation for UI feedback
  static ValidationResult validateEmailRealTime(String email) {
    if (email.isEmpty) {
      return ValidationResult(isValid: false, message: null, showError: false);
    }

    final error = validateEmail(email);
    return ValidationResult(
      isValid: error == null,
      message: error,
      showError: email.length > 3, // Only show error after user has typed a bit
    );
  }

  /// Real-time password validation for UI feedback
  static ValidationResult validatePasswordRealTime(String password) {
    if (password.isEmpty) {
      return ValidationResult(isValid: false, message: null, showError: false);
    }

    final error = validatePassword(password);
    final strength = getPasswordStrength(password);
    
    return ValidationResult(
      isValid: error == null,
      message: error,
      showError: password.length > 2, // Only show error after user has typed a bit
      metadata: {
        'strength': strength,
        'strengthDescription': getPasswordStrengthDescription(strength),
      },
    );
  }

  /// Real-time name validation for UI feedback
  static ValidationResult validateNameRealTime(String name) {
    if (name.isEmpty) {
      return ValidationResult(isValid: false, message: null, showError: false);
    }

    final error = validateName(name);
    return ValidationResult(
      isValid: error == null,
      message: error,
      showError: name.length > 1, // Only show error after user has typed a bit
    );
  }

  /// Check if password is in common password list
  static bool _isCommonPassword(String password) {
    // List of common weak passwords
    const commonPasswords = [
      'password',
      '123456',
      '123456789',
      'qwerty',
      'abc123',
      'password123',
      'admin',
      'letmein',
      'welcome',
      'monkey',
      '1234567890',
      'iloveyou',
      'princess',
      'rockyou',
      '12345678',
      'sunshine',
      'password1',
      '123123',
      'welcome123',
      'admin123',
    ];

    return commonPasswords.contains(password.toLowerCase());
  }
}

/// Result of validation with additional metadata
class ValidationResult {
  final bool isValid;
  final String? message;
  final bool showError;
  final Map<String, dynamic>? metadata;

  const ValidationResult({
    required this.isValid,
    this.message,
    required this.showError,
    this.metadata,
  });

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, message: $message, showError: $showError)';
  }
}

/// Form validation state for complex forms
class FormValidationState {
  final Map<String, ValidationResult> _fieldResults = {};
  final Map<String, String> _fieldValues = {};

  /// Update field value and validation result
  void updateField(String fieldName, String value, ValidationResult result) {
    _fieldValues[fieldName] = value;
    _fieldResults[fieldName] = result;
  }

  /// Get validation result for a field
  ValidationResult? getFieldResult(String fieldName) {
    return _fieldResults[fieldName];
  }

  /// Get value for a field
  String? getFieldValue(String fieldName) {
    return _fieldValues[fieldName];
  }

  /// Check if all fields are valid
  bool get isFormValid {
    return _fieldResults.values.every((result) => result.isValid);
  }

  /// Get all invalid fields
  List<String> get invalidFields {
    return _fieldResults.entries
        .where((entry) => !entry.value.isValid)
        .map((entry) => entry.key)
        .toList();
  }

  /// Clear all validation state
  void clear() {
    _fieldResults.clear();
    _fieldValues.clear();
  }

  /// Get form data as map
  Map<String, String> get formData => Map.from(_fieldValues);

  @override
  String toString() {
    return 'FormValidationState(isValid: $isFormValid, fields: ${_fieldResults.keys.toList()})';
  }
}