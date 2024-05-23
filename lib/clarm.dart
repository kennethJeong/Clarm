//
import 'dart:async';
import 'dart:io';
import 'package:Clarm/widgets/contact_us.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
//
import 'package:Clarm/custom_icons_icons.dart';
import 'package:Clarm/screens/edit_alarm.dart';
import 'package:Clarm/screens/ring_alarm.dart';
import 'package:Clarm/widgets/alarm_tile.dart';
import 'package:Clarm/theme.dart';
import 'package:Clarm/utils/color_print.dart';
import 'package:Clarm/models/providers.dart';
import 'package:Clarm/utils/audio_process.dart';
//

class Clarm extends ConsumerStatefulWidget {
  final AlarmSettings? alarmSettings;

  const Clarm({
    super.key,
    this.alarmSettings
  });

  @override
  ClarmState createState() => ClarmState();
}

class ClarmState extends ConsumerState<Clarm> {
  late List<AlarmSettings> alarms;

  static StreamSubscription? subscription;

  late SharedPreferences sharedPrefs;

  ///
  ///
  void doAlarm(AlarmSettings alarmSettings) {
    late final String audioSound;
    late final String audioClap;
    const String audioBeep = 'assets/audios/beep.wav';

    Future.wait([
      getRandomAudio("sound").then((randomAudio) {
        audioSound = randomAudio;
      }),
      getRandomAudio("clap").then((randomAudio) {
        audioClap = randomAudio;
        ref.watch(originalClapAssetPath.notifier).state = audioClap;
      }),
    ]).then((_) {
      mergeAudios(audioSound, audioClap, audioBeep).then((audioPath) {
        if(audioPath != '') {
          ref.watch(mergedAudioPath.notifier).state = audioPath;

          /// get audio duration
          final audioPlayer = AudioPlayer();
          audioPlayer.setSourceDeviceFile(audioPath).then((_) {
            audioPlayer.getDuration().then((duration) {
              int durationSeconds;
              duration!.inMilliseconds > 0 ? durationSeconds = duration.inMilliseconds
                  : durationSeconds = 0;

              /// go to RingScreen
              navigateToRingScreen(alarmSettings, durationSeconds);
            });
          });
        } else {
          /// Error - Audio Merge Fail


        }
      });
    });
  }

  @override
  void initState() {
    super.initState();

    loadAlarms();

    subscription ??= Alarm.ringStream.stream.listen((alarmSettings) {
      printRed("SUBSCRIPTION");

      /// 이전에 시작해서 지금 실행 중인 알람이 있다면,
      ///  (알람 ring 2개 동시 발생)
      /// 현재 입력된 알람은 실행하지 않음.(1년 연장.)
      setState(() {
        List<AlarmSettings> savedAlarms = Alarm.getAlarms();
        for(var i=0; i<savedAlarms.length; i++) {    // 저장된 알람 중에,
          AlarmSettings savedAlarm = savedAlarms[i];
          if(savedAlarm != alarmSettings) {     // 지금 알람이 아닌 것 중에,
            Alarm.isRinging(savedAlarm.id).then((isRinging) {
              // 울리고 있c는 알람이 있다면,
              if(isRinging) {
                // '현재 알람' 은 울리지 않음. (1년 연장.)
                Alarm.set(
                  alarmSettings: alarmSettings.copyWith(
                    dateTime: alarmSettings.dateTime.add(const Duration(days: 365))
                  )
                );
              }
              // 울리고있는 알람이 없다면,
              // 알람 진행.
              else {
                doAlarm(alarmSettings);
              }
            });
          } else {
            doAlarm(alarmSettings);
          }
        }
      });
    });

    /// Local Directory 에 저장된 value 가져오기 (ex. Dark Mode)
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        sharedPrefs = prefs;
      });
    });
  }

  void loadAlarms() {
    setState(() {
      alarms = Alarm.getAlarms();
      alarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    });

    if(alarms.isEmpty) {
      printRed("ALARMS is Empty");
    } else {
      for(var i=0; i<alarms.length; i++) {
        AlarmSettings eachAlarm = alarms[i];
        printRed("ALARMS [${i+1}] ==> ID: ${eachAlarm.id} | DateTime: ${eachAlarm.dateTime}"
            " | Options: ${eachAlarm.notificationBody} | Label: ${eachAlarm.notificationTitle}");
      }
    }
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings, int duration) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RingAlarm(
          alarmSettings: alarmSettings,
          duration: duration,
        ),
      ),
    );

    loadAlarms();
  }

  Future<void> navigateToAlarmScreen(AlarmSettings? settings) async {
    final res = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8 - kBottomNavigationBarHeight,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(22.0)
            ),
          ),
          child: EditAlarm(alarmSettings: settings),
        );
      }
    );

    if (res != null && res == true) loadAlarms();
  }

  @override
  void dispose() {
    subscription?.cancel();

    super.dispose();
  }

  Widget iconOfBottomModal(IconData iconData, StateSetter bottomState) {
    final iconSizeOfBottomSheet = MediaQuery.of(context).size.width / 6;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height / 5
      ),
      child: ClipOval(
        child: InkWell(
          onTap: () { },
          child: Container(
            color: Colors.grey,
            width: iconSizeOfBottomSheet,
            height: iconSizeOfBottomSheet,
            child: IconButton(
              onPressed: () async {
                /// Dark Mode
                if(iconData == Icons.dark_mode_rounded) {
                  bottomState(() {
                    setState(() {
                      sharedPrefs.setBool("Dark_Mode", !sharedPrefs.getBool("Dark_Mode")!);
                      ref.watch(isDarkMode.notifier).state = sharedPrefs.getBool("Dark_Mode")!;
                    });
                  });
                }

                /// Set Language
                // else if(iconData == Icons.language) {
                //   print("Language");
                //   showModalBottomSheet(
                //     context: context,
                //     builder: (BuildContext ctx) {
                //       return ClipRRect(
                //         borderRadius: BorderRadius.circular(30),
                //         child: CupertinoPicker(
                //           itemExtent: 50,
                //           onSelectedItemChanged: (i) {
                //             print(listLanguage[i]);
                //           },
                //           useMagnifier: true,
                //           children: [
                //             ...listLanguage.map((e) => Center(
                //               child: SizedBox(
                //                 height: 30,
                //                 child: Text(
                //                   e,
                //                   style: const TextStyle(
                //                     fontSize: 24,
                //                   ),
                //                 ),
                //               ),
                //             ))
                //           ]
                //         ),
                //       );
                //     }
                //   );
                // }

                /// Send Email
                else if(iconData == Icons.mail_outline) {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    enableDrag: true,
                    isDismissible: false,
                    builder: (context) {
                      return Container(
                        height: MediaQuery.of(context).size.height * 0.9,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(15.0)
                          ),
                        ),
                        child: const ContactUs(),
                      );
                    }
                  );
                }

                /// Remove Ads
                else if(iconData == CustomIcons.remove_ads) {
                  printRed("Remove Ads");
                }
              },
              icon: Icon(
                iconData,
                color: (iconData == Icons.dark_mode_rounded && sharedPrefs.getBool("Dark_Mode")!)
                    ? Colors.black : Colors.white,
                size: iconSizeOfBottomSheet * 0.7,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.0)),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          extendBody: true,
          appBar: Platform.isAndroid ? AppBar(
            systemOverlayStyle: SystemUiOverlayStyle(
              systemStatusBarContrastEnforced: false,
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: ref.watch(isDarkMode) ? Brightness.light : Brightness.dark,
            ),
            elevation: 0,
            toolbarHeight: 0,
          ) : null,
          body: alarms.isNotEmpty ? ListView.separated(
            itemCount: alarms.length + 1,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if(index == alarms.length) {
                /// Add a new Alarm
                return Container(
                  height: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: RawMaterialButton(
                    onPressed: () => navigateToAlarmScreen(null),
                    splashColor: Colors.transparent,
                    child: Center(
                      child: Icon(
                        Icons.add_rounded,
                        size: 40,
                        color: MyTheme.primaryColor,
                      ),
                    ),
                  ),
                );
              } else {
                /// Load set Alarms
                bool booleanSwitch = true;
                if(alarms[index].dateTime.year > DateTime.now().year) {
                  booleanSwitch = false;
                }
                /*
                ***
                [Switch OFF] -> 1년 Add
                [Switch ON] -> 1년 Substrate
                ***
                If, 지금보다 1년 이상이다 = Switch OFF 상태 = booleanSwitch=false
                If, 지금보다 1년 이하이다 = Switch ON 상태 = booleanSwitch=true
                ***

                [clarm.dart - 초기화면(리스트뷰)] 에서 알람 데이터 로드할 때]
                  => alarms[index]의 datetime = 1년 이상(+2days 로 판별) --> booleanSwitch=false
                  => alarms[index]의 datetime = 1년 이하 --> booleanSwitch=true
                 */

                return AlarmTile(
                  key: Key(alarms[index].id.toString()),
                  timeToStr: "${alarms[index].dateTime.hour.toString().padLeft(2, '0')}"
                      ":${alarms[index].dateTime.minute.toString().padLeft(2, '0')}",
                  label: alarms[index].notificationTitle.toString(),
                  booleanSwitch: booleanSwitch,
                  onPressed: () => navigateToAlarmScreen(alarms[index]),
                  onDismissed: () {
                    Alarm.stop(alarms[index].id).then((_) => loadAlarms());
                  },
                );
              }
            },
          )
          /// Add a new Alarm
          : RawMaterialButton(
            onPressed: () => navigateToAlarmScreen(null),
            highlightColor: Colors.transparent,
            splashColor: MyTheme.primaryColor.withOpacity(0.5),
            child: Center(
              child: Icon(
                Icons.add_rounded,
                size: 50,
                color: MyTheme.primaryColor,
              ),
            ),
          ),
          floatingActionButton: SpeedDial(
            activeBackgroundColor: MyTheme.primaryColor,
            activeForegroundColor: ref.watch(isDarkMode) ? Colors.black : Colors.white,
            backgroundColor: MyTheme.primaryColor,
            foregroundColor: ref.watch(isDarkMode) ? Colors.black : Colors.white,
            icon: Icons.more_vert,
            activeIcon: Icons.more_horiz,
            useRotationAnimation: true,
            spaceBetweenChildren: 10,
            renderOverlay: true,
            overlayColor: ref.watch(isDarkMode) ? Colors.black : Colors.white,
            buttonSize: const Size(58, 58),
            childrenButtonSize: const Size(55, 58),
            onClose: () {

            },
            children: [
              ///
              /// [ INSTANT ALARM ]
              ///
              SpeedDialChild(
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext ctx) {
                      return AlertDialog(
                        content: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: MediaQuery.of(context).size.height * 0.2,
                          child: Column(
                            children: [
                              Container(
                                height: MediaQuery.of(context).size.height * 0.09,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  size: MediaQuery.of(context).size.width * 0.1,
                                  color: Colors.redAccent,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.contain,
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: "This is a ",
                                              style: Theme.of(context).textTheme.titleMedium!
                                            ),
                                            TextSpan(
                                              text: "Test Alarm",
                                              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ]
                                        ),
                                      ),
                                    ),
                                    const Padding(padding: EdgeInsets.symmetric(vertical: 3)),
                                    Text(
                                      "Loud noise can suddenly occur.",
                                      style: Theme.of(context).textTheme.titleMedium!
                                    ),
                                    Text(
                                      "Do you want to run it ?",
                                      style: Theme.of(context).textTheme.titleMedium!
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        actionsAlignment: MainAxisAlignment.spaceAround,
                        actions: [
                          /// [Test Alarm] 실행 버튼
                          ///  alarmSettins.notificationBody 에 알람 옵션(clap, repeat, test) 설정 값 Load.
                          ///    => String 값을 Load 하기 위한 Key 가 없어서, 부득이하게 사용하지 않는 notificationBody 에 싣기로 결정함.
                          ElevatedButton(
                            onPressed: () {
                              Alarm.set(
                                alarmSettings: AlarmSettings(
                                  id: DateTime.now().millisecondsSinceEpoch % 10000,
                                  dateTime: DateTime.now(),
                                  assetAudioPath: 'assets/audios/empty.wav',
                                  notificationTitle: "ㅤThis is Test Alarm",
                                  notificationBody: 'test/clap/',
                                ),
                              ).then((_) => Navigator.of(context).pop());
                            },
                            child: Text(
                              "Yes",
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                color: MyTheme.primaryColor,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              "No",
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                color: MyTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  );
                },
                backgroundColor: Colors.red,
                child: const Icon(
                  Icons.alarm_add
                )
              ),
              ///
              /// [ SETTING ]
              ///
              SpeedDialChild(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isDismissible: true,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext context) {
                      return StatefulBuilder(builder: (BuildContext context, StateSetter bottomState) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            iconOfBottomModal(Icons.dark_mode_rounded, bottomState),    // 다크 모드
                            iconOfBottomModal(Icons.mail_outline, bottomState),         // 메일 보내기
                            iconOfBottomModal(CustomIcons.remove_ads, bottomState),         // 메일 보내기
                            // iconOfBottomModal(Icons.language, bottomState),             // 언어 설정
                          ],
                        );
                      });
                    }
                  );
                },
                child: const Icon(
                  Icons.settings,
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}