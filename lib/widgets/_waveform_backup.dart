// import 'dart:io';
// import 'package:alarm/alarm.dart';
// import 'package:Clarm/clarm.dart';
// import 'package:Clarm/main.dart';
// import 'package:Clarm/screens/ring_alarm.dart';
// import 'package:Clarm/utils/audio_process.dart';
// import 'package:flutter/material.dart';
// import 'package:audio_waveforms/audio_waveforms.dart';
// import 'package:Clarm/models/providers.dart';
// import 'package:Clarm/utils/hex_color.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// class VideoWaveForm extends ConsumerStatefulWidget {
//   const VideoWaveForm({
//     Key? key,
//     required this.audioFile,
//     required this.isRecording,
//     required this.viewWidth,
//   }) : super(key: key);
//
//   final File audioFile;
//   final bool isRecording;
//   final double viewWidth;
//
//   @override
//   VideoWaveFormState createState() => VideoWaveFormState();
// }
//
// class VideoWaveFormState extends ConsumerState<VideoWaveForm> {
//   RecorderController recorderController = RecorderController();
//   PlayerController playerController = PlayerController();
//   late final PlayerWaveStyle waveformStyle;
//   late final int audioDuration;
//   double opacity = 1.0;
//   double volume = 1.0;
//   String audioFile = '';
//   String localPath = '';
//   String recordFilePath = '';
//   bool recording = false;
//   final GlobalKey clapIconKey = GlobalKey();
//   final GlobalKey stackKey = GlobalKey();
//   List<Widget> listClapIcons = [];
//
//   final playerWaveStyle = PlayerWaveStyle(
//     fixedWaveColor: HexColor('b4a7d6'),
//     liveWaveColor: HexColor('8e7cc3'),
//     waveThickness: 5,
//     showSeekLine: true,
//     seekLineThickness: 5,
//     seekLineColor: HexColor('674ea7'),
//     spacing: 7,
//     scaleFactor: 500,
//     backgroundColor: Colors.transparent,
//   );
//
//   @override
//   void initState() {
//     super.initState();
//
//     getAudioDuration();
//
//     _initializePlayerController();
//
//     if(widget.isRecording) {
//       _initializeRecorderControllers();
//
//       WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {recording = true;}));
//     }
//   }
//
//   void getAudioDuration() {
//     audioDuration = int.parse(((widget.audioFile.path.split("/").last).split("_").first).substring(0,1));
//   }
//
//   void _initializePlayerController() async {
//     if(widget.isRecording) {
//       setState(() {
//         opacity = 0.7;
//         volume = 0.1;
//       });
//     }
//     playerController = PlayerController();
//     playerController.onPlayerStateChanged.listen((_) => setState(() {}));
//     playerController.preparePlayer(
//       path: widget.audioFile.path,
//       shouldExtractWaveform: true,
//       noOfSamples: playerWaveStyle.getSamplesForWidth(widget.viewWidth),
//       volume: volume,
//     );
//     playerController.updateFrequency = UpdateFrequency.high;
//     playerController.onCompletion.listen((_) {
//       if(!widget.isRecording) {
//         ref.watch(isVisiblePlayControl.notifier).state = false;
//         ref.watch(isVisibleWaveform.notifier).state = true;
//       } else {
//         recorderController.stop(true).then((_) {
//           applyFilter('comparison', File(recordFilePath)).then((filteredAudioCp) {
//             compareAudios(File(ref.watch(filteredAudioPathCt)), filteredAudioCp).then((bool result) {
//
//               print("//////////// COMPARISON RESULT = '${result.toString().toUpperCase()}' ////////////");
//
//               ref.watch(isVisibleRecorder.notifier).state = false;
//
//               /// Matched
//               if(result) {
//
//                 ref.watch(isVisibleAlarmOff.notifier).state = true;
//               }
//               /// Not Matched
//               else {
//                 ref.watch(isAlarmRollback.notifier).state = true;
//
//               }
//             });
//           });
//
//           // ref.watch(isVisibleRecorder.notifier).state = false;
//
//         });
//       }
//     });
//   }
//
//   void _initializeRecorderControllers() {
//     audioFile = widget.audioFile.path.split("/").last;
//     localPath = widget.audioFile.path.replaceAll(audioFile, '');
//     recordFilePath = "${localPath}recordFile.wav";
//
//     recorderController = RecorderController()
//       ..androidEncoder = AndroidEncoder.aac
//       ..androidOutputFormat = AndroidOutputFormat.mpeg4
//       ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
//       ..sampleRate = 44100
//       ..bitRate = 48000;
//
//     recorderController.updateFrequency = const Duration(milliseconds: 70);
//     recorderController.onCurrentDuration.listen((duration) {
//       AudioWaveformsInterface.instance.getDecibel().then((decibel) {
//         if(decibel! > 10000) {
//           setState(() => listClapIcons.add(clapIcon(getWidgetPosition(clapIconKey))));
//
//           if(duration >= const Duration(seconds: 1) && duration < Duration(seconds: audioDuration)) {
//             print("Duration: $duration || Decibel: $decibel");
//           }
//         }
//       });
//     });
//   }
//
//   Map<String, double> getWidgetPosition(GlobalKey widgetKey) {
//     final RenderBox renderBox = widgetKey.currentContext?.findRenderObject() as RenderBox;
//     final Offset position = renderBox.localToGlobal(Offset.zero);
//     final x = position.dx;
//     final y = position.dx;
//     return {"x": x, "y": y};
//   }
//
//   Widget clapIcon(Map<String, double> position) {
//     double size = 40.0;
//
//     return Positioned(
//       left: position['x']! - size/2,
//       child: Icon(
//         Icons.front_hand,
//         size: size,
//         color: HexColor('ff69b4'),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     recorderController.dispose();
//     playerController.dispose();
//     super.dispose();
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     if(playerController.playerState.isInitialised) {
//       playerController.startPlayer(finishMode: FinishMode.stop).then((_) {
//         if(widget.isRecording) {
//           recorderController.record(path: recordFilePath);
//         }
//       });
//     }
//
//     return Stack(
//       key: stackKey,
//       alignment: Alignment.centerLeft,
//       children: [
//         Opacity(
//           opacity: opacity,
//           child: AudioFileWaveforms(
//             padding: EdgeInsets.zero,
//             margin: EdgeInsets.zero,
//             size: Size(widget.viewWidth, 100),
//             playerController: playerController,
//             playerWaveStyle: playerWaveStyle,
//             waveformType: WaveformType.fitWidth,
//             animationCurve: Curves.easeOut,
//             animationDuration: const Duration(milliseconds: 100),
//           ),
//         ),
//         // widget.isRecording ? AudioWaveforms(
//         //   size: Size(widget.viewWidth, 100),
//         //   recorderController: recorderController,
//         //   waveStyle: WaveStyle(
//         //     waveColor: HexColor('ff69b4'),
//         //     waveThickness: 5,
//         //     showMiddleLine: false,
//         //     spacing: 7,
//         //     scaleFactor: 50,
//         //     backgroundColor: Colors.transparent,
//         //     extendWaveform: true,
//         //   ),
//         // ) : const SizedBox.shrink(),
//         widget.isRecording ? SizedBox(
//           width: widget.viewWidth,
//           height: 100,
//           child: AnimatedAlign(
//             alignment: !recording ? Alignment.centerLeft : Alignment.centerRight,
//             duration: Duration(seconds: audioDuration),
//             curve: Curves.linear,
//             child: Icon(
//               key: clapIconKey,
//               Icons.front_hand_outlined,
//               size: 40.0,
//               color: HexColor('ff69b4'),
//             ),
//           ),
//         ) : const SizedBox.shrink(),
//         for(Widget item in listClapIcons) item,
//       ],
//     );
//   }
// }