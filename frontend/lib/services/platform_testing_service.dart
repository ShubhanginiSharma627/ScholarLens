import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'permission_handler.dart';
import 'graceful_degradation_service.dart';

/// Service for testing platform-specific functionality
class PlatformTestingService {
  static PlatformTestingService? _instance;
  static PlatformTestingService get instance => _instance ??= PlatformTestingService._();

  PlatformTestingService._();

  /// Runs comprehensive platform tests
  Future<PlatformTestResults> runPlatformTests() async {
    debugPrint('Starting platform compatibility tests...');
    
    final results = <String, TestResult>{};
    
    // Test camera functionality
    results['camera'] = await _testCameraFunctionality();
    
    // Test audio functionality
    results['audio'] = await _testAudioFunctionality();
    
    // Test voice input functionality
    results['voice'] = await _testVoiceInputFunctionality();
    
    // Test network functionality
    results['network'] = await _testNetworkFunctionality();
    
    // Test storage functionality
    results['storage'] = await _testStorageFunctionality();
    
    // Test permissions
    results['permissions'] = await _testPermissions();
    
    // Test platform-specific UI
    results['ui'] = await _testPlatformUI();
    
    final testResults = PlatformTestResults(
      platform: Platform.isIOS ? 'iOS' : 'Android',
      results: results,
      timestamp: DateTime.now(),
    );
    
    debugPrint('Platform tests completed: ${testResults.overallStatus}');
    return testResults;
  }

  /// Tests camera functionality
  Future<TestResult> _testCameraFunctionality() async {
    try {
      debugPrint('Testing camera functionality...');
      
      final issues = <String>[];
      final warnings = <String>[];
      
      // Check if camera is available
      final degradationService = GracefulDegradationService.instance;
      final cameraAvailable = await degradationService.isCameraAvailable();
      
      if (!cameraAvailable) {
        issues.add('Camera not available on this device');
      }
      
      // Check camera permissions
      final permissionHandler = PermissionHandler.instance;
      final cameraPermission = await permissionHandler.checkPermissionStatus(
        PermissionType.camera,
      );
      
      if (cameraPermission == PermissionStatus.permanentlyDenied) {
        issues.add('Camera permission permanently denied');
      } else if (cameraPermission == PermissionStatus.denied) {
        warnings.add('Camera permission not granted');
      }
      
      // Platform-specific camera tests
      if (Platform.isIOS) {
        // iOS-specific camera tests
        final iosIssues = await _testIOSCamera();
        issues.addAll(iosIssues);
      } else if (Platform.isAndroid) {
        // Android-specific camera tests
        final androidIssues = await _testAndroidCamera();
        issues.addAll(androidIssues);
      }
      
      return TestResult(
        name: 'Camera Functionality',
        status: issues.isEmpty ? TestStatus.passed : TestStatus.failed,
        issues: issues,
        warnings: warnings,
        details: 'Camera availability: $cameraAvailable, Permission: $cameraPermission',
      );
    } catch (e) {
      return TestResult(
        name: 'Camera Functionality',
        status: TestStatus.error,
        issues: ['Camera test failed: $e'],
        warnings: [],
        details: 'Exception during camera testing',
      );
    }
  }

  /// Tests audio functionality
  Future<TestResult> _testAudioFunctionality() async {
    try {
      debugPrint('Testing audio functionality...');
      
      final issues = <String>[];
      final warnings = <String>[];
      
      // Check if audio is available
      final degradationService = GracefulDegradationService.instance;
      final audioAvailable = await degradationService.isAudioAvailable();
      
      if (!audioAvailable) {
        issues.add('Audio/TTS not available on this device');
      }
      
      // Platform-specific audio tests
      if (Platform.isIOS) {
        final iosIssues = await _testIOSAudio();
        issues.addAll(iosIssues);
      } else if (Platform.isAndroid) {
        final androidIssues = await _testAndroidAudio();
        issues.addAll(androidIssues);
      }
      
      return TestResult(
        name: 'Audio Functionality',
        status: issues.isEmpty ? TestStatus.passed : TestStatus.failed,
        issues: issues,
        warnings: warnings,
        details: 'Audio availability: $audioAvailable',
      );
    } catch (e) {
      return TestResult(
        name: 'Audio Functionality',
        status: TestStatus.error,
        issues: ['Audio test failed: $e'],
        warnings: [],
        details: 'Exception during audio testing',
      );
    }
  }

  /// Tests voice input functionality
  Future<TestResult> _testVoiceInputFunctionality() async {
    try {
      debugPrint('Testing voice input functionality...');
      
      final issues = <String>[];
      final warnings = <String>[];
      
      // Check if voice input is available
      final degradationService = GracefulDegradationService.instance;
      final voiceAvailable = await degradationService.isVoiceInputAvailable();
      
      if (!voiceAvailable) {
        warnings.add('Voice input not available on this device');
      }
      
      // Check microphone permissions
      final permissionHandler = PermissionHandler.instance;
      final micPermission = await permissionHandler.checkPermissionStatus(
        PermissionType.microphone,
      );
      
      if (micPermission == PermissionStatus.permanentlyDenied) {
        issues.add('Microphone permission permanently denied');
      } else if (micPermission == PermissionStatus.denied) {
        warnings.add('Microphone permission not granted');
      }
      
      return TestResult(
        name: 'Voice Input Functionality',
        status: issues.isEmpty ? TestStatus.passed : TestStatus.failed,
        issues: issues,
        warnings: warnings,
        details: 'Voice availability: $voiceAvailable, Permission: $micPermission',
      );
    } catch (e) {
      return TestResult(
        name: 'Voice Input Functionality',
        status: TestStatus.error,
        issues: ['Voice input test failed: $e'],
        warnings: [],
        details: 'Exception during voice input testing',
      );
    }
  }

  /// Tests network functionality
  Future<TestResult> _testNetworkFunctionality() async {
    try {
      debugPrint('Testing network functionality...');
      
      final issues = <String>[];
      final warnings = <String>[];
      
      // Check network connectivity
      final degradationService = GracefulDegradationService.instance;
      final networkAvailable = await degradationService.isNetworkAvailable();
      
      if (!networkAvailable) {
        warnings.add('No network connectivity available');
      }
      
      // Test basic connectivity
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 5));
        if (result.isEmpty) {
          issues.add('DNS resolution failed');
        }
      } catch (e) {
        warnings.add('Network connectivity test failed: $e');
      }
      
      return TestResult(
        name: 'Network Functionality',
        status: issues.isEmpty ? TestStatus.passed : TestStatus.failed,
        issues: issues,
        warnings: warnings,
        details: 'Network availability: $networkAvailable',
      );
    } catch (e) {
      return TestResult(
        name: 'Network Functionality',
        status: TestStatus.error,
        issues: ['Network test failed: $e'],
        warnings: [],
        details: 'Exception during network testing',
      );
    }
  }

  /// Tests storage functionality
  Future<TestResult> _testStorageFunctionality() async {
    try {
      debugPrint('Testing storage functionality...');
      
      final issues = <String>[];
      final warnings = <String>[];
      
      // Check storage availability
      final degradationService = GracefulDegradationService.instance;
      final storageAvailable = await degradationService.isStorageAvailable();
      
      if (!storageAvailable) {
        issues.add('Storage not available or insufficient space');
      }
      
      // Check storage permissions (Android only)
      if (Platform.isAndroid) {
        final permissionHandler = PermissionHandler.instance;
        final storagePermission = await permissionHandler.checkPermissionStatus(
          PermissionType.storage,
        );
        
        if (storagePermission == PermissionStatus.permanentlyDenied) {
          warnings.add('Storage permission permanently denied');
        }
      }
      
      return TestResult(
        name: 'Storage Functionality',
        status: issues.isEmpty ? TestStatus.passed : TestStatus.failed,
        issues: issues,
        warnings: warnings,
        details: 'Storage availability: $storageAvailable',
      );
    } catch (e) {
      return TestResult(
        name: 'Storage Functionality',
        status: TestStatus.error,
        issues: ['Storage test failed: $e'],
        warnings: [],
        details: 'Exception during storage testing',
      );
    }
  }

  /// Tests permissions
  Future<TestResult> _testPermissions() async {
    try {
      debugPrint('Testing permissions...');
      
      final issues = <String>[];
      final warnings = <String>[];
      
      final permissionHandler = PermissionHandler.instance;
      
      // Test all required permissions
      final permissions = [
        PermissionType.camera,
        PermissionType.microphone,
        if (Platform.isAndroid) PermissionType.storage,
      ];
      
      for (final permission in permissions) {
        final status = await permissionHandler.checkPermissionStatus(permission);
        
        switch (status) {
          case PermissionStatus.granted:
            // All good
            break;
          case PermissionStatus.denied:
            warnings.add('${permission.name} permission not granted');
            break;
          case PermissionStatus.permanentlyDenied:
            issues.add('${permission.name} permission permanently denied');
            break;
          case PermissionStatus.unknown:
            warnings.add('${permission.name} permission status unknown');
            break;
        }
      }
      
      return TestResult(
        name: 'Permissions',
        status: issues.isEmpty ? TestStatus.passed : TestStatus.failed,
        issues: issues,
        warnings: warnings,
        details: 'Tested ${permissions.length} permissions',
      );
    } catch (e) {
      return TestResult(
        name: 'Permissions',
        status: TestStatus.error,
        issues: ['Permission test failed: $e'],
        warnings: [],
        details: 'Exception during permission testing',
      );
    }
  }

  /// Tests platform-specific UI
  Future<TestResult> _testPlatformUI() async {
    try {
      debugPrint('Testing platform UI...');
      
      final issues = <String>[];
      final warnings = <String>[];
      
      // Test platform detection
      final platform = Platform.isIOS ? 'iOS' : 'Android';
      
      // Test system UI overlay
      try {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
      } catch (e) {
        warnings.add('System UI overlay test failed: $e');
      }
      
      // Test haptic feedback
      try {
        HapticFeedback.lightImpact();
      } catch (e) {
        warnings.add('Haptic feedback test failed: $e');
      }
      
      return TestResult(
        name: 'Platform UI',
        status: issues.isEmpty ? TestStatus.passed : TestStatus.failed,
        issues: issues,
        warnings: warnings,
        details: 'Platform: $platform',
      );
    } catch (e) {
      return TestResult(
        name: 'Platform UI',
        status: TestStatus.error,
        issues: ['Platform UI test failed: $e'],
        warnings: [],
        details: 'Exception during platform UI testing',
      );
    }
  }

  // Platform-specific test methods

  Future<List<String>> _testIOSCamera() async {
    final issues = <String>[];
    
    try {
      // iOS-specific camera tests
      // Check if AVFoundation is available
      // This would typically use platform channels
      debugPrint('Running iOS camera tests...');
    } catch (e) {
      issues.add('iOS camera test failed: $e');
    }
    
    return issues;
  }

  Future<List<String>> _testAndroidCamera() async {
    final issues = <String>[];
    
    try {
      // Android-specific camera tests
      // Check Camera2 API availability
      debugPrint('Running Android camera tests...');
    } catch (e) {
      issues.add('Android camera test failed: $e');
    }
    
    return issues;
  }

  Future<List<String>> _testIOSAudio() async {
    final issues = <String>[];
    
    try {
      // iOS-specific audio tests
      // Check AVSpeechSynthesizer availability
      debugPrint('Running iOS audio tests...');
    } catch (e) {
      issues.add('iOS audio test failed: $e');
    }
    
    return issues;
  }

  Future<List<String>> _testAndroidAudio() async {
    final issues = <String>[];
    
    try {
      // Android-specific audio tests
      // Check TextToSpeech service availability
      debugPrint('Running Android audio tests...');
    } catch (e) {
      issues.add('Android audio test failed: $e');
    }
    
    return issues;
  }

  /// Gets platform compatibility report
  String generateCompatibilityReport(PlatformTestResults results) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== Platform Compatibility Report ===');
    buffer.writeln('Platform: ${results.platform}');
    buffer.writeln('Test Date: ${results.timestamp}');
    buffer.writeln('Overall Status: ${results.overallStatus}');
    buffer.writeln();
    
    buffer.writeln('Test Results:');
    for (final entry in results.results.entries) {
      final result = entry.value;
      buffer.writeln('  ${result.name}: ${result.status}');
      
      if (result.issues.isNotEmpty) {
        buffer.writeln('    Issues:');
        for (final issue in result.issues) {
          buffer.writeln('      - $issue');
        }
      }
      
      if (result.warnings.isNotEmpty) {
        buffer.writeln('    Warnings:');
        for (final warning in result.warnings) {
          buffer.writeln('      - $warning');
        }
      }
      
      if (result.details.isNotEmpty) {
        buffer.writeln('    Details: ${result.details}');
      }
      
      buffer.writeln();
    }
    
    buffer.writeln('=== End Report ===');
    
    return buffer.toString();
  }
}

/// Results of platform testing
class PlatformTestResults {
  final String platform;
  final Map<String, TestResult> results;
  final DateTime timestamp;

  const PlatformTestResults({
    required this.platform,
    required this.results,
    required this.timestamp,
  });

  /// Overall test status
  TestStatus get overallStatus {
    if (results.values.any((r) => r.status == TestStatus.error)) {
      return TestStatus.error;
    } else if (results.values.any((r) => r.status == TestStatus.failed)) {
      return TestStatus.failed;
    } else {
      return TestStatus.passed;
    }
  }

  /// Number of passed tests
  int get passedCount => results.values
      .where((r) => r.status == TestStatus.passed)
      .length;

  /// Number of failed tests
  int get failedCount => results.values
      .where((r) => r.status == TestStatus.failed)
      .length;

  /// Number of error tests
  int get errorCount => results.values
      .where((r) => r.status == TestStatus.error)
      .length;

  /// Total number of tests
  int get totalCount => results.length;

  /// Success rate as percentage
  double get successRate => totalCount > 0 ? (passedCount / totalCount) * 100 : 0;
}

/// Individual test result
class TestResult {
  final String name;
  final TestStatus status;
  final List<String> issues;
  final List<String> warnings;
  final String details;

  const TestResult({
    required this.name,
    required this.status,
    required this.issues,
    required this.warnings,
    required this.details,
  });

  @override
  String toString() {
    return 'TestResult(name: $name, status: $status, issues: ${issues.length}, warnings: ${warnings.length})';
  }
}

/// Test status
enum TestStatus {
  passed,
  failed,
  error,
}

/// Mixin for widgets that need platform testing
mixin PlatformTestingMixin<T extends StatefulWidget> on State<T> {
  /// Runs platform tests and shows results
  Future<void> runPlatformTestsWithUI() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Running platform tests...'),
          ],
        ),
      ),
    );

    try {
      final testingService = PlatformTestingService.instance;
      final results = await testingService.runPlatformTests();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show results
      _showTestResults(results);
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Platform tests failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTestResults(PlatformTestResults results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Platform Test Results'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Platform: ${results.platform}'),
              Text('Overall Status: ${results.overallStatus}'),
              Text('Success Rate: ${results.successRate.toStringAsFixed(1)}%'),
              const SizedBox(height: 16),
              ...results.results.entries.map((entry) {
                final result = entry.value;
                return ListTile(
                  leading: Icon(
                    _getStatusIcon(result.status),
                    color: _getStatusColor(result.status),
                  ),
                  title: Text(result.name),
                  subtitle: result.issues.isNotEmpty || result.warnings.isNotEmpty
                      ? Text('${result.issues.length} issues, ${result.warnings.length} warnings')
                      : null,
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(TestStatus status) {
    switch (status) {
      case TestStatus.passed:
        return Icons.check_circle;
      case TestStatus.failed:
        return Icons.error;
      case TestStatus.error:
        return Icons.warning;
    }
  }

  Color _getStatusColor(TestStatus status) {
    switch (status) {
      case TestStatus.passed:
        return Colors.green;
      case TestStatus.failed:
        return Colors.red;
      case TestStatus.error:
        return Colors.orange;
    }
  }
}