// // import 'package:clapping_alarm/utils/audio_process.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:record/record.dart';
//
// class MkTestAudio extends ConsumerStatefulWidget {
//   const MkTestAudio({
//     Key? key,
//   }) : super(key: key);
//
//   @override
//   MkTestAudioState createState() => MkTestAudioState();
// }
//
// class MkTestAudioState extends ConsumerState<MkTestAudio> {
//   // final AudioRecorder _audioRecorder = AudioRecorder();
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   String buttonText = '';
//
//   @override
//   void initState() {
//     super.initState();
//     buttonText = 'Record Start';
//
//     // text = "TEST";
//     //
//     // Future.wait([
//     //   getRandomAudio("sound").then((randomAudio) {
//     //     audioSound = randomAudio;
//     //   }),
//     //   getRandomAudio("clap").then((randomAudio) {
//     //     audioClap = randomAudio;
//     //   }),
//     // ]).then((_) {
//     //   mergeAudios(audioClap, audioSound, 'assets/audios/beep.wav');
//     // });
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () {
//
//           },
//           child: Text(
//             buttonText
//           )
//         )
//       ),
//     );
//   }
// }
//
// /// List to Dev ///
// /// . <Ring Alarm> 으로 navigate 할 때, [beep, sound, clapping] 파일 랜덤 지정 후 ByteData 로 local 저장.
// /// ... 동시에 audio files {MERGE} - [beep + sound + clapping] - by FFmpeg
// /// ..... beep: 0.5s -> merge 후 삭제
// /// ..... sound: 4.0s | 다양한 생활 소음 -> merge 후 삭제
// /// ..... clapping: 4.0s -> merge 후 경로(String) provider 저장
// /// . <Ring Alarm> 에서 Merged Audio 반복 재생.
// /// . [sound] -> soundWave 반복 재생
// /// . 그 아래에 녹음 버튼 위치
// /// ... 버튼 클릭 -> soundWave 위에 [clapping]용 soundWave 입히기
// /// ..... (compareAudios) 처리 중 -> CircularProgressIndicator 작동
// /// ... 4초 기준으로 / 틀리면 진동 길게(1.5초) | 맞으면 진동 1번 + showDialog {sound 반복 재생 수 + 틀린 횟수 + 총 걸린 시간}
//
// /// Goals
// /// . [clapping] 4.0s -> 20개 제작
// /// . [sound] 4.0s -> 20개 제작
// /// . Alarm 2개 중복 재생 시 -> Debugging
// /// . 모든 process 종료 후 -> 모든 파일 삭제
// /// . Alarm 기록 보기 페이지 생성
// /// . Alarm 설정 페이지(Main) 수정
// /// . RingAlarmNow -> 삭제
// /// . Alarm 재생 중 앱 종료 시,