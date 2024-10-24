// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

Future<void> writeConfig(String sort, String writeValue) async {
  final directory = (await getApplicationDocumentsDirectory ()).path;
  const String dirConfig = 'config';

  /// Dark Mode
  if(sort == "DarkMode") {
    const String file_DarkMode = '$dirConfig/isDarkMode.txt';
    final String path_DarkMode = '$directory/$file_DarkMode';
    String value = writeValue;   // int -> String

    File(path_DarkMode).writeAsString(value);
  }
}

Future<dynamic> readConfig(String sort) async {
  final directory = (await getApplicationDocumentsDirectory ()).path;
  const String dirConfig = 'config';
  dynamic result;

  /// Dark Mode
  if(sort == "DarkMode") {
    const String file_DarkMode = '$dirConfig/isDarkMode.txt';
    final String path_DarkMode = '$directory/$file_DarkMode';
    result = int.parse(await File(path_DarkMode).readAsString());
  }

  print("<<Processing>> value of [isDarkMode] == $result");

  return result;
}

Future<void> initWriteFiles(String dir) async {
  final directory = dir;
  const String dirConfig = 'config';

  /// Dark Mode
  const String file_DarkMode = '$dirConfig/isDarkMode.txt';
  final String path_DarkMode = '$directory/$file_DarkMode';
  int initValueDarkMode = 0;
  File(path_DarkMode).writeAsString(initValueDarkMode.toString());    // txt 파일 생성

  ///

}

Future<bool> initConfig() async {
  // config 디렉토리 생성 => [ /data/user/0/com.example.clapping_alarm/app_flutter ]
  final directory = (await getApplicationDocumentsDirectory ()).path;
  String dirConfig = 'config';
  bool isExisted = false;

  // 처음 생성
  if(!await Directory("$directory/$dirConfig").exists()) {
    Directory("$directory/$dirConfig").create(recursive: true).then((value) {
      initWriteFiles(directory);

      print("<<Processing>> initConfig => Directory is Created !!");
      isExisted = false;
    });
  } else {
    print("<<Processing>> initConfig => Directory is Already Existed !!");
    isExisted = true;
  }

  return isExisted;   // 이미 생성됨
}