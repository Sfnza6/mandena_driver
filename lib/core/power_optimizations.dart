import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PowerOptimizations {
  static const _keyShown = 'bg_power_tip_shown';

  static Future<void> maybePromptOnce() async {
    if (!Platform.isAndroid) return;
    final box = GetStorage();
    if (box.read(_keyShown) == true) return;
    await _showDialog();
    box.write(_keyShown, true);
  }

  static Future<void> showDialogAlways() => _showDialog();

  static Future<void> _showDialog() async {
    if (!Platform.isAndroid) return;
    return Get.dialog(
      AlertDialog(
        title: const Text('تشغيل في الخلفية (مهم للسائق)'),
        content: const Text(
          'لتستمر مشاركة موقعك حتى بعد الخروج من التطبيق:\n'
          '1️⃣ اجعل موفّر البطارية للتطبيق "بدون قيود".\n'
          '2️⃣ إن وُجد تشغيل تلقائي (Autostart) فعّله.\n'
          '3️⃣ الموقع الجغرافي: مسموح طوال الوقت.\n\n'
          'اختر الإعداد الذي تريد فتحه يدويًا:'
        ),
        actions: [
          TextButton(
            onPressed: () async => _openAppDetails(),
            child: const Text('إعدادات التطبيق'),
          ),
          TextButton(
            onPressed: () async => _openAutoStartIfAvailable(),
            child: const Text('تشغيل تلقائي (Autostart)'),
          ),
          TextButton(onPressed: () => Get.back(), child: const Text('تم')),
        ],
      ),
      barrierDismissible: true,
    );
  }

  static Future<void> _openAppDetails() async {
    try {
      final pkg = (await PackageInfo.fromPlatform()).packageName;
      final intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:$pkg',
        flags: <int>[0x10000000], // NEW_TASK
      );
      await intent.launch();
    } catch (_) {}
  }

  static Future<void> _openAutoStartIfAvailable() async {
    final intents = <AndroidIntent>[
      AndroidIntent(
        package: 'com.miui.securitycenter',
        componentName:
            'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
        flags: <int>[0x10000000],
      ),
      AndroidIntent(
        package: 'com.miui.powerkeeper',
        componentName:
            'com.miui.powerkeeper/com.miui.powerkeeper.ui.PowerHideModeActivity',
        flags: <int>[0x10000000],
      ),
      AndroidIntent(
        package: 'com.miui.powerkeeper',
        componentName:
            'com.miui.powerkeeper/com.miui.powerkeeper.ui.HiddenAppsContainerManagement',
        flags: <int>[0x10000000],
      ),
    ];

    for (final i in intents) {
      try {
        await i.launch();
        return;
      } catch (_) {/* جرّب التالي */}
    }

    await _openAppDetails();
  }
}
