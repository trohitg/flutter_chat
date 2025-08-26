import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static PermissionService? _instance;
  static PermissionService get instance {
    _instance ??= PermissionService._internal();
    return _instance!;
  }
  
  PermissionService._internal();
  
  // Check if all required permissions are granted
  Future<bool> checkAllPermissions() async {
    final permissions = [
      Permission.notification,
      Permission.systemAlertWindow,
    ];
    
    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        return false;
      }
    }
    
    return true;
  }
  
  // Request overlay permission with user-friendly dialog
  Future<bool> requestOverlayPermission(BuildContext context) async {
    final status = await Permission.systemAlertWindow.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (!context.mounted) return false;
    
    if (status.isDenied) {
      return await _showPermissionDialog(
        context,
        'Chat Bubble Permission',
        'To display the chat bubble over other apps, please grant the "Display over other apps" permission.',
        Permission.systemAlertWindow,
      );
    }
    
    if (status.isPermanentlyDenied) {
      return await _showSettingsDialog(
        context,
        'Permission Required',
        'Chat bubble permission was denied. Please enable it manually in Settings → Apps → Ask Genie → Display over other apps.',
      );
    }
    
    return false;
  }
  
  // Request notification permission
  Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (!context.mounted) return false;
    
    if (status.isDenied) {
      return await _showPermissionDialog(
        context,
        'Notification Permission',
        'Allow notifications to receive important updates and chat responses.',
        Permission.notification,
      );
    }
    
    if (status.isPermanentlyDenied) {
      return await _showSettingsDialog(
        context,
        'Notification Permission Required',
        'Notification permission was denied. Please enable it manually in Settings → Apps → Ask Genie → Notifications.',
      );
    }
    
    return false;
  }
  
  // Show permission request dialog with rationale
  Future<bool> _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    Permission permission,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.security,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    );
    
    if (result == true) {
      final status = await permission.request();
      return status.isGranted;
    }
    
    return false;
  }
  
  // Show settings dialog for permanently denied permissions
  Future<bool> _showSettingsDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
    
    if (result == true) {
      await openAppSettings();
      return false; // User needs to manually enable and return to app
    }
    
    return false;
  }
  
  // Check specific permission status
  Future<PermissionStatus> getPermissionStatus(Permission permission) async {
    return await permission.status;
  }
  
  // Get permission status with detailed info
  Future<Map<String, dynamic>> getDetailedPermissionStatus() async {
    final permissions = {
      'overlay': Permission.systemAlertWindow,
      'notification': Permission.notification,
    };
    
    final result = <String, dynamic>{};
    
    for (final entry in permissions.entries) {
      final status = await entry.value.status;
      result[entry.key] = {
        'granted': status.isGranted,
        'denied': status.isDenied,
        'permanentlyDenied': status.isPermanentlyDenied,
        'restricted': status.isRestricted,
        'status': status.toString(),
      };
    }
    
    return result;
  }
}