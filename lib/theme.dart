import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyTheme {
  static ThemeData lightThemeData = themeData();  // 실제 쓸 때는 요걸로 쓸 거임

  static ThemeData themeData() {  // 실제 ThemeData 만듬
    final base = ThemeData.light();
    return base.copyWith(
      textTheme: _buildEllasNotesTextTheme(base.textTheme),

      // ...
      // textTheme 외에도 appBarTheme, primaryTheme, colorScheme 등 override 할 수 있는 항목 매우 많음
    );
  }

  static TextTheme _buildEllasNotesTextTheme(TextTheme base) {  // TextTheme 생성
    return base.copyWith(
      titleLarge: GoogleFonts.robotoSlab(textStyle: base.titleLarge), // main text
      bodyMedium: GoogleFonts.nanumGothic(textStyle: base.bodyMedium), // note
      // ...
    );
  }

  static String fontFamilyDefault = 'Happiness-Sans';
  static Color primaryColor = const Color(0xff7f54ad);
  // static Color secondaryColor = const Color(0xff7f54ad);

  // 기본 테마
  static ThemeData themeDefault = ThemeData(
    fontFamily: fontFamilyDefault,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      color: Colors.transparent
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 17,
        color: Colors.blueAccent
      ),
      titleLarge: TextStyle(
        color: Colors.black,
        fontSize: 17,
      ),
      titleMedium: TextStyle(
        color: Colors.black,
        fontSize: 14,
      ),
      titleSmall: TextStyle(
        color: Colors.black,
        fontSize: 9,
      ),
      bodyMedium: TextStyle(
        color: Colors.black,
        fontSize: 14,
      ),
      displayMedium: TextStyle(
        fontSize: 300
      )
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(
        color: Colors.black26,
        fontSize: 14,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      modalBackgroundColor: Colors.white
    ),
    switchTheme: const SwitchThemeData(
      trackOutlineWidth: WidgetStatePropertyAll(0),
      trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.grey.shade100,
    ),
  );

  // 기본 테마
  static ThemeData themeDarkMode = ThemeData(
    fontFamily: fontFamilyDefault,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      color: Colors.transparent
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 17,
        color: Colors.blueAccent
      ),
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 17,
      ),
      titleMedium: TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      titleSmall: TextStyle(
        color: Colors.white,
        fontSize: 9,
      ),
      bodyMedium: TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(
        color: Colors.white30,
        fontSize: 14,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      modalBackgroundColor: Color(0xff151515),
    ),
    switchTheme: const SwitchThemeData(
      trackOutlineWidth: WidgetStatePropertyAll(0),
      trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.grey.shade900,
    ),

  );

  static ThemeData themeDefaultShowPicker = ThemeData(
    brightness: Brightness.light,
    textTheme: const TextTheme(
      displayMedium: TextStyle(
        fontSize: 300
      )
    ),
  );

  static ThemeData themeDarkModeShowPicker = ThemeData(
    brightness: Brightness.dark,
    textTheme: const TextTheme(
      displayMedium: TextStyle(
        fontSize: 300
      )
    ),
  );

}