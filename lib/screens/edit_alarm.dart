import 'dart:async';
import 'dart:io';
import 'package:Clarm/admob.dart';
import 'package:Clarm/models/providers.dart';
import 'package:Clarm/theme.dart';
import 'package:alarm/alarm.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditAlarm extends ConsumerStatefulWidget {
  final AlarmSettings? alarmSettings;

  const EditAlarm({super.key, this.alarmSettings});

  @override
  EditAlarmState createState() => EditAlarmState();
}

class EditAlarmState extends ConsumerState<EditAlarm> with SingleTickerProviderStateMixin {
  late bool creating;
  late TimeOfDay selectedTime;
  late bool loopAudio;
  late double volume;
  String label = '';
  bool doClap = true;
  bool doVibrate = true;
  String alarmVariables = '';
  FocusNode focusNodeLabel = FocusNode();
  bool hasKeyboardOpen = false;
  late StreamSubscription<bool> keyboardSubscription;

  @override
  void initState() {
    super.initState();

    creating = widget.alarmSettings == null;

    /// alarmSettings 값 설정 - 알람 '생성'
    ///
    if (creating) {
      final dt = DateTime.now().add(const Duration(minutes: 1));
      selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      volume = 1.0;
      doClap = true;
      // doRepeat = false;
    }
    /// alarmSettings 값 설정 - 기존 알람 '수정'
    ///
    else {
      selectedTime = TimeOfDay(
        hour: widget.alarmSettings!.dateTime.hour,
        minute: widget.alarmSettings!.dateTime.minute,
      );
      volume = widget.alarmSettings!.volume!;
      if(Platform.isIOS) {
        doVibrate = widget.alarmSettings!.notificationSettings.body.contains('vib') ? true : false;
        doClap = widget.alarmSettings!.notificationSettings.body.contains('clap') ? true : false;
      } else {
        doVibrate = widget.alarmSettings!.assetAudioPath.contains('vib') ? true : false;
        doClap = widget.alarmSettings!.assetAudioPath.contains('clap') ? true : false;
      }
    }

    /// Label 의 focus On(=Keyboard Open 으로 인한) -> showPicker 의 height 변경
    ///
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription = keyboardVisibilityController.onChange.listen((bool visible) {
      if(visible) {
        hasKeyboardOpen = true;
      } else {
        hasKeyboardOpen = false;
      }
    });
  }

  showSnackBar(context, bool isForEditing, DateTime dateTime) {
    late String comments;
    late Color color;
    DateTime now = DateTime.now().subtract(const Duration(minutes: 2));
    int diffHour = dateTime.difference(now).inHours;
    int diffMin = dateTime.difference(now).inMinutes % 60;

    /// For Save or Edit
    if(isForEditing) {
      color = MyTheme.primaryColor;
      if(dateTime.difference(now) >= const Duration(hours: 1)) {
        if(diffMin != 0) {
          comments = "The alarm will go off in ${diffHour}h and ${diffMin}m.";
        } else {
          comments = "The alarm will go off in ${diffHour}h.";
        }
      } else {
        comments = "The alarm will go off in ${diffMin}m.";
      }
    }
    /// For Delete
    else {
      color = Colors.red;
      comments = "The alarm set at ${dateTime.hour}:${dateTime.minute} has been deleted.";
    }

    SnackBar snackBar = SnackBar(
      content: Container(
        height: MediaQuery.of(context).size.height * 0.03,
        alignment: Alignment.center,
        child: Center(
          child: Text(
            comments,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: MediaQuery.of(context).size.width * 0.04,
              color: Colors.white,
            ),
          ),
        ),
      ),
      elevation: 10,
      actionOverflowThreshold: 0,
      dismissDirection: DismissDirection.up,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(
        bottom: 20,
        left: 30,
        right: 30
      ),
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15)
      ),
      backgroundColor: color.withOpacity(0.6),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> pickTime() async {
    final res = await showTimePicker(
      initialTime: selectedTime,
      context: context,
    );
    if (res != null) setState(() => selectedTime = res);
  }

  AlarmSettings buildAlarmSettings() {
    final now = DateTime.now();
    final id = creating
        ? DateTime.now().millisecondsSinceEpoch % 100000
        : widget.alarmSettings!.id;

    setState(() {
      selectedTime = selectedTime;
    });

    DateTime dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
      0,
      0,
    );

    if (dateTime.isBefore(DateTime.now())) {
      dateTime = dateTime.add(const Duration(days: 1));
    }

    /// Alarm Options
    ///
    // Vibration or not
    doVibrate ? alarmVariables += 'vib/' : null;
    // Clap or not
    doClap ? alarmVariables += 'clap/' : null;
    // Repeat or not
    // doRepeat ? alarmVariables += 'repeat/' : null;
    ///

    late AlarmSettings alarmSettings;
    if(Platform.isIOS) {
      alarmSettings = AlarmSettings(
        id: id,
        dateTime: dateTime,
        vibrate: false,
        volume: volume,
        notificationSettings: NotificationSettings(
          title: "ㅤ$label",
          body: alarmVariables,
        ),
        assetAudioPath: "assets/audios/empty.wav",
      );
    } else {
      alarmSettings = AlarmSettings(
        id: id,
        dateTime: dateTime,
        vibrate: false,
        volume: volume,
        notificationSettings: NotificationSettings(
          title: "ㅤ$label",
          body: '',
        ),
        assetAudioPath: alarmVariables,
      );
    }

    return alarmSettings;
  }

  void saveAlarm() {
    AlarmSettings newAlarmSetting = buildAlarmSettings();

    showSnackBar(context, true, newAlarmSetting.dateTime);

    Alarm.set(alarmSettings: newAlarmSetting).then((res) {
      if (res) {
        if (!mounted) return;
        Navigator.popAndPushNamed(context, '/clarm');
      }
    });
  }

  void deleteAlarm() {
    showSnackBar(context, false, widget.alarmSettings!.dateTime);

    Alarm.stop(widget.alarmSettings!.id).then((res) {
      if (!mounted) return;
      if (res) Navigator.popAndPushNamed(context, '/clarm');
    });
  }

  @override
  void dispose() {
    focusNodeLabel.dispose();
    keyboardSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);

    return MediaQuery(
      data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: InkWell(
          splashColor: Colors.transparent,
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    height: 50.w,
                    padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            "Cancel",
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Colors.lightBlue,
                              fontWeight: FontWeight.w400,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.watch(isAdLoading.notifier).state = true;
                            /// Admob ///
                            Admob().adLoadInterstitial(() {
                              saveAlarm();
                              ref.watch(isAdLoading.notifier).state = false;
                            });
                          },
                          child: Text(
                            "Save",
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Colors.lightBlue,
                              fontWeight: FontWeight.w400,
                              fontSize: 16.sp,
                            )
                          ),
                        ),
                      ],
                    ),
                  ),

                  ///
                  /// 시간 & 분 선택 Animation Picker
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: hasKeyboardOpen ? 0 : 370,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: showPicker(
                        isInlinePicker: true,
                        isOnChangeValueMode: true,
                        elevation: 0,
                        hideButtons: true,
                        disableAutoFocusToNextInput: true,
                        width: double.infinity,
                        wheelMagnification: 1.3,
                        wheelHeight: 180,
                        height: 200,
                        dialogInsetPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
                        contentPadding: EdgeInsets.zero,
                        accentColor: MyTheme.primaryColor,
                        unselectedColor: MyTheme.primaryColor.withOpacity(0.5),
                        value: Time(
                          hour: selectedTime.hour,
                          minute: selectedTime.minute,
                          second: DateTime.now().second
                        ),
                        minuteInterval: TimePickerInterval.ONE,
                        iosStylePicker: Platform.isIOS ? true : false,
                        is24HrFormat: true,
                        themeData: !ref.watch(isDarkMode) ? MyTheme.themeDefaultShowPicker
                          : MyTheme.themeDarkModeShowPicker,
                        // hmsStyle: TextStyle(
                        //   fontSize: 20,
                        //   color: MyTheme.primaryColor
                        // ),
                        onChange: (Time newTime) {
                          setState(() {
                            selectedTime = TimeOfDay(
                              hour: newTime.hour,
                              minute: newTime.minute
                            );
                          });
                        },
                      ),
                    ),
                  ),

                  /// Alarm Options
                  ///
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0, left: 25, right: 25),
                      child: Column(
                        children: [
                          /// Set Clapping
                          SizedBox(
                            height: 40.w,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Clap',
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 15.sp,
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.fill,
                                  child: Switch(
                                    value: doClap,
                                    onChanged: (value) {
                                      focusNodeLabel.unfocus();
                                      setState(() => doClap = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// Set Vibration
                          SizedBox(
                            height: 40.w,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Vibrate',
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 15.sp,
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.fill,
                                  child: Switch(
                                    value: doVibrate,
                                    onChanged: (value) {
                                      focusNodeLabel.unfocus();
                                      setState(() => doVibrate = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// Label
                          SizedBox(
                            height: 40.w,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Label ',
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 15.sp,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 15),
                                ),
                                Expanded(
                                  child: TextField(
                                    focusNode: focusNodeLabel,
                                    decoration: InputDecoration(
                                      isCollapsed: true,
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: 'Alarm',
                                      hintTextDirection: TextDirection.rtl,
                                      floatingLabelBehavior: FloatingLabelBehavior.never,
                                      contentPadding: const EdgeInsets.only(right: 5),
                                      focusColor: null,
                                      focusedBorder: InputBorder.none,
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15.sp,
                                      )
                                    ),
                                    cursorWidth: 0,
                                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      fontSize: 15.sp,
                                      color: MyTheme.primaryColor,
                                    ),
                                    textDirection: TextDirection.rtl,
                                    maxLines: 1,
                                    autofocus: false,
                                    keyboardType: TextInputType.text,
                                    keyboardAppearance: !ref.watch(isDarkMode) ? Brightness.light : Brightness.dark,
                                    onTap: () {
                                      hasKeyboardOpen = true;
                                    },
                                    onTapOutside: (_) {
                                      hasKeyboardOpen = false;
                                    },
                                    onChanged: (text) {
                                      setState(() {
                                        label = text;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// Set Repetition per 1 minute
                          // SizedBox(
                          //   height: 40,
                          //   child: Row(
                          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //     children: [
                          //       Text(
                          //         'Repeat (1 min)',
                          //         style: Theme.of(context).textTheme.bodyMedium,
                          //       ),
                          //       FittedBox(
                          //         fit: BoxFit.fill,
                          //         child: Switch(
                          //           value: doRepeat,
                          //           onChanged: (value) {
                          //             focusNodeLabel.unfocus();
                          //             setState(() => doRepeat = value);
                          //           },
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          !creating ? Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: TextButton(
                                onPressed: deleteAlarm,
                                child: Text(
                                  'Delete',
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ) : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ref.watch(isAdLoading)
                  ? const Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: CircularProgressIndicator(),
                        )
                      ),
                    ],
                  )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
