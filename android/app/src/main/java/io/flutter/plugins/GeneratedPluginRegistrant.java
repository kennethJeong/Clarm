package io.flutter.plugins;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import io.flutter.Log;

import io.flutter.embedding.engine.FlutterEngine;

/**
 * Generated file. Do not edit.
 * This file is generated by the Flutter tool based on the
 * plugins that support the Android platform.
 */
@Keep
public final class GeneratedPluginRegistrant {
  private static final String TAG = "GeneratedPluginRegistrant";
  public static void registerWith(@NonNull FlutterEngine flutterEngine) {
    try {
      flutterEngine.getPlugins().add(new com.gdelataillade.alarm.alarm.AlarmPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin alarm, com.gdelataillade.alarm.alarm.AlarmPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.simform.audio_waveforms.AudioWaveformsPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin audio_waveforms, com.simform.audio_waveforms.AudioWaveformsPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new xyz.luan.audioplayers.AudioplayersPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin audioplayers_android, xyz.luan.audioplayers.AudioplayersPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new dev.fluttercommunity.plus.device_info.DeviceInfoPlusPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin device_info_plus, dev.fluttercommunity.plus.device_info.DeviceInfoPlusPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.arthenica.ffmpegkit.flutter.FFmpegKitFlutterPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin ffmpeg_kit_flutter, com.arthenica.ffmpegkit.flutter.FFmpegKitFlutterPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.ajinasokan.flutter_fgbg.FlutterFGBGPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_fgbg, com.ajinasokan.flutter_fgbg.FlutterFGBGPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.jrai.flutter_keyboard_visibility.FlutterKeyboardVisibilityPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_keyboard_visibility, com.jrai.flutter_keyboard_visibility.FlutterKeyboardVisibilityPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_local_notifications, com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin google_mobile_ads, io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.pathprovider.PathProviderPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin path_provider_android, io.flutter.plugins.pathprovider.PathProviderPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.baseflow.permissionhandler.PermissionHandlerPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin permission_handler_android, com.baseflow.permissionhandler.PermissionHandlerPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin shared_preferences_android, io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.benjaminabel.vibration.VibrationPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin vibration, com.benjaminabel.vibration.VibrationPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.webviewflutter.WebViewFlutterPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin webview_flutter_android, io.flutter.plugins.webviewflutter.WebViewFlutterPlugin", e);
    }
  }
}
