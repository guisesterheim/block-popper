import UIKit

/// Singleton wrapping ad SDK integration.
/// For v1, this is a stub that simulates ad behavior.
/// Replace with Google Mobile Ads SDK when AdMob app ID is configured.
///
/// Ad flow:
/// 1. Preload interstitial on app launch
/// 2. On stuck state: player taps "Use Life"
/// 3. lives -= 1 immediately (before ad shown)
/// 4. AdManager.showInterstitial called
/// 5. On ad dismiss (or 3s timeout): rescue proceeds
/// 6. AdManager reloads next interstitial in background
class AdManager {

    static let shared = AdManager()

    private var isInterstitialReady = false
    private var isShowingAd = false

    private init() {}

    // MARK: - Preload

    func preloadInterstitial() {
        // TODO: Replace with real Google Mobile Ads SDK call:
        // GADInterstitialAd.load(withAdUnitID: adUnitId, request: GADRequest()) { ... }
        self.isInterstitialReady = true
    }

    // MARK: - Show

    func showInterstitial(from viewController: UIViewController, completion: @escaping () -> Void) {
        guard self.isInterstitialReady, !self.isShowingAd else {
            // Ad not ready or already showing — skip silently
            completion()
            return
        }

        self.isShowingAd = true

        // Timeout: if ad doesn't complete in 3s, proceed anyway
        var completionCalled = false
        let safeCompletion = {
            guard !completionCalled else { return }
            completionCalled = true
            self.isShowingAd = false
            self.reloadInterstitial()
            completion()
        }

        // Schedule timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.adTimeoutSeconds) {
            safeCompletion()
        }

        // TODO: Replace with real ad presentation:
        // interstitialAd.present(fromRootViewController: viewController)
        // In the ad delegate's adDidDismissFullScreenContent, call safeCompletion()

        // Stub: simulate ad dismiss after 0.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            safeCompletion()
        }
    }

    // MARK: - Reload

    private func reloadInterstitial() {
        self.isInterstitialReady = false
        // TODO: Replace with real reload
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isInterstitialReady = true
        }
    }
}
