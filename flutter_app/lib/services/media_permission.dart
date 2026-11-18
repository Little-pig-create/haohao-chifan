import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum MediaAccessKind { camera, gallery }

/// 在打开相机或系统相册前申请对应权限。
Future<bool> ensureMediaAccess(MediaAccessKind kind) async {
  if (kIsWeb) return true;
  if (kind == MediaAccessKind.camera) {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  final photos = await Permission.photos.request();
  if (photos.isGranted || photos.isLimited) return true;

  if (defaultTargetPlatform == TargetPlatform.android) {
    final storage = await Permission.storage.request();
    if (storage.isGranted || storage.isLimited) return true;
  }
  return false;
}

/// 权限被拒绝时给出「取消 / 去设置」，用户确认后直接跳到系统应用设置。
Future<void> showMediaPermissionPrompt(
  BuildContext context, {
  required MediaAccessKind kind,
}) async {
  final goSettings = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final gallery = kind == MediaAccessKind.gallery;
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 6),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Text(
          gallery ? '需要相册权限' : '需要相机权限',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          gallery
              ? '允许访问相册后，才能选择餐盘照片进行识别。\n如果之前拒绝过，请到系统设置里打开权限。'
              : '允许使用相机后，才能拍摄餐盘进行识别。\n如果之前拒绝过，请到系统设置里打开权限。',
          style: const TextStyle(
            fontSize: 12,
            height: 1.6,
            color: Color(0xFF6E786F),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF17211A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('去设置'),
          ),
        ],
      );
    },
  );
  if (goSettings == true) {
    await openAppSettings();
  }
}
