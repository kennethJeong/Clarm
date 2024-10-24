import 'dart:async';
import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
/////////////////////////////////////////////////////////
import 'package:Clarm/models/providers.dart';
import 'package:Clarm/utils/hex_color.dart';
import 'package:Clarm/utils/color_print.dart';
import 'package:Clarm/utils/audio_process.dart';
/////////////////////////////////////////////////////////
import 'package:audioplayers/audioplayers.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
// import 'package:vibration/vibration.dart';

class VideoWaveForms extends ConsumerStatefulWidget {
  const VideoWaveForms({
    super.key,
    required this.originAudioFile,
    required this.mergedAudioFile,
    required this.viewWidth,
    required this.duration,
    required this.clap,
    required this.vibration,
  });

  final File originAudioFile;
  final File mergedAudioFile;
  final double viewWidth;
  final int duration;
  final bool clap;
  final bool vibration;

  @override
  VideoWaveFormsState createState() => VideoWaveFormsState();
}

class VideoWaveFormsState extends ConsumerState<VideoWaveForms> with TickerProviderStateMixin {
  late AudioPlayer audioPlayer;
  late AudioPlayer audioPlayer4Record;
  late PlayerController waveformPlayerController;
  late PlayerController waveformPlayerController4Record;
  late RecorderController recorderController;
  late String recordFilePath;
  final GlobalKey clapIconKey = GlobalKey();
  List<Widget> listClapIcons = [];
  bool isPlayedOnce = false;    // audioPlayer 최소 한번 재생됐는지 확인용 boolean
  bool isRecording = false;
  bool isComparing = false;
  bool isEndedComparing = false;
  String textAfterComparison = '';
  Color textColorAfterComparison = Colors.red;
  late List<int> patternedVibration = [];
  late bool hasCustomVibrationsSupport = false;
  late Timer vibrationTimer = Timer.periodic(Duration.zero, (t) { });

  late final AnimationController animationController = AnimationController(
    duration: Duration(milliseconds: widget.duration),
    vsync: this,
  );
  late final Animation<AlignmentGeometry> animation = Tween<AlignmentGeometry>(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  ).animate(
    CurvedAnimation(
      parent: animationController,
      curve: Curves.linear,
    ),
  );

   final playerWaveStyle = PlayerWaveStyle(
    fixedWaveColor: HexColor('b4a7d6'),
    liveWaveColor: HexColor('674ea7'),
    waveThickness: 7,
    spacing: 15,
    scaleFactor: 400,
    backgroundColor: Colors.transparent,
  );
  final playerWaveStyle4Record = PlayerWaveStyle(
    fixedWaveColor: HexColor('fec9e0'),
    liveWaveColor: HexColor('ff3e90'),
    waveThickness: 7,
    spacing: 15,
    scaleFactor: 400,
    backgroundColor: Colors.transparent,
  );

  @override
  void initState() {
    super.initState();

    recordFilePath = setRecordFilePath();

    /// Audio 재생 시 움직이는 Waveform 컨트롤러
    _initializeControllers();
    /// Recording 시작 시 움직이는 Waveform 컨트롤러
    _initializeControllers4Record();
    /// Audio Record 컨트롤러
    _initializeRecorderController();

    /// Check if the device is able to vibrate with a custom (iOS의 경우 -> pattern vibration 작동 안됌)
    ///  & Get Vibration Pattern from [originalAudioFile]
    if(widget.vibration) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        patternedVibration = await getPatternedVibration(widget.originAudioFile);
        // hasCustomVibrationsSupport = (await Vibration.hasCustomVibrationsSupport())!;
      });
    }
  }

  /// audioFileName (String) 으로 부터 녹음 파일이 저장될 local path 설정.
  ///
  String setRecordFilePath() {
    String audioFileName = widget.originAudioFile.path.split("/").last;
    String localPath = widget.originAudioFile.path.replaceAll(audioFileName, '');
    String recordLocalPath = "${localPath}record.wav";
    return recordLocalPath;
  }

  /// originalAudioFile (File) 로 부터 Peak Time 받아서,
  /// Vibration 패턴으로 변환.
  ///
  Future<List<int>> getPatternedVibration(File originalAudioFile) async {
    int secondsVibration = 200;
    List<int> patternVibration = [];

    getDataFromAudioFile('ct', originalAudioFile).then((audioDataCt) {
      int peakLength = audioDataCt.length;
      for(var i=0; i<peakLength; i++) {
        if (i == 0) {
          patternVibration.add((audioDataCt[i]['pts_time']! * 1000).toInt());
          patternVibration.add(secondsVibration);
        }
        else if(i == peakLength-1) {
          patternVibration.add((audioDataCt[i]['pts_time']! * 1000).toInt() - (audioDataCt[i-1]['pts_time']! * 1000).toInt() - secondsVibration);
          patternVibration.add(widget.duration - (audioDataCt[i]['pts_time']! * 1000).toInt() - secondsVibration);
        } else {
          patternVibration.add((audioDataCt[i]['pts_time']! * 1000).toInt() - (audioDataCt[i-1]['pts_time']! * 1000).toInt() - secondsVibration);
          patternVibration.add(secondsVibration);
        }
      }
    });

    return patternVibration;
  }

  ///
  ///
  void _initializeControllers() {
    audioPlayer = AudioPlayer()
      ..setSourceDeviceFile(widget.mergedAudioFile.path)
      ..setReleaseMode(ReleaseMode.stop)
      ..setVolume(1.0)
      ..stop();

    waveformPlayerController = PlayerController();
    waveformPlayerController.preparePlayer(
      path: widget.originAudioFile.path,
      shouldExtractWaveform: true,
      noOfSamples: playerWaveStyle.getSamplesForWidth(widget.viewWidth),
      volume: 0.0,
    );

    waveformPlayerController.onPlayerStateChanged.listen((event) async {
      /// init
      if(event.isInitialised) {
        printGreen("/////////////////////////// Audio WAVEFORM is initialized ///////////////////////////");
        await waveformPlayerController.startPlayer(finishMode: FinishMode.pause);
        await audioPlayer.resume();

        if(widget.vibration) {
          if(Platform.isIOS) {
            vibrationTimer.cancel();
            vibrationTimer = Timer.periodic(
              Duration(milliseconds: (widget.duration / 4).truncate()), (t) {
                HapticFeedback.vibrate();
              }
            );
          } else {
            // Vibration.cancel().then((value) => Vibration.vibrate(pattern: patternedVibration, amplitude: 255));
          }
        }
      }
      else if(event.isPaused) {
        /// 첫 재생이 완료되었음을 확인 -> 녹음 버튼 활성화.
        printGreen("/////////////////////////// Audio WAVEFORM is paused ///////////////////////////");
        mounted && !isPlayedOnce ? setState(() => isPlayedOnce = true) : null;

        /// loop-transition
        if(!isRecording) {
          printGreen("/////////////////////////// Audio is completed & re-initialized ///////////////////////////");
          await waveformPlayerController.startPlayer(finishMode: FinishMode.pause);
          await audioPlayer.stop().then((_) => audioPlayer.resume());

          if(widget.vibration) {
            if(Platform.isIOS) {
              vibrationTimer.cancel();
              vibrationTimer = Timer.periodic(
                Duration(milliseconds: (widget.duration / 4).truncate()), (t) {
                  HapticFeedback.vibrate();
                }
              );
            } else {
              // Vibration.cancel().then((value) => Vibration.vibrate(pattern: patternedVibration, amplitude: 255));
            }
          }
        }
      }
    });
  }

  ///
  ///
  void _initializeControllers4Record() {
    audioPlayer4Record = AudioPlayer()
      ..setSourceDeviceFile(widget.mergedAudioFile.path)
      ..setReleaseMode(ReleaseMode.stop)
      ..setVolume(0.7);

    waveformPlayerController4Record = PlayerController();
    waveformPlayerController4Record.preparePlayer(
      path: widget.originAudioFile.path,
      shouldExtractWaveform: true,
      noOfSamples: playerWaveStyle.getSamplesForWidth(widget.viewWidth),
      volume: 0.0,
    );

    waveformPlayerController4Record.onPlayerStateChanged.listen((event) async {
      if(event.isInitialised) {
        printGreen("/////////////////////////// Recording WAVEFORM is initialized ///////////////////////////");
      }
      else if(event.isPlaying) {
        printGreen("/////////////////////////// Recording WAVEFORM is Playing ///////////////////////////");
      }
      else if(event.isPaused) {
        printGreen("/////////////////////////// Recording WAVEFORM is completed ///////////////////////////");

        await recorderController.stop(true).then((_) async {

          /// 원래 오디오와 녹음된 오디오 서로 비교
          compareAfterFilterApplied();

          if(mounted) {
            setState(() {
              isRecording = false;
              listClapIcons = [];
            });
          }

          await waveformPlayerController.startPlayer(finishMode: FinishMode.pause);
          await audioPlayer.resume().then((_) => animationController.reset());

          if(widget.vibration) {
            if(Platform.isIOS) {
              vibrationTimer.cancel();
              vibrationTimer = Timer.periodic(
                Duration(milliseconds: (widget.duration / 4).truncate()), (t) {
                  HapticFeedback.vibrate();
                }
              );
            } else {
              // Vibration.cancel().then((value) => Vibration.vibrate(pattern: patternedVibration, amplitude: 255));
            }
          }
        });
      }
    });
  }

  ///
  ///
  void _initializeRecorderController() {
    recorderController = RecorderController(useLegacyNormalization: false)
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatAppleLossless
      ..sampleRate = 44100
      ..bitRate = 48000
      ..updateFrequency = const Duration(milliseconds: 70);

    List<double> claps4Ios = [];

    recorderController.onRecorderStateChanged.listen((event) {
      if(event.isInitialized) {
        printGreen("/////////////////////////// Record is Initialized ///////////////////////////");
      }
      else if(event.isStopped) {
        printGreen("/////////////////////////// Record is Ended ///////////////////////////");
        claps4Ios = [];   // clear the list of clap icons in iOS
      }
    });

    recorderController.onCurrentDuration.listen((duration) {
      if(recorderController.recorderState.isRecording)  {
        AudioWaveformsInterface.instance.getDecibel().then((decibel) {
          if(mounted
              && duration >= const Duration(milliseconds: 500)
              && duration < Duration(milliseconds: widget.duration)) {
            if(Platform.isAndroid && decibel! > 20000) {
              setState(() => listClapIcons.add(clapIcon(getWidgetPosition(clapIconKey))));
            }
            else if(Platform.isIOS && decibel! > 0.7 && !claps4Ios.contains(decibel)) {
              setState(() {
                claps4Ios.add(decibel);
                listClapIcons.add(clapIcon(getWidgetPosition(clapIconKey)));
              });
            } else {
              // Another OS
            }
          }

          // TEST //
          // printGreen("//////////// RECORDING (Duration: $duration || Decibel: $decibel) ////////////");
        });
      }
    });
  }

  ///
  ///
  void recording() {
    if(mounted) {
      setState(() {
        isRecording = true;
      });
    }

    audioPlayer
      ..pause()
      ..seek(Duration.zero);
    waveformPlayerController
      ..pausePlayer()
      ..seekTo(0);

    Future.delayed(const Duration(milliseconds: 200), () async {
      await waveformPlayerController4Record.startPlayer(finishMode: FinishMode.pause);
      await audioPlayer4Record.resume().then((_) => animationController.forward());
    });

    if(widget.vibration) {
      if(Platform.isIOS) {
        vibrationTimer.cancel();
        vibrationTimer = Timer.periodic(
          Duration(milliseconds: (widget.duration / 4).truncate()), (t) {
            HapticFeedback.vibrate();
          }
        );
      } else {
        // Vibration.cancel().then((value) => Vibration.vibrate(pattern: patternedVibration, amplitude: 255));
      }
    }

    recorderController.record(path: recordFilePath);
  }

  ///
  ///
  void compareAfterFilterApplied() async {
    if(mounted) {
      setState(() {
        isComparing = true;
      });
    }

    await applyFilter('comparison', File(recordFilePath)).then((filteredRecordFile) async {

      // Control Recorded File (녹음된 파일) == 'File(widget.originAudioFile.path)'
      // Comparison Recorded File (필터 처리된 녹음된 파일) == 'filteredRecordFile'
      await compareAudios(File(widget.originAudioFile.path), filteredRecordFile).then((bool result) async {
        printGreen("//////////// COMPARISON RESULT = '${result.toString().toUpperCase()}' ////////////");

        if(mounted) {
          setState(() {
            isComparing = false;
            isEndedComparing = true;
          });

          /// Matched
          if(result) {
            File(widget.originAudioFile.path).deleteSync(recursive: true);
            File(widget.mergedAudioFile.path).deleteSync(recursive: true);
            File(recordFilePath).deleteSync(recursive: true);
            File(filteredRecordFile.path).deleteSync(recursive: true);

            ref.watch(isAudioMatched.notifier).state = true;
          }
          /// Not Matched
          else {
            setState(() {
              textAfterComparison = "Fail :(";
              textColorAfterComparison = Colors.red;
            });

            ref.watch(countOfFailedAlarm.notifier).state++;
          }
        }
      });
    });
  }

  /// 녹음 시, waveform에 실시간으로 얹어질(stacking) 손바닥 모양 아이콘.
  ///
  Widget clapIcon(Map<String, double> position) {
    double size = 40.0;
    return Positioned(
      left: position['x']! - size/2,
      child: Icon(
        Icons.front_hand,
        size: size,
        color: HexColor('ff69b4'),
      ),
    );
  }

  /// 좌에서 우로 움직이는 각 ClapIcon의 실시간 x, y 위치.
  ///  waveform 위에 stacking 하기 위해 사용.
  ///
  Map<String, double> getWidgetPosition(GlobalKey widgetKey) {
    final RenderBox renderBox = widgetKey.currentContext?.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final x = position.dx;
    final y = position.dx;
    return {"x": x, "y": y};
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    audioPlayer4Record.dispose();
    waveformPlayerController.dispose();
    waveformPlayerController4Record.dispose();
    animationController.dispose();
    recorderController.dispose();
    // Vibration.cancel();
    vibrationTimer.cancel();

    super.dispose();
  }

  @override
  void deactivate() {
    vibrationTimer.cancel();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 2.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// [Waveform] 재생.
          /// Visibility => isRecording == false
          Visibility(
            visible: !isRecording,
            child: AudioFileWaveforms(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              size: Size(widget.viewWidth, 100),
              playerController: waveformPlayerController,
              playerWaveStyle: playerWaveStyle,
              waveformType: WaveformType.fitWidth,
              animationCurve: Curves.linear,
              animationDuration: const Duration(milliseconds: 100),
              enableSeekGesture: false,
            ),
          ),

          /// [Waveform for Recording] 재생.
          /// Visibility => isRecording == true
          Visibility(
            visible: isRecording,
            child: Stack(
              children: [
                AudioFileWaveforms(
                  padding: EdgeInsets.zero,
                  margin: EdgeInsets.zero,
                  size: Size(widget.viewWidth, 100),
                  playerController: waveformPlayerController4Record,
                  playerWaveStyle: playerWaveStyle4Record,
                  waveformType: WaveformType.fitWidth,
                  animationCurve: Curves.linear,
                  animationDuration: const Duration(milliseconds: 100),
                  enableSeekGesture: false,
                ),
                SizedBox(
                  width: widget.viewWidth,
                  height: 100,
                  child: AlignTransition(
                    alignment: animation,
                    child: Icon(
                      key: clapIconKey,
                      Icons.front_hand_outlined,
                      size: 40.0,
                      color: HexColor('ff69b4'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// [Waveform for Recording] 재생 중일 때,
          /// 데시벨에 따라 박수 Icon 추가하기.
          for(Widget item in listClapIcons) item,

          /// waveform 상단에 나타날 Label 모음.
          ///
          Positioned(
            top: 50,
            child: Stack(
              children: [
                /// 녹음 후, 비교 결과 process 중에 CircularProgressIndicator 등장.
                /// 상태 관리 = isComparing
                Visibility(
                  visible: isComparing,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: HexColor('ff69b4'),
                    ),
                  )
                ),

                /// 녹음하고 Comparison 종료 후,
                ///  결과값 (Success || Fail) FadeAnimatedText 출력.
                /// 상태 관리 = isEndedComparing
                Visibility(
                  visible: isEndedComparing,
                  child: AnimatedTextKit(
                    totalRepeatCount: 2,
                    pause: const Duration(milliseconds: 500),
                    onFinished: () {
                      if(mounted) {
                        setState(() {
                          isEndedComparing = !isEndedComparing;
                          textAfterComparison = '';
                          textColorAfterComparison = Colors.red;
                        });
                      }
                    },
                    animatedTexts: [
                      FadeAnimatedText(
                        textAfterComparison,
                        duration: const Duration(milliseconds: 1000),
                        textStyle: TextStyle(
                          fontSize: 20,
                          color: textColorAfterComparison,
                        ),
                      ),
                    ]
                  ),
                ),
              ],
            ),
          ),


          /// [Waveform] 아래에 마이크 모양 IconButton.
          ///  버튼 클릭 시, Recording 시작.
          /// 상태 관리 = isRecording
          Visibility(
            visible: widget.clap,
            child: Positioned(
              bottom: 0,
              child: Center(
                child: AvatarGlow(
                  glowColor: HexColor('ff69b4'),
                  animate: isRecording,
                  child: Material(
                    elevation: 8.0,
                    shape: const CircleBorder(),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 30.0,
                      child: IconButton(
                        onPressed: () {
                          if(!isRecording && isPlayedOnce) {
                            recording();
                          }
                        },
                        icon: Icon(
                          Icons.mic,
                          color: HexColor('ff69b4'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}