import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:Clarm/models/providers.dart';
import 'package:Clarm/widgets/waveform.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class RingAlarm extends ConsumerStatefulWidget {
  final AlarmSettings alarmSettings;
  final int duration;

  const RingAlarm({
    super.key,
    required this.alarmSettings,
    required this.duration,
  });

  @override
  RingAlarmState createState() => RingAlarmState();
}

class RingAlarmState extends ConsumerState<RingAlarm> {
  late String clapLocalPath = '';
  double viewWidth = 0;
  bool isClap = false;
  bool isTest = false;
  double opacityAlarmOff = 0.0;

  @override
  void initState() {
    super.initState();

    getOriginalClapLocalPath().then((audioPath) {
      clapLocalPath = audioPath;
    });

    Future.delayed(Duration.zero, () {
      viewWidth = MediaQuery.of(context).size.width * 0.95;
    });

    /// 알람 설정값 확인
    isClap = widget.alarmSettings.notificationBody.contains("clap");
    isTest = widget.alarmSettings.notificationBody.contains("test");
  }

  Future<String> getOriginalClapLocalPath() async {
    final localPath = (await getTemporaryDirectory()).path;
    String originalClapAssetFileName = (ref.watch(originalClapAssetPath)).split('/').last;
    String originalClapLocalPath = "$localPath/$originalClapAssetFileName";
    return originalClapLocalPath;
  }

  /// Provider 변수 초기화
  void initProvider() {
    ref.watch(isAudioMatched.notifier).state = false;
    ref.watch(countOfFailedAlarm.notifier).state = 0;
  }

  // void delayByAMinute(AlarmSettings alarmSettings) {
  //   final now = DateTime.now();
  //   Alarm.set(
  //     alarmSettings: alarmSettings.copyWith(
  //       dateTime: DateTime(
  //         now.year,
  //         now.month,
  //         now.day,
  //         now.hour,
  //         now.minute,
  //         0,
  //       ).add(const Duration(minutes: 1)),
  //     ),
  //   ).then((_) {
  //     ref.watch(countOfFailedAlarm.notifier).state = 0;
  //     ref.watch(isAlarmReactivated.notifier).state = true;
  //
  //     Navigator.pop(context, true);
  //   });
  // }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// 알람 종료 성공 -> 메인으로 이동
    if(mounted) {
      if(ref.watch(isAudioMatched)) {
        if(!isTest) {
          Alarm.set(
            alarmSettings: widget.alarmSettings.copyWith(
              dateTime: widget.alarmSettings.dateTime.add(const Duration(days: 365))
            )
          ).then((_) {
            initProvider();
            Navigator.popAndPushNamed(context, '/clarm');
          });
        } else {
          Alarm.stop(widget.alarmSettings.id).then((_) {
            initProvider();
            Navigator.popAndPushNamed(context, '/clarm');
          });
        }
      }

      /// 알람 해제 n번 실패 -> [Alarm Off] 버튼 활성화
      // 일반 알람 -> n=3
      if(!isTest) {
        if(ref.watch(countOfFailedAlarm) == 1) {
          setState(() => opacityAlarmOff = 1.0);
        }
      }
      // Test 모드 -> n=1
      else {
        if(ref.watch(countOfFailedAlarm) == 1) {
          setState(() => opacityAlarmOff = 1.0);
        }
      }
    }

    return PopScope(
      canPop: false,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.0)),
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      widget.alarmSettings.notificationTitle,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontSize: 30,
                      ),
                    ),
                  ),
                ),
                /// [[박수 알람 모드]]
                /// 변수: isClap = true
                Visibility(
                  visible: isClap,
                  child: FutureBuilder(
                    future: getOriginalClapLocalPath(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if(snapshot.hasData == true) {
                        return VideoWaveForms(
                          originAudioFile: File(clapLocalPath),
                          mergedAudioFile: File(ref.watch(mergedAudioPath)),
                          viewWidth: viewWidth,
                          duration: widget.duration,
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    }
                  ),
                ),
                Opacity(
                  opacity: opacityAlarmOff,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: ElevatedButton(
                      onPressed: () {
                        mounted ? ref.watch(isAudioMatched.notifier).state = true : null;
                      },
                      child: const Text(
                        "Alarm Off"
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}