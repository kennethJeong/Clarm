import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:Clarm/admob_helper.dart';

class Admob {
  /// 보상형 전면 광고
  void showRewardFullBanner(Function callback) {
    RewardedInterstitialAd.load(
      // adUnitId 는 "광고 단위 ID" 를 입력하도록 한다.
      adUnitId: AdHelper.rewardAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          // 기본 이벤트에 대한 정의부분
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (RewardedInterstitialAd ad, AdError error) {
              ad.dispose();
            },
          );
          // 광고를 바로 보여주도록 하고
          // 광고조건 만족시 리워드에 대한 부분(callback 함수)을 실행한다.
          ad.show(onUserEarnedReward: (ad, reward) {
            callback();
          }).then((_) => ad.dispose());
        },
        // 광고를 로드 실패하는 오류가 발생 서비스에 영향이 없도록 실행하도록 처리 했다.
        onAdFailedToLoad: (_) {
          callback();
        }
      ),
    );
  }

  /// 전면 광고
  void adLoadInterstitial(Function callback) {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          ad.show();

          ad.fullScreenContentCallback = FullScreenContentCallback(
            // Called when the ad showed the full screen content.
            onAdShowedFullScreenContent: (ad) {},
            // Called when an impression occurs on the ad.
            onAdImpression: (ad) {

            },
            // Called when the ad failed to show full screen content.
            onAdFailedToShowFullScreenContent: (ad, err) {
              // Dispose the ad here to free resources.
              ad.dispose().then((_) => callback());
            },
            onAdWillDismissFullScreenContent: (ad) {
              ad.dispose().then((_) => callback());
            },
            // Called when the ad dismissed full screen content.
            onAdDismissedFullScreenContent: (ad) {
              // Dispose the ad here to free resources.
              ad.dispose().then((_) => callback());
            },
          );
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (LoadAdError error) {
          callback();
        },
      )
    );
  }

  /// 배너 광고
  Widget widgetAdBanner(BuildContext context, double height) {
    BannerAd? adBanner;

    try {
      adBanner = Admob().adLoadBanner(context);
      adBanner.load();
    } catch(_) {
      adBanner = null;
    }

    return SizedBox(
      width: double.maxFinite,
      height: height,
      child: Center(
        child: AdWidget(ad: adBanner!),
      ),
    );
  }

  BannerAd adLoadBanner(BuildContext context) {
    // AdSize adSize = AdSize.getPortraitInlineAdaptiveBannerAdSize(
    //   MediaQuery.of(context).size.width.truncate()
    // );
    AdSize adSize = AdSize(width: MediaQuery.of(context).size.width.truncate(), height: 65);

    return BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) async {
        },
        onAdClosed: (ad) {
          ad.dispose();
        },
        onAdWillDismissScreen: (ad) {
          ad.dispose();
        },
        onAdFailedToLoad: (ad, error) {
          // Releases an ad resource when it fails to load
          ad.dispose();
        },
      ),
      size: adSize,
      request: const AdRequest(),
    );
  }
}