import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:Clarm/screens/edit_alarm.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

import 'package:Clarm/models/providers.dart';
import 'package:Clarm/screens/ring_alarm.dart';
import 'package:Clarm/widgets/_bottom_nav.dart';

class ClappingAlarms extends ConsumerStatefulWidget {
  const ClappingAlarms({super.key});

  @override
  ClappingAlarmsState createState() => ClappingAlarmsState();
}

class ClappingAlarmsState extends ConsumerState<ClappingAlarms> {
  List<Widget> pages = [];

  List<Map<String, double>> _outputToList(String? output) {
    if (output == null || output.isEmpty) {
      throw Exception("No data");
    }

    List<Map<String, double>> result = [];

    try {
      final parsedOutput = jsonDecode(output);
      // debugPrint(output, wrapWidth: 1024);
      final frameData = parsedOutput["frames"] as List;
      for (var fd in frameData) {
        double ptsTime = double.parse(fd['pts_time']);
        double minLevel = double.parse(fd['tags']["lavfi.astats.Overall.Min_level"]);
        double maxLevel = double.parse(fd['tags']["lavfi.astats.Overall.Max_level"]);
        double peakLevel = double.parse(fd['tags']["lavfi.astats.Overall.Peak_level"]);
        if(peakLevel > 0) {
          result.add({
            "pts_time": ptsTime,
            "min_level": minLevel,
            "max_level": maxLevel,
            "peak_level": peakLevel,
          });
        }
      }
      return result;
    } on Exception catch (_) {
      throw Exception("Parsing failed");
    }
  }

  void _handleFailure({
    required ReturnCode? returnCode,
    required Completer<List<Map<String, double>>?> completer,
  }) {
    if (ReturnCode.isCancel(returnCode)) {
      print("ffprobe command canceled");
      completer.complete(null);
    } else {
      final e = Exception("command fail");
      completer.completeError(e);
    }
  }

  Future<File> saveAudioAssetToLocalDirectory(String audioFileName) async {
    final byteData = await rootBundle.load('assets/audios/$audioFileName');

    final file = File('${(await getTemporaryDirectory()).path}/$audioFileName');
    return file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }

  Future<List<Map<String, double>>> getDataFromAudio(File audioFile) async {
    final audioFilePath = audioFile.path;
    List<String> pathDivide = audioFilePath.split("/");
    final audioFileWithExpansion  = pathDivide.last;
    final audioFileWithoutExpansion  = audioFileWithExpansion.split(".").first;
    final inputAudioFilePath = audioFilePath;
    final outputAudioFilePath = "${audioFilePath.replaceAll(audioFileWithExpansion, "")}${audioFileWithoutExpansion}_cv.${audioFileWithExpansion.split(".").last}";

    List<Map<String, double>> result = [];
    final completer = Completer<List<Map<String, double>>>();

    // 스테레오(2채널) 이어야 변환 가능.
    // mp3 파일에 대한 Encoder를 찾지못함 -> 애초에 다른 확장자를 사용하거나, 다른 포멧(-f mp2) 사용하여 변환.
    // FFmpeg add filters -> bandpass,channelsplit,axcorrelate 적용.
    //
    // FFmpegKit 사용하여 filter 적용된 temp 파일 생성
    // -> temp 파일과 기존에 녹음해둔 파일을 비교
    // -> pts_time(오차범위 설정 필요) 내에 같은 Peak값 존재 시, 동일 audio 파일로 인식하도록 설정.

    /// Control Audio File (대조군) ///
    /// 1. clapping 녹음. (확장자=mp4, 채널=스테레오, 샘플률=48000Hz, 비트레이트=160kbps, 길이=5초)
    /// 2. assets/audios/clapping_list 에 directly 저장.
    /// 3. saveAudioAssetToLocalDirectory -> audio 파일을 ByteData 로 변환하여 Local 저장.
    /// # Comparison Audio File 과의 비교 시, ByteData 끼리 비교.
    /// # 들려줄 때는 assets/audios/clapping_list 에서 재생.
    ///
    /// Comparison Audio File (비교군) ///
    /// 1. Control Audio File 과 동일한 File name + Comparison 이름으로 설정.
    /// 2. clapping 녹음. (확장자=mp4, 채널=스테레오, 샘플률=48000Hz, 비트레이트=160kbps, 길이=5초)
    /// 3. saveAudioAssetToLocalDirectory -> audio 파일을 ByteData 로 변환하여 Local 저장.
    /// 4. 미리 Local 에 저장된 Control Audio File 과 FFprobe 로 데이터 비교
    /// # 데이터 비교 => 오차 범위 내 시간 (ex. 오차=전체길이의 5프로 -> 5초 길이의 Audio 경우, 오차=0.25초)
    ///               => (ex. 2.0초에 박수 소리가 녹음되어있다면, 유저가 1.75~2.25 범위 내에 박수를 쳐야 True.)
    /// 5. Control Audio File 의 전체 박수 수마다 True 값 산출하여, All True 일 경우에 Alarm OFF.)
    /// 6. 녹음된 ByteData Audio file -> Local 에서 삭제
    ///
    /// # Comparison Audio File 과의 비교 시, ByteData 끼리 비교.
    /// # 들려줄 때는 assets/audios/clapping_list 에서 재생.

    // String audioFilePath = '/data/user/0/com.dev_kennyJ.clapping_alarm/cache';
    // String inputAudioFilePath = '$audioFilePath/clapping_4t_2s_ct_cv.wav';
    // String outputAudioFilePath = '$audioFilePath/clapping_4t_2s_cp_cv.wav';

    await FFmpegKit.executeAsync(
        "-y -i $inputAudioFilePath -hide_banner "
            "-af bandpass=normalize=true,channelsplit,axcorrelate=size=1024:algo=fast "
            "$outputAudioFilePath",
            (session) async {
          final result = await session.getOutput();
          debugPrint(result, wrapWidth: 1024);
        }
    );

    // await FFprobeKit.executeAsync(
    //   "-v error -hide_banner -print_format json -f lavfi"
    //   " -i amovie=$inputAudioFilePath,astats=metadata=1:reset=1:length=0.01"
    //   " -show_entries frame=pts_time:frame_tags=lavfi.astats.Overall.Max_level,lavfi.astats.Overall.Min_level",
    //   (session) async {
    //     final returnCode = await session.getReturnCode();
    //     final output = await session.getOutput();
    //
    //     if (ReturnCode.isSuccess(returnCode)) {
    //       if (output == null || output.isEmpty) {
    //         throw Exception("No data - [$audioFilePath]");
    //       }
    //
    //       try {
    //         final parsedOutput = jsonDecode(output);
    //         final frameData = parsedOutput["frames"] as List;
    //         for (var fd in frameData) {
    //           double ptsTime = double.parse(fd['pts_time']);
    //           double minLevel = double.parse(fd['tags']["lavfi.astats.Overall.Min_level"]);
    //           double maxLevel = double.parse(fd['tags']["lavfi.astats.Overall.Max_level"]);
    //           if (minLevel != 0 && maxLevel != 0) {
    //             result.add({
    //               "pts_time": ptsTime,
    //               "min_level": minLevel,
    //               "max_level": maxLevel,
    //             });
    //           }
    //         }
    //       } on Exception catch (_) {
    //         throw Exception("Parsing failed");
    //       }
    //
    //       completer.complete(result);
    //     } else {
    //       _handleFailure(returnCode: returnCode, completer: completer);
    //     }
    //   }
    // );

    return completer.future;
  }

  Future<List<Map<String, double>>> getDataFromAudioFile(File audioFile) async {
    final audioFilePath = audioFile.path;

    List<Map<String, double>> result = [];
    final completer = Completer<List<Map<String, double>>>();

    await FFprobeKit.executeAsync(
        "-v error -hide_banner -print_format json -f lavfi"
            " -i amovie=$audioFilePath,astats=metadata=1:reset=1:length=0.01"
            " -show_entries frame=pts_time:frame_tags=lavfi.astats.Overall.Max_level,lavfi.astats.Overall.Min_level",
            (session) async {
          final returnCode = await session.getReturnCode();
          final output = await session.getOutput();

          if (ReturnCode.isSuccess(returnCode)) {
            if (output == null || output.isEmpty) {
              throw Exception("No data - [$audioFilePath]");
            }

            try {
              final parsedOutput = jsonDecode(output);
              final frameData = parsedOutput["frames"] as List;
              for (var fd in frameData) {
                double ptsTime = double.parse(fd['pts_time']);
                double minLevel = double.parse(fd['tags']["lavfi.astats.Overall.Min_level"]);
                double maxLevel = double.parse(fd['tags']["lavfi.astats.Overall.Max_level"]);
                if (minLevel != 0 && maxLevel != 0) {
                  result.add({
                    "pts_time": ptsTime,
                    "min_level": minLevel,
                    "max_level": maxLevel,
                  });
                }
              }
            } on Exception catch (_) {
              throw Exception("Parsing failed");
            }

            completer.complete(result);
          } else {
            _handleFailure(returnCode: returnCode, completer: completer);
          }
        }
    );

    return completer.future;
  }

  // void compareAudios(List<Map<String, double>> controlAudioData, List<Map<String, double>> comparisonAudioData) {
  Future<bool> compareAudios() async {
    String audioFilePath = '/data/user/0/com.dev_kennyJ.clapping_alarm/cache';
    String controlAudioFile = '$audioFilePath/clapping_4t_2s_ct_cv.wav';
    String comparisonAudioFile = '$audioFilePath/clapping_4t_2s_cp_cv.wav';

    final completer = Completer<bool>();
    int matchCount = 0;
    double allowableSeconds = 0.5;

    getDataFromAudioFile(File(controlAudioFile)).then((controlAudioData) {
      getDataFromAudioFile(File(comparisonAudioFile)).then((comparisonAudioData) {
        for (var cpData in controlAudioData) {
          final cpData_ptsTime = cpData['pts_time'];
          for (var ctData in comparisonAudioData) {
            final ctData_ptsTime = ctData['pts_time'];
            if(ctData_ptsTime! > cpData_ptsTime!-allowableSeconds && ctData_ptsTime< cpData_ptsTime+allowableSeconds) {
              matchCount++;
            }
          }
        }

        if(matchCount >= comparisonAudioData.length) {
          completer.complete(true);
        } else {
          completer.complete(false);
        }
      });
    });

    return completer.future;
  }

  @override
  void initState() {
    // pages = [
    //   AlarmList(),
    //   ScreenB(),
    // ];

    // String audioFileName = 'clapping_sample.mp3';
    // String audioFileName = 'clap_sample.mp3';
    // String audioFileName = 'clap_sample_1.m4a';
    String audioFileName = 'clapping_4t_2s_ct.wav';
    // String audioFileName = 'clapping_4t_2s_cp.wav';
    // getAudioFileFromAssets(audioFileName);

    // saveAudioAssetToLocalDirectory(audioFileName).then((audioFile) {
    //   getDataFromAudio(audioFile).then((clappingData) {
    //      // 오디오파일(cache) 제거
    //   });
    // });

    compareAudios().then((bool matchResult) {
      print(matchResult);
    });

    // getDataFromAudio().then((clappingData) {
    //   print(clappingData);
    // });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: null,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: const Center(
            child: Text(
                "Clapping Alarm"
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: EditAlarm(),
          // child: pages[ref.watch(bottomNavIndex)]
        ),
        // bottomNavigationBar: const BottomNav(),
      ),
    );
  }
}