import 'dart:io';
import 'package:Clarm/admob.dart';
import 'package:Clarm/models/providers.dart';
import 'package:Clarm/theme.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmTile extends ConsumerStatefulWidget {
  const AlarmTile({
    super.key,
    required this.timeToStr,
    required this.label,
    required this.onPressed,
    required this.booleanSwitch,
    this.onDismissed,
  });

  final String timeToStr;
  final String label;
  final bool booleanSwitch;
  final void Function() onPressed;
  final void Function()? onDismissed;

  @override
  AlarmTileState createState() => AlarmTileState();
}

class AlarmTileState extends ConsumerState<AlarmTile> {
  late SharedPreferences sharedPrefs;

  late List<AlarmSettings> alarms;
  int alarmId = 0;
  late AlarmSettings alarmSettings;
  bool booleanSwitch = false;
  bool isVisibleTheNextDay = false;   // [ +1 day ] 표시 결정 boolean
  bool isVisibleClapping = false;   // [ 박수 모드 ] 표시 결정 boolean
  // bool isVisibleRepetition = false;   // [ 반복 ] 표시 결정 boolean

  @override
  void initState() {
    super.initState();

    alarmId = int.parse(widget.key.toString().replaceAll(RegExp('\\D'), ""));
    alarmSettings = Alarm.getAlarm(alarmId)!;
    booleanSwitch = widget.booleanSwitch;

    /// 다음 날 알람이면 -> isVisibleTheNextDay=true
    if(alarmSettings.dateTime.day > DateTime.now().day) {
      isVisibleTheNextDay = true;
    }
    /// 박수 알람 모드 설정했으면 -> isVisibleClapping=true
    if(Platform.isIOS) {
      if(alarmSettings.notificationSettings.body.contains("clap")) {
        isVisibleClapping = true;
      }
    } else {
      if(alarmSettings.assetAudioPath.contains("clap")) {
        isVisibleClapping = true;
      }
    }

    /// Local Directory 에 저장된 value 가져오기 (ex. Dark Mode)
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        sharedPrefs = prefs;
      });
    });

    // /// 알람 반복하기 설정했으면 -> isVisibleRepetition=true
    // if(alarmSettings.notificationBody.contains("repeat")) {
    //   isVisibleRepetition = true;
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: widget.key!,
      direction: widget.onDismissed != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 30),
        child: const Icon(
          Icons.delete,
          size: 30,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => widget.onDismissed?.call(),
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            Opacity(
              opacity: booleanSwitch ? 1.0 : 0.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 40,
                  child: isVisibleClapping ? Image.asset(
                    'assets/icons/clarm_pink.png',
                    fit: BoxFit.fitWidth,
                  ) : const SizedBox.shrink(),
                ),
              ),
            ),
            Expanded(
              child: RawMaterialButton(
                onPressed: widget.onPressed,
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Time (00:00)
                        Opacity(
                          opacity: booleanSwitch ? 1.0 : 0.5,
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.timeToStr,
                              style: TextStyle(
                                fontSize: 50,
                                fontWeight: FontWeight.w400,
                                color: MyTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10, left: 5),
                          child: Column(
                            children: [
                              isVisibleTheNextDay ? const Text(
                                "+1",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.red,
                                ),
                              ) : const SizedBox.shrink(),
                              // isVisibleRepetition ? const Icon(
                              //   Icons.repeat,
                              //   size: 18,
                              //   color: Colors.blueAccent,
                              // ) : const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    /// Label
                    Opacity(
                      opacity: booleanSwitch ? 1.0 : 0.5,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          " ${widget.label}",
                          style: TextStyle(
                            fontSize: 18,
                            color: MyTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Switch Button
            Container(
              width: 100,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.transparent,
              child: FittedBox(
                fit: BoxFit.fitWidth,
                child: Switch(
                  value: booleanSwitch,
                  onChanged: (value) {
                    setState(() => booleanSwitch = value);

                    /// Alarm OFF (booleanSwitch = false)
                    if (!value) {
                      // printGreen("Before : $alarmSettings");
                      AlarmSettings newAlarmSettings = alarmSettings.copyWith(
                        dateTime: alarmSettings.dateTime.add(const Duration(days: 365))
                      );

                      /// 1년 뒤로(newAlarmSettings) 설정
                      alarmSettings = newAlarmSettings;
                      Alarm.set(alarmSettings: alarmSettings);

                      setState(() => isVisibleTheNextDay = false);
                      // printGreen("After : $alarmSettings");
                    }
                    /// Alarm ON (booleanSwitch = true)
                    else {
                      /// ShardPref 의 Count_Of_Switch_On ++
                      sharedPrefs.setInt("Count_Of_Switch_On", sharedPrefs.getInt("Count_Of_Switch_On")!+1);

                      // printGreen("Before : $alarmSettings");
                      DateTime newDateTime = alarmSettings.dateTime.copyWith(
                        year: DateTime.now().year,
                        month: DateTime.now().month,
                        day: DateTime.now().day,
                      );

                      /// 현재 시간 이전일 경우(day 는 같지만 시간이 Before),
                      ///  -> "+1 day"
                      if(newDateTime.isBefore(DateTime.now())) {
                        newDateTime = newDateTime.copyWith(
                          day: newDateTime.day + 1
                        );
                      }

                      AlarmSettings newAlarmSettings = alarmSettings.copyWith(
                        dateTime: newDateTime
                      );

                      /// 초기에 설정한 시간(alarmSettings) + 오늘 날짜(day)로 롤백
                      alarmSettings = newAlarmSettings;

                      /// Switch On 한 것(SharedPrefs)이 n번째가 되면 -> 광고 시청
                      if(sharedPrefs.getInt("Count_Of_Switch_On") == 3) {
                        sharedPrefs.setInt("Count_Of_Switch_On", 0);
                        ref.watch(isAdLoading.notifier).state = true;

                        Admob().adLoadInterstitial(() {
                          Alarm.set(alarmSettings: newAlarmSettings);
                          ref.watch(isAdLoading.notifier).state = false;
                        });
                      } else {
                        Alarm.set(alarmSettings: newAlarmSettings);
                      }

                      // [+1 day] 표기 여부 설정
                      if(newAlarmSettings.dateTime.day > DateTime.now().day) {
                        setState(() => isVisibleTheNextDay = true);
                      } else {
                        setState(() => isVisibleTheNextDay = false);
                      }
                      // printGreen("After : $alarmSettings");
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}