import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// A real device location reading (never fabricated).
class EmergencyLocation {
  final double latitude;
  final double longitude;

  const EmergencyLocation({required this.latitude, required this.longitude});
}

/// Real device-side emergency actions for the SOS flow:
/// - Calling Rescue 1122 through the OS dialer (tel:1122)
/// - Reading the real device GPS position (null when unavailable)
/// - Sharing the patient's emergency location via the OS share sheet
///
/// All actions are honest: failures are reported to the caller and no
/// success is ever simulated locally.
class EmergencyActionsService {
  static final EmergencyActionsService _instance =
      EmergencyActionsService._internal();
  factory EmergencyActionsService() => _instance;
  EmergencyActionsService._internal();

  /// Pakistan national emergency rescue helpline.
  static const String rescue1122PhoneNumber = '1122';

  // ---- Test seams (set only in tests, never in production) ----
  @visibleForTesting
  static Future<bool> Function(Uri uri, LaunchMode mode)? launchUrlOverride;

  @visibleForTesting
  static Future<EmergencyLocation?> Function()? currentLocationOverride;

  @visibleForTesting
  static Future<ShareResult> Function(String text)? shareOverride;

  /// Opens the OS dialer with the Rescue 1122 emergency number.
  ///
  /// Returns true only when the dialer could actually be opened.
  Future<bool> callRescue1122() async {
    final uri = Uri(scheme: 'tel', path: rescue1122PhoneNumber);
    final launcher = launchUrlOverride ?? _launchUrl;
    try {
      return await launcher(uri, LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[EmergencyActionsService] Could not open dialer: $e');
      return false;
    }
  }

  /// Reads the real device location.
  ///
  /// Returns null when location services are off or the permission was
  /// denied — coordinates are never invented.
  Future<EmergencyLocation?> getCurrentLocation() async {
    final provider = currentLocationOverride ?? _readDeviceLocation;
    try {
      return await provider();
    } catch (e) {
      debugPrint('[EmergencyActionsService] Could not read location: $e');
      return null;
    }
  }

  /// Shares the patient's emergency location through the OS share sheet.
  ///
  /// Real GPS coordinates are included when available; otherwise the share
  /// text honestly states that the live location could not be determined.
  /// Returns true when the share sheet could be opened.
  Future<bool> shareEmergencyLocation({
    required String patientName,
    String? city,
    String? symptoms,
    EmergencyLocation? location,
  }) async {
    final text = buildEmergencyLocationShareText(
      patientName: patientName,
      city: city,
      symptoms: symptoms,
      location: location,
    );

    final sharer = shareOverride ?? _shareText;
    try {
      await sharer(text);
      return true;
    } catch (e) {
      debugPrint('[EmergencyActionsService] Could not share location: $e');
      return false;
    }
  }

  /// Builds the emergency location share text (pure & testable).
  static String buildEmergencyLocationShareText({
    required String patientName,
    String? city,
    String? symptoms,
    EmergencyLocation? location,
  }) {
    final buffer = StringBuffer()
      ..writeln('🚨 EMERGENCY — SehatAI Pakistan patient needs help')
      ..writeln('Patient: $patientName');

    if (city != null && city.trim().isNotEmpty) {
      buffer.writeln('City: ${city.trim()}');
    }
    if (symptoms != null && symptoms.trim().isNotEmpty) {
      buffer.writeln('Reported symptoms: ${symptoms.trim()}');
    }

    if (location != null) {
      buffer
        ..writeln(
            'Live GPS: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}')
        ..writeln(
            'Map: https://maps.google.com/?q=${location.latitude},${location.longitude}');
    } else {
      buffer.writeln(
          'Live GPS: unavailable (location permission denied or GPS is off)');
    }

    buffer
      ..writeln()
      ..writeln('Please contact Rescue 1122 if immediate help is needed.');
    return buffer.toString();
  }

  Future<bool> _launchUrl(Uri uri, LaunchMode mode) {
    return launchUrl(uri, mode: mode);
  }

  Future<EmergencyLocation?> _readDeviceLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return EmergencyLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<ShareResult> _shareText(String text) {
    return SharePlus.instance.share(ShareParams(text: text));
  }
}
