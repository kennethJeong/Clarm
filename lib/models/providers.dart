import 'package:flutter_riverpod/flutter_riverpod.dart';

// bottom_bar.dart
// final bottomNavIndex = StateProvider<int>((ref) => 0);

// clarm.dart
// final clappingAlarmInit = StateProvider<bool>((ref) => true);

// _let_out_clap.dart
// final isVisibleCountDown = StateProvider<bool>((ref) => true);
// final isVisiblePlayControl = StateProvider<bool>((ref) => false);
// final isVisibleRecorder = StateProvider<bool>((ref) => false);
// final isVisibleAlarmOff = StateProvider<bool>((ref) => false);
// final isAlarmRollback = StateProvider<bool>((ref) => false);
// final countOfAlarm = StateProvider<int>((ref) => 1);


// waveform.dart
// final isVisibleWaveform = StateProvider<bool>((ref) => false);


// final filteredAudioPathCt = StateProvider<String>((ref) => '');

/// main.dart
final isAdLoading = StateProvider<bool>((ref) => false);

/// clarm.dart
final originalClapAssetPath = StateProvider<String>((ref) => '');
final mergedAudioPath = StateProvider<String>((ref) => '');
final mergedAudioDuration = StateProvider<int>((ref) => 0);
final isAudioMatched = StateProvider<bool>((ref) => false);
final countOfFailedAlarm = StateProvider<int>((ref) => 0);
final isAlarmReactivated = StateProvider<bool>((ref) => false);

/// setting
final isDarkMode = StateProvider<bool>((ref) => false);