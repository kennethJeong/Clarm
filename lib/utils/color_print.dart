import 'dart:io';

void printRed(String text) {
  if(Platform.isAndroid) {
    print('🟥🟥🟥 \x1B[31m$text\x1B[0m');
  } else {
    print("🟥🟥🟥: $text");
  }
}
void printGreen(String text) {
  if(Platform.isAndroid) {
    print('🟩🟩🟩 \x1B[32m$text\x1B[0m');
  } else {
    print("🟩🟩🟩: $text");
  }
}