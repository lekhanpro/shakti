import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Permissions requested during onboarding, in order.
enum AppPermission { location, sms, microphone, notifications }

enum PermissionOutcome { granted, denied, permanentlyDenied }

/// Thin seam over permission_handler so onboarding can be tested with a fake.
/// This file is the only place in the features layer that imports the plugin.
abstract interface class PermissionGateway {
  Future<PermissionOutcome> status(AppPermission p);
  Future<PermissionOutcome> request(AppPermission p);
  Future<void> openSettings();
}

class PluginPermissionGateway implements PermissionGateway {
  const PluginPermissionGateway();

  static ph.Permission _map(AppPermission p) => switch (p) {
        AppPermission.location => ph.Permission.location,
        AppPermission.sms => ph.Permission.sms,
        AppPermission.microphone => ph.Permission.microphone,
        AppPermission.notifications => ph.Permission.notification,
      };

  static PermissionOutcome _outcome(ph.PermissionStatus s) => s.isGranted || s.isLimited
      ? PermissionOutcome.granted
      : s.isPermanentlyDenied
          ? PermissionOutcome.permanentlyDenied
          : PermissionOutcome.denied;

  @override
  Future<PermissionOutcome> status(AppPermission p) async {
    try {
      return _outcome(await _map(p).status);
    } catch (_) {
      return PermissionOutcome.denied;
    }
  }

  @override
  Future<PermissionOutcome> request(AppPermission p) async {
    try {
      return _outcome(await _map(p).request());
    } catch (_) {
      return PermissionOutcome.denied;
    }
  }

  @override
  Future<void> openSettings() async {
    try {
      await ph.openAppSettings();
    } catch (_) {}
  }
}

final permissionGatewayProvider = Provider<PermissionGateway>((_) => const PluginPermissionGateway());
