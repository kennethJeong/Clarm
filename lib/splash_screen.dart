import 'dart:io';
import 'package:Clarm/clarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key
  });

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends ConsumerState<SplashScreen> with WidgetsBindingObserver {
  late double screenHeight;
  late double screenWidth;
  late double bottomHeight;
  late int timerCount;
  late String iconFile;
  late SharedPreferences sharedPrefs;

  /// showDialog -> 권한에 관한 설명문
  Future<void> showDialogPermission() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text("Please allow [Microphone] and [Notification] permissions so that the alarm can function properly."),
                )
              ],
            ),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    );
  }

  /// showDialog -> 권한 설정을 위해 App Setting 으로 이동
  Future<void> showDialogOpenAppSetting(String text) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(text)
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  openAppSettings();    // 앱 설정으로 이동
                  SystemNavigator.pop();    // 앱 종료
                },
                child: const Text('Go App Setting')
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> checkPermissions() async {
    /// 권한 여부 확인
    await [
      Permission.microphone,
      Permission.notification,
      Permission.storage,
      Permission.scheduleExactAlarm,
    ].request().then((_) async {
      /// All allowed
      if(await Permission.microphone.isGranted && await Permission.notification.isGranted) {
        // Move to Main Screen (-> Clarm)
        Future.delayed(Duration(milliseconds: timerCount), () {
          if(mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const Clarm(),
              ),
            );
          }
        });
      }
      // Some were not allowed
      else {
        /// Force terminated && Move to App Setting
        showDialogPermission().then((_) async {   // 권한에 관한 설명문
          if(await Permission.microphone.isDenied || await Permission.microphone.isPermanentlyDenied) {
            showDialogOpenAppSetting('Please set the [Microphone] permission in setting');
          }
          if(await Permission.notification.isDenied || await Permission.notification.isPermanentlyDenied) {
            showDialogOpenAppSetting('Please set the [Notification] permission in setting');
          }
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();

    bottomHeight = 50.0;
    timerCount = 3000;
    iconFile = 'clarm_black.png';

    SystemChannels.textInput.invokeMethod('TextInput.hide');

    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        sharedPrefs = prefs;
      });
    });

    checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Platform.isAndroid ? AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          systemStatusBarContrastEnforced: false,
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        elevation: 0,
        toolbarHeight: 0,
      ) : null,
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Image(
                  fit: BoxFit.fill,
                  image: AssetImage(
                    "assets/icons/$iconFile"
                  ),
                ),
              ),
            ),
            Container(
              height: bottomHeight,
              alignment: Alignment.topCenter,
              child: Text(
                "© Copyright 2024, Clarm",
                style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                  color: Colors.white
                ),
              )
            ),
          ],
        ),
      ),
    );
  }
}