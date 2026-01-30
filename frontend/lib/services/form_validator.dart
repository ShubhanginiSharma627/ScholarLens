class FormValidator {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
  static const int _minPasswordLength = 6;
  static const int _maxPasswordLength = 128;
  static const int _minNameLength = 2;
  static const int _maxNameLength = 50;
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
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
    if (email.startsWith('.') || email.endsWith('.')) {
      return 'Email cannot start or end with a period';
    }
    if (email.contains('..')) {
      return 'Email cannot contain consecutive periods';
    }
    return null;
  }
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
    if (_isCommonPassword(password)) {
      return 'This password is too common. Please choose a stronger password';
    }
    return null;
  }
  static String? validateStrongPassword(String? password) {
    final basicValidation = validatePassword(password);
    if (basicValidation != null) return basicValidation;
    if (!_specialCharRegex.hasMatch(password!)) {
      return 'Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)';
    }
    return null;
  }
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name is required';
    }
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
    if (name.contains(RegExp(r'\s{2,}'))) {
      return 'Name cannot contain multiple consecutive spaces';
    }
    return null;
  }
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  static String? validateTermsAcceptance(bool? accepted) {
    if (accepted != true) {
      return 'You must accept the terms and conditions to continue';
    }
    return null;
  }
  static bool isValidEmail(String email) {
    return validateEmail(email) == null;
  }
  static bool isStrongPassword(String password) {
    return validatePassword(password) == null;
  }
  static bool isValidName(String name) {
    return validateName(name) == null;
  }
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>"\'']'), '') // Remove HTML/script injection chars
        .replaceAll(RegExp(r'[;&|`]'), '') // Remove command injection chars
        .trim();
  }
  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= _minPasswordLength) score++;
    if (_uppercaseRegex.hasMatch(password)) score++;
    if (_lowercaseRegex.hasMatch(password)) score++;
    if (_digitRegex.hasMatch(password)) score++;
    if (_specialCharRegex.hasMatch(password)) score++;
    if (password.length >= 12) score++;
    if (_isCommonPassword(password)) score = score > 0 ? score - 1 : 0;
    return score.clamp(0, 4);
  }
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
  static bool _isCommonPassword(String password) {
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
class FormValidationState {
  final Map<String, ValidationResult> _fieldResults = {};
  final Map<String, String> _fieldValues = {};
  void updateField(String fieldName, String value, ValidationResult result) {
    _fieldValues[fieldName] = value;
    _fieldResults[fieldName] = result;
  }
  ValidationResult? getFieldResult(String fieldName) {
    return _fieldResults[fieldName];
  }
  String? getFieldValue(String fieldName) {
    return _fieldValues[fieldName];
  }
  bool get isFormValid {
    return _fieldResults.values.every((result) => result.isValid);
  }
  List<String> get invalidFields {
    return _fieldResults.entries
        .where((entry) => !entry.value.isValid)
        .map((entry) => entry.key)
        .toList();
  }
  void clear() {
    _fieldResults.clear();
    _fieldValues.clear();
  }
  Map<String, String> get formData => Map.from(_fieldValues);
  @override
  String toString() {
    return 'FormValidationState(isValid: $isFormValid, fields: ${_fieldResults.keys.toList()})';
  }
}