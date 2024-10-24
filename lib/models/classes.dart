
import 'package:alarm/alarm.dart';

class AlarmSet {
  final bool isTest;
  final bool isClap;
  AlarmSettings alarmSettings = AlarmSettings(
    id: 0,
    dateTime: DateTime.now(),
    vibrate: false,
    volume: 0,
    notificationSettings: const NotificationSettings(
      title: "",
      body: "",
    ),
    assetAudioPath: "",
  );

  AlarmSet({
    required this.isTest,
    required this.isClap,
    required this.alarmSettings
  });
}