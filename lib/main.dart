//
import 'package:Clarm/models/providers.dart';
import 'package:Clarm/splash_screen.dart';
import 'package:Clarm/theme.dart';
import 'package:Clarm/clarm.dart';
import 'package:Clarm/utils/color_print.dart';
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//
import 'package:alarm/alarm.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
  SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
    Future.delayed(const Duration(seconds: 1), () {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    });
  });

  await Alarm.init(showDebugLogs: false);

  // 앱 강제 종료 시 알람이 제대로 작동하지 않기 때문에 -> Warning Notification
  // await Alarm.setNotificationOnAppKillContent("[WARNING] Clarm", "Please keep the Alarm on. Otherwise, the alarm will not go off.");

  runApp(
    const ProviderScope(
      child: Main(),
      // child: Test(),
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
  final FlutterLocalNotificationsPlugin localNotification = FlutterLocalNotificationsPlugin();

  /// 기기 내부에 key-value 저장
  /// + Provider 설정 (ShardPref 는 await 가 필요 -> initiate 될 때 사용 불가 !!)
  void setPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? firstTime = prefs.getBool('The_First');

    /// 처음 사용자
    if (firstTime == null) {
      prefs.setBool('The_First', true);
      prefs.setBool('Dark_Mode', false);
      ref.watch(isDarkMode.notifier).state = false;
    }
    /// 기존 사용자
    else {
      ref.watch(isDarkMode.notifier).state = prefs.getBool('Dark_Mode')!;
    }
  }

  /// initialize Local Notification
  void initializeLocalNotification() async {
    AndroidInitializationSettings android = const AndroidInitializationSettings("@mipmap/launch_icon");
    DarwinInitializationSettings ios = const DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    InitializationSettings settings = InitializationSettings(android: android, iOS: ios);
    await localNotification.initialize(settings);
  }

  @override
  void initState() {
    super.initState();

    setPreferences();   // SharedPreferences
    initializeLocalNotification();    // Local Notification (initialization)

    /// 앱의 상태에 따라 Local Notification 작동.
    ///
    appLifecycleListener = AppLifecycleListener(
      onShow: () => printGreen("APP LAUNCHED"),
      onRestart: () {
        printGreen("APP RESTART");
        localNotification.cancelAll().then((value) {
          printGreen("All notifications have been canceled.");
        });
      },
      onResume: () {
        printGreen("APP RESUMED");
        localNotification.cancelAll().then((value) {
          printGreen("All notifications have been canceled.");
        });
      },
      onDetach: () async {
        printRed("APP DETACHED");

        // Platform 별 설정
        NotificationDetails details = const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            badgeNumber: 1,
          ),
          android: AndroidNotificationDetails(
            "0",    // Channel ID
            "",   // Channel Name
            channelDescription: "Local Notication To prevent the app from terminated",  // 알림 설명
            importance: Importance.max, // 알림 중요도
            priority: Priority.high,  // 알림 중요도
            color: Colors.redAccent,
          ),
        );

        /// 알림 전송
        ///
        // localNotification.show(
        //   1,  // Unique ID
        //   "❗Clarm ❗",  // Title
        //   "Please keep the Alarm on. Otherwise, the alarm will not go off.",   // Body
        //   // RepeatInterval.everyMinute,   // 알람 주기
        //   details,  // 각 Platform 세팅
        // );
        await localNotification.periodicallyShow(
          1,  // Unique ID
          "❗Clarm ❗",  // Title
          "Please keep the Alarm on. Otherwise, the alarm will not go off.",   // Body
          RepeatInterval.everyMinute,   // 알람 주기
          details,  // 각 Platform 세팅
        );

        final List<ActiveNotification> activeNotifications =
        await localNotification.getActiveNotifications();

        print(activeNotifications);
      },
    );
  }

  // 1. await localNotification.periodicallyShow 가 매분 작동하지 않음.
  // 2. 앱이 재시작(Restart or Resumed) 되는 것을 감지하지 못함.
  //    -> 감지해야 1.의 주기적 알람을 끌 수 있음!


  @override
  void dispose() {
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
        // child: Clarm(),
        // child: MkTestAudio(),
      ),
      theme: ref.watch(isDarkMode) ? MyTheme.themeDarkMode : MyTheme.themeDefault,
      // darkTheme: ThemeData.dark(),
    );
  }
}

