// // ignore_for_file: non_constant_identifier_names
// import 'dart:io';
// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// import 'package:Clarm/main.dart';
// import 'package:Clarm/utils/audio_process.dart';
// import 'package:Clarm/models/state_providers.dart';
// import 'package:Clarm/utils/hex_color.dart';
// import 'package:Clarm/widgets/waveform.dart';
//
// import 'package:alarm/alarm.dart';
// import 'package:animated_text_kit/animated_text_kit.dart';
// import 'package:avatar_glow/avatar_glow.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:path_provider/path_provider.dart';
//
// class LetOutClap extends ConsumerStatefulWidget {
//   final AlarmSettings? alarmSettings;
//
//   const LetOutClap({
//     Key? key,
//     this.alarmSettings,
//   }) : super(key: key);
//
//   @override
//   LetOutClapState createState() => LetOutClapState();
// }
//
// class LetOutClapState extends ConsumerState<LetOutClap> {
//   int clapSeconds = 4;
//   File originLocalAudioFile = File('');
//
//   FadeAnimatedText fadeAnimatedText(String text, int duration) {
//     return FadeAnimatedText(
//       text,
//       duration: Duration(milliseconds: duration),
//       fadeInEnd: 0.1,
//       fadeOutBegin: 0.5,
//     );
//   }
//
//   Future<File> saveToLocalDirectory(String type, String audioDir, String audioFileName) async {
//     String audioPath = "";
//     if(type == "control") {
//       audioPath = "$audioDir/$audioFileName";
//     } else if(type == "comparison") {
//       audioPath = audioFileName;
//     }
//
//     final byteData = await rootBundle.load('assets/audios/$audioPath');
//     final file = File('${(await getTemporaryDirectory()).path}/$audioFileName');
//     return file.writeAsBytes(byteData.buffer
//         .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
//   }
//
//   /// 문제로 낼 Audio 파일 생성
//   ///
//   Future<void> createMedia_control() async {
//     String randomClapFileName = "${clapSeconds}s_${Random().nextInt(9)+1}.wav"; // ex) 2s_(1~10).wav
//     String audioDir = "${clapSeconds}s";
//
//     // make a ByteData file
//     await saveToLocalDirectory("control", audioDir, randomClapFileName).then((clapFile) async {
//       print("<<<<<<<<<< saveToLocalDirectory >>>>>>>>>>");
//       originLocalAudioFile = clapFile;
//
//       // Apply filter using FFmpegKit
//       await applyFilter('control', clapFile).then((filteredAudioCt) async {
//         print("<<<<<<<<<< applyFilter >>>>>>>>>>");
//         ref.watch(filteredAudioPathCt.notifier).state = filteredAudioCt.path;
//
//         // // Get data-set using FFprobeKit
//         // await getDataFromAudioFile(filteredClapFile).then((audioData) {
//         //   dataFromCt = audioData;
//         // });
//       });
//     });
//   }
//
//   Widget processingIcon(String hexCode, IconData iconData) {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.only(top: MediaQuery.of(context).size.height / 3),
//         child: AvatarGlow(
//           glowColor: HexColor(hexCode),
//           endRadius: 60.0,
//           duration: const Duration(milliseconds: 1000),
//           repeat: true,
//           showTwoGlows: true,
//           repeatPauseDuration: const Duration(milliseconds: 100),
//           child: Material(
//             elevation: 8.0,
//             shape: const CircleBorder(),
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               radius: 30.0,
//               child: Icon(
//                 iconData,
//                 color: HexColor(hexCode),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void initState() {
//     super.initState();
//
//     createMedia_control();
//   }
//
//   void deleteLocalDirectory() async {
//     final localPath = (await getTemporaryDirectory()).path;
//     Directory(localPath).deleteSync(recursive: true);
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     // deleteLocalDirectory();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             /// 카운트 다운
//             /// 상태 관리 = ref.watch(isVisibleCountDown)
//             Visibility(
//               visible: ref.watch(isVisibleCountDown),
//               child: Expanded(
//                 child: Center(
//                   child: AnimatedTextKit(
//                     animatedTexts: [
//                       // fadeAnimatedText("", 500),
//                       // fadeAnimatedText("I'll play the Clapping first", 1000),
//                       // fadeAnimatedText("2", 500),
//                       // fadeAnimatedText("1", 500),
//                       fadeAnimatedText("", 100),
//                     ],
//                     isRepeatingAnimation: false,
//                     onFinished: () {
//                       ref.watch(isVisibleCountDown.notifier).state = false;
//                       ref.watch(isVisiblePlayControl.notifier).state = true;
//                     },
//                   ),
//                 ),
//               ),
//             ),
//
//             /// 박수 문제 재생.
//             /// 상태 관리 = ref.watch(isVisiblePlayControl)
//             Visibility(
//               visible: ref.watch(isVisiblePlayControl),
//               child: Expanded(
//                 child: Stack(
//                   children: [
//                     Center(
//                       child: VideoWaveForm(
//                         audioFile: originLocalAudioFile,
//                         isRecording: false,
//                         viewWidth: MediaQuery.of(context).size.width * .9,
//                       ),
//                     ),
//                     processingIcon('674ea7', Icons.play_arrow),
//                   ],
//                 )
//               ),
//             ),
//
//             /// 카운트 다운
//             /// 상태 관리 = ref.watch(isVisibleWaveform)
//             Visibility(
//               visible: ref.watch(isVisibleWaveform),
//               child: Expanded(
//                 child: Center(
//                   child: AnimatedTextKit(
//                     animatedTexts: [
//                       // fadeAnimatedText("", 500),
//                       // fadeAnimatedText("Please clap the same way", 1000),
//                       // fadeAnimatedText("2", 500),
//                       // fadeAnimatedText("1", 500),
//                       fadeAnimatedText("", 100),
//                     ],
//                     isRepeatingAnimation: false,
//                     onFinished: () {
//                       ref.watch(isVisibleWaveform.notifier).state = false;
//                       ref.watch(isVisibleRecorder.notifier).state = true;
//                     },
//                   ),
//                 ),
//               ),
//             ),
//
//             /// 박수 문제에 대응(녹음 및 비교).
//             /// 상태 관리 = ref.watch(isVisibleRecorder)
//             Visibility(
//               visible: ref.watch(isVisibleRecorder),
//               child: Expanded(
//                 child: Stack(
//                   children: [
//                     Center(
//                       child: VideoWaveForm(
//                         audioFile: originLocalAudioFile,
//                         isRecording: true,
//                         viewWidth: MediaQuery.of(context).size.width * .9,
//                       ),
//                     ),
//                     processingIcon('ff69b4', Icons.mic),
//                   ],
//                 ),
//               )
//             ),
//
//             /// 결과 보여주기 및 사후 처리.
//             /// 상태 관리 = ref.watch(isVisibleAlarmOff)
//             Visibility(
//               visible: ref.watch(isVisibleAlarmOff),
//               child: Expanded(
//                 child: Center(
//                   child: AnimatedTextKit(
//                     animatedTexts: [
//                       fadeAnimatedText("Alarm OFF", 2000),
//                     ],
//                     isRepeatingAnimation: false,
//                     onFinished: () {
//                       ref.watch(isVisibleAlarmOff.notifier).state = false;
//                       ref.watch(isVisibleCountDown.notifier).state = true;
//
//                       Navigator.pushAndRemoveUntil(
//                         context,
//                         MaterialPageRoute(
//                           builder: (BuildContext context) => const Main(),
//                         ), (route) => false,
//                       );
//                     },
//                   ),
//                 ),
//               )
//             )
//           ],
//         ),
//       )
//     );
//   }
// }