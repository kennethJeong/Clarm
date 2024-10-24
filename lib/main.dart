//
import 'package:Clarm/models/providers.dart';
import 'package:Clarm/splash_screen.dart';
import 'package:Clarm/theme.dart';
import 'package:Clarm/clarm.dart';
import 'package:Clarm/utils/color_print.dart';
import 'package:Clarm/utils/notification.dart';
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:screen_corners/screen_corners.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//
import 'package:alarm/alarm.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
  await SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
    Future.delayed(const Duration(seconds: 1), () {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    });
  });

  /// init Alarm
  await Alarm.init(showDebugLogs: false);
  /// init Local Notification
  await FlutterLocalNotification.init();
  /// init Admob
  await MobileAds.instance.initialize();
  /// init Screen Corners
  // await ScreenCorners.initScreenCorners();

  // 앱 강제 종료 시 알람이 제대로 작동하지 않기 때문에 -> Warning Notification
  // await Alarm.setNotificationOnAppKillContent(
  //   '‼️Clarm ‼️',
  //   "Please keep the Alarm on. Otherwise, the alarm will not go off.",
  // );
  Alarm.setWarningNotificationOnKill(
    '‼️Clarm ‼️',
    "Please keep the Alarm on. Otherwise, the alarm will not go off."
  );

  runApp(
    const ProviderScope(
      child: Main(),
    ),
  );
}

class Main extends ConsumerStatefulWidget {
  const Main({super.key});

  @override
  MainState createState() => MainState();
}

class MainState extends ConsumerState<Main> with WidgetsBindingObserver {
  late final AppLifecycleListener appLifecycleListener;   // 앱의 상태를 수신하는 Listener

  /// 기기 내부에 key-value 저장
  /// + Provider 설정 (ShardPref 는 await 가 필요 -> initiate 될 때 사용 불가 !!)
  void setPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? firstTime = prefs.getBool('The_First');

    /// 처음 사용자
    if (firstTime == null) {
      prefs.setBool('The_First', true);
      prefs.setBool('Dark_Mode', false);
      prefs.setInt('Count_Of_Switch_On', 0);
      ref.watch(isDarkMode.notifier).state = false;
    }
    /// 기존 사용자
    else {
      ref.watch(isDarkMode.notifier).state = prefs.getBool('Dark_Mode')!;
    }
  }

  void showWarningNotification() {
    FlutterLocalNotification.showNotification(
      '‼️Clarm ‼️',
      "Please keep the Alarm on. Otherwise, the alarm will not go off.",
    );
  }

  @override
  void initState() {
    super.initState();

    setPreferences();   // initiate 'Shared Preferences'

    /// 앱의 상태에 따라 Local Notification 작동.
    ///
    appLifecycleListener = AppLifecycleListener(
      onResume: () {
        printGreen("APP RESUMED");
        FlutterLocalNotification.cancelAllNotification();
      },
      onRestart: () {
        printGreen("APP RESTARTED");
        FlutterLocalNotification.cancelAllNotification();
      },
      onInactive: () {
        printRed("APP INACTIVED");
        // showWarningNotification();
      },
      onDetach: () {
        printRed("APP DETACHED");
        showWarningNotification();
      },
      onPause: () {
        printRed("APP PAUSED");
        if(!ref.watch(isAdLoading)) {
          showWarningNotification();
        }
      },
      onHide: () {
        printRed("APP HIDED");
        if(!ref.watch(isAdLoading)) {
          showWarningNotification();
        }
      },
    );
  }

  @override
  void dispose() {
    appLifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: null,
      routes: <String, WidgetBuilder> {
        '/clarm' : (BuildContext context) => const Clarm(),
      },
      home: const PopScope(  // AOS 의 하단 뒤로가기 버튼 방지
        canPop: false,
        child: SplashScreen(),
      ),
      theme: ref.watch(isDarkMode) ? MyTheme.themeDarkMode : MyTheme.themeDefault,
      // darkTheme: ThemeData.dark(),
    );
  }
}

