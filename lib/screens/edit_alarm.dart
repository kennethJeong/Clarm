import 'dart:async';
import 'dart:io';
import 'package:Clarm/models/providers.dart';
import 'package:Clarm/theme.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

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
  late bool vibrate;
  late double volume;
  String label = '';
  bool doClap = false;
  // bool doRepeat = false;
  String alarmVariables = '';
  FocusNode focusNodeLabel = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _animation;
  bool visibleShowPicker = true;
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
      vibrate = true;
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
      vibrate = widget.alarmSettings!.vibrate;
      volume = widget.alarmSettings!.volume!;
      doClap = widget.alarmSettings!.notificationBody.contains('clap') ? true : false;
      // doRepeat = widget.alarmSettings!.assetAudioPath.contains('repeat') ? true : false;
    }

    /// Label 의 focus On -> (Keyboard Open 으로 인한) showPicker 위젯의
    ///  Size & Scale transition 애니메이션 컨트롤러
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = Tween(begin: 1.0, end: 0.1).animate(_animationController);

    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription = keyboardVisibilityController.onChange.listen((bool visible) {
      if(visible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  showSnackBar(context, bool isForEditing, DateTime dateTime) {
    late String comments;
    late Color color;
    DateTime now = DateTime.now().subtract(const Duration(minutes: 1));
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
        alignment: Alignment.centerLeft,
        child: Text(
          comments,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontSize: MediaQuery.of(context).size.width * 0.04,
            color: Colors.white,
          ),
        ),
      ),
      elevation: 10,
      actionOverflowThreshold: 0,
      dismissDirection: DismissDirection.up,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(
        bottom: 20,
        left: 10,
        right: 10
      ),
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15)
      ),
      backgroundColor: color.withOpacity(0.9),
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
    // Clap or not
    doClap ? alarmVariables += 'clap/' : null;
    // Repeat or not
    // doRepeat ? alarmVariables += 'repeat/' : null;
    ///

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      vibrate: vibrate,
      volume: volume,
      notificationTitle: "ㅤ$label",
      notificationBody: alarmVariables,
      assetAudioPath: "assets/audios/empty.wav",
    );

    return alarmSettings;
  }

  void saveAlarm() {
    AlarmSettings newAlarmSetting = buildAlarmSettings();

    showSnackBar(context, true, newAlarmSetting.dateTime);

    Alarm.set(alarmSettings: newAlarmSetting).then((res) {
      if (res) {
        Navigator.popAndPushNamed(context, '/clarm');
      }
    });
  }

  void deleteAlarm() {
    showSnackBar(context, false, widget.alarmSettings!.dateTime);

    Alarm.stop(widget.alarmSettings!.id).then((res) {
      if (res) Navigator.popAndPushNamed(context, '/clarm');
    });
  }

  @override
  void dispose() {
    focusNodeLabel.dispose();
    _animationController.dispose();
    keyboardSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              Container(
                height: 50,
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
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: saveAlarm,
                      child: Text(
                        "Save",
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: Colors.lightBlue,
                          fontWeight: FontWeight.w400,
                        )
                      ),
                    ),
                  ],
                ),
              ),

              ///
              /// 시간 & 분 선택 Animation Picker
              Flexible(
                flex: 2,
                child: SizeTransition(
                  sizeFactor: _animation,
                  axisAlignment: 1.0,
                  child: ScaleTransition(
                    scale: _animation,
                    child: showPicker(
                      isInlinePicker: true,
                      isOnChangeValueMode: true,
                      elevation: 0,
                      hideButtons: true,
                      disableAutoFocusToNextInput: true,
                      width: double.infinity,
                      height: 350,
                      // height: MediaQuery.of(context).size.height * 0.5,
                      dialogInsetPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
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
              ),

              /// Alarm Options
              /// ///
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 0, left: 25, right: 25),
                  child: Column(
                    children: [
                      /// Set Clapping
                      SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Clap',
                              style: Theme.of(context).textTheme.bodyMedium,
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
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Vibrate',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            FittedBox(
                              fit: BoxFit.fill,
                              child: Switch(
                                value: vibrate,
                                onChanged: (value) {
                                  focusNodeLabel.unfocus();
                                  setState(() => vibrate = value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// Label
                      SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Label ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 15),
                            ),
                            Expanded(
                              child: TextField(
                                focusNode: focusNodeLabel,
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'Alarm',
                                  hintTextDirection: TextDirection.rtl,
                                  focusColor: null,
                                  floatingLabelBehavior: FloatingLabelBehavior.never,
                                  contentPadding: EdgeInsets.only(right: 5),
                                  focusedBorder: InputBorder.none,
                                ),
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: MyTheme.primaryColor,
                                ),
                                textDirection: TextDirection.rtl,
                                maxLines: 1,
                                autofocus: false,
                                keyboardType: TextInputType.text,
                                keyboardAppearance: !ref.watch(isDarkMode) ? Brightness.light : Brightness.dark,
                                onTap: () {
                                  _animationController.forward();
                                },
                                onTapOutside: (_) {
                                  _animationController.reverse();
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
        ),
      ),
    );
  }
}
