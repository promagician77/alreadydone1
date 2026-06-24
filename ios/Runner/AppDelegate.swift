import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)

    // Request notification permission
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Match AuthTheme.warmWhite (#F9F7F4) so iOS home-transition snapshots
    // don't flash pure white around the app icon.
    let warmWhite = UIColor(
      red: 249.0 / 255.0,
      green: 247.0 / 255.0,
      blue: 244.0 / 255.0,
      alpha: 1.0
    )
    window?.backgroundColor = warmWhite
    window?.rootViewController?.view.backgroundColor = warmWhite

    return result
  }

  // Forward APNs token to Firebase - THIS IS THE KEY PART
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Show notification banner, sound, badge when app is in foreground (iOS default is to hide)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge, .list])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}