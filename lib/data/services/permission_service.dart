import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Requests Camera and Photos/Storage permissions at startup.
  static Future<void> requestInitialPermissions() async {
    // We request Camera, Photos, and Notification permissions.
    await [
      Permission.camera,
      Permission.photos,
      Permission.notification,
    ].request();

    // Request Exact Alarm permission for Android 14+
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    // Specific handling for Android < 13 storage if needed
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
  }

  /// Checks if gallery permission is granted.
  static Future<bool> isGalleryGranted() async {
    return await Permission.photos.isGranted || await Permission.storage.isGranted;
  }
}
