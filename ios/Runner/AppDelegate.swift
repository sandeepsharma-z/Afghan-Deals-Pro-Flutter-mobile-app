import Flutter
import UIKit
import FirebaseCore
import FirebaseAuth

@main
@objc class AppDelegate: FlutterAppDelegate {
  // APNs token can arrive before the Dart side calls Firebase.initializeApp.
  // Keep it and hand it to Auth as soon as Firebase is configured.
  private var pendingApnsToken: Data?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Fetch the APNs device token at launch (no user prompt). Firebase Phone
    // Auth uses a silent push to verify the app; a ready APNs token keeps it
    // off the reCAPTCHA fallback that crashes on this setup.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    pendingApnsToken = deviceToken
    deliverApnsTokenToAuth(retriesLeft: 40)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Retry until Firebase is configured (Dart runs initializeApp shortly after
  // launch), then set the APNs token on Auth so phone verification uses silent
  // push and never the crashing reCAPTCHA fallback.
  private func deliverApnsTokenToAuth(retriesLeft: Int) {
    guard let token = pendingApnsToken else { return }
    if FirebaseApp.app() != nil {
      Auth.auth().setAPNSToken(token, type: .unknown)
      pendingApnsToken = nil
      return
    }
    if retriesLeft > 0 {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
        self?.deliverApnsTokenToAuth(retriesLeft: retriesLeft - 1)
      }
    }
  }

  // Let Firebase Auth consume its verification push instead of the app.
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if FirebaseApp.app() != nil, Auth.auth().canHandleNotification(userInfo) {
      completionHandler(.noData)
      return
    }
    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
  }
}
