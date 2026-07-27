import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Prime the APNs device token at launch so Firebase Phone Auth uses
    // silent-push app verification instead of the reCAPTCHA fallback (which
    // needs a reversed-client-id URL scheme this app doesn't have and would
    // otherwise crash on entering the phone number). This does NOT prompt the
    // user — it only fetches the APNs token, which Firebase's swizzling
    // forwards to both Messaging and Auth.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
