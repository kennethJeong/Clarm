import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:Clarm/utils/color_print.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

Future<File> applyFilter(String type, File audioFile) async {
  final localPath = (await getTemporaryDirectory()).path;
  final audioFileName = audioFile.path.split("/").last;
  final inputAudioFilePath = audioFile.path;

  String outputAudioFilePath = '';
  if(type == "control") {
    outputAudioFilePath = "$localPath/ct_$audioFileName";
    await FFmpegKit.execute(
      "-y -i $inputAudioFilePath -hide_banner "
      // "-af 'highpass=f=300,asendcmd=0.0 afftdn sn start,asendcmd=1.5 afftdn sn stop,afftdn=nf=-20,dialoguenhance,lowpass=f=3000' "
      // "-af 'bandpass=normalize=true,channelsplit,axcorrelate=size=1024:algo=slow' "
      // "-af 'bandpass=normalize=true' "
      "-af 'anlmdn=s=7:p=0.002:r=0.002:m=15' "
      "$outputAudioFilePath"
    );
  } else if(type == "comparison") {
    // String outputAudioFilePath_ex = "$localPath/ex_cp_$audioFileName";
    // outputAudioFilePath = "$localPath/cp_$audioFileName";
    // await FFmpegKit.execute(
    //   "-y -i $inputAudioFilePath -hide_banner "
    //   "-af 'highpass=f=300,asendcmd=0.0 afftdn sn start,asendcmd=1.5 afftdn sn stop,afftdn=nf=-20,dialoguenhance,lowpass=f=3000' "
    //   "$outputAudioFilePath_ex"
    // );
    // await FFmpegKit.execute(
    //   "-y -i $outputAudioFilePath_ex -hide_banner "
    //   "-af 'bandpass=normalize=true,channelsplit,axcorrelate=size=1024:algo=slow' "
    //   "$outputAudioFilePath"
    // ).then((_) {
    //   File(outputAudioFilePath_ex).deleteSync(recursive: true);
    // });

    outputAudioFilePath = "$localPath/cp_$audioFileName";
    await FFmpegKit.execute(
      "-y -i $inputAudioFilePath -hide_banner "
      // "-af 'anlmdn=s=7:p=0.002:r=0.002:m=15' "   // Simple Filter
      "-af 'highpass=f=10,asendcmd=0.0 afftdn sn start,asendcmd=4.0 afftdn sn stop,afftdn=nr=10:nf=-40:tn=1,dialoguenhance,lowpass=f=3000' "
      // "-af 'bandpass=normalize=true,channelsplit,axcorrelate=size=1024:algo=slow' "
      // "-af 'highpass=f=200,asendcmd=0.0 afftdn sn start,asendcmd=1.5 afftdn sn stop,afftdn=nf=-20,dialoguenhance,lowpass=f=1000' "
      "$outputAudioFilePath"
    );
  }

  return File(outputAudioFilePath);
}

Future<List<Map<String, double>>> getDataFromAudioFile(String type, File audioFile) async {
  final audioFilePath = audioFile.path;
  List<Map<String, double>> result = [];
  final completer = Completer<List<Map<String, double>>>();

  int level = 0;
  if(type == 'ct') {
    level = 30000;
  }
  else if(type == 'cp') {
    level = 20000;
  }

  await FFprobeKit.executeAsync(
    "-v error -hide_banner -print_format json -f lavfi"
    " -i amovie=$audioFilePath,astats=metadata=1:reset=1:length=10"
    " -show_entries frame=pts_time:frame_tags="
    "lavfi.astats.Overall.Max_level,lavfi.astats.Overall.Min_level",
    (session) async {
      final returnCode = await session.getReturnCode();
      final output = await session.getOutput();

      if(ReturnCode.isSuccess(returnCode)) {
        if(output == null || output.isEmpty) {
          throw Exception("No data - [$audioFilePath]");
        }

        try {
          final parsedOutput = jsonDecode(output);
          final frameData = parsedOutput["frames"] as List;
          List<double> listPtsTime = [];
          for (var fd in frameData) {
            double ptsTime = double.parse(fd['pts_time']);
            double roundedPtsTime = double.parse(truncateToDecimalPlaces(ptsTime, 2).toStringAsFixed(1));    // ex) 1.6126 -> 1.6
            double minLevel = double.parse(fd['tags']["lavfi.astats.Overall.Min_level"]);
            double maxLevel = double.parse(fd['tags']["lavfi.astats.Overall.Max_level"]);

            if (minLevel < -level && maxLevel > level) {
              if(!listPtsTime.contains(roundedPtsTime)) {
                listPtsTime.add(roundedPtsTime);

                result.add({
                  "pts_time": roundedPtsTime,
                  "min_level": minLevel,
                  "max_level": maxLevel,
                });
              }
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

double truncateToDecimalPlaces(num value, int fractionalDigits) {
  return (value * pow(10, fractionalDigits)).truncate() / pow(10, fractionalDigits);
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

Future<bool> compareAudios(File filteredAudioCt, File filteredAudioCp) async {
  final completer = Completer<bool>();
  int matchCount = 0;
  double allowableSeconds = 0.2;

  await getDataFromAudioFile('ct', filteredAudioCt).then((audioDataCt) async {
    printGreen("//////////// CT COUNTS = '${audioDataCt.length}' ////////////");
    printGreen(audioDataCt.toString());

    await getDataFromAudioFile('cp', filteredAudioCp).then((audioDataCp) {
      printGreen("//////////// CP COUNTS = '${audioDataCp.length}' ////////////");
      printGreen(audioDataCp.toString());

      for (var cpData in audioDataCt) {
        final cpDataPtsTime = cpData['pts_time'];
        for (var ctData in audioDataCp) {
          final ctDataPtsTime = ctData['pts_time'];

          if(ctDataPtsTime! >= cpDataPtsTime! - allowableSeconds
              && ctDataPtsTime <= cpDataPtsTime + allowableSeconds) {
            matchCount++;
          }
        }
      }

      printGreen("//////////// MATCH COUNTS = '$matchCount' ////////////");

      if(matchCount != 0
          && audioDataCp.length >= audioDataCt.length
          && matchCount >= audioDataCt.length
      ) {
        completer.complete(true);
      } else {
        completer.complete(false);
      }
    });
  });

  return completer.future;
}

Future<String> getRandomAudio(String sort) async {
  final manifestJson = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = json.decode(manifestJson);
  late List filtered;

  if(sort == "clap") {
    filtered = manifestMap.keys
        .where((path) => path.startsWith('assets/audios/clap/'))
        .toList();
  }
  else if(sort == "sound") {
    filtered = manifestMap.keys
        .where((path) => path.startsWith('assets/audios/sounds/'))
        .toList();
  }

  String randomAudio = filtered[Random().nextInt(filtered.length)];
  return randomAudio;
}

Future<File> fileToByteData(String audioAssetFile) async {
  final byteData = await rootBundle.load(audioAssetFile);
  final audioAssetFileName = audioAssetFile.split("/").last;
  final file = File('${(await getTemporaryDirectory()).path}/$audioAssetFileName');
  return file.writeAsBytes(byteData.buffer
      .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
}

Future<String> mergeAudios(String inputName1, String inputName2, String inputName3) async {
  final completer = Completer<String>();
  final localPath = (await getTemporaryDirectory()).path;
  String output = "$localPath/merged.wav";

  /// input1 = Sound
  /// input2 = Clap
  /// input2 = Beep

  await fileToByteData(inputName1).then((input1) {
    fileToByteData(inputName2).then((input2) {
      fileToByteData(inputName3).then((input3) {
        FFmpegKit.executeAsync(
          '-y -i ${input1.path} -i ${input2.path} -i ${input3.path} '
          '-filter_complex "[0:0]volume=1.0[a];[1:0]volume=0.8[b];[2:0]volume=0.3[c];'
          '[a][b][c]amix=inputs=3:duration=first" '
          '$output', (session) async {
            final returnCode = await session.getReturnCode();

            if(ReturnCode.isSuccess(returnCode)) {
              printGreen("//////////////// MERGE - SUCCESS ////////////////");

              File(input1.path).deleteSync(recursive: true);
              File(input3.path).deleteSync(recursive: true);

              completer.complete(output);
            } else {
              printRed("//////////////// MERGE - FAILURE ////////////////");
              completer.complete('');
            }
          }
        );
      });
    });
  });

  return completer.future;
}