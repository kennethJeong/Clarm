import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdHelper {
  // 배너 광고
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['admob_aos_unitId_banner_test'].toString();
    } else if (Platform.isIOS) {
      return dotenv.env['admob_ios_unitId_banner_test'].toString();
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  // 전면 광고
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['admob_aos_unitId_interstitial_test'].toString();
    } else if (Platform.isIOS) {
      return dotenv.env['admob_ios_unitId_interstitial_test'].toString();
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  // 보상형 전면 광고
  static String get rewardAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['admob_aos_unitId_reward_test'].toString();
    } else if (Platform.isIOS) {
      return dotenv.env['admob_ios_unitId_reward_test'].toString();
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }
}