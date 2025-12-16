import UIKit
import Flutter
import Firebase
import GoogleMaps
import GooglePlaces
import UserNotifications
import FBSDKCoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Firebase
    FirebaseApp.configure()

    // Google Maps + Places: نقرأ المفتاح من Info.plist (مفتاح GMSApiKey)
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String, !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
      GMSPlacesClient.provideAPIKey(apiKey)
    } else {
      // مفيد أثناء التطوير لمعرفة سبب الكراش إذا المفتاح غير موجود
      print("⚠️ GMSApiKey not found in Info.plist")
    }

    // تفويض مركز التنبيهات
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // دعم فتح الروابط (Facebook إلخ)
  override func application(_ app: UIApplication, open url: URL,
                            options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    let handled = ApplicationDelegate.shared.application(app, open: url, options: options)
    return handled || super.application(app, open: url, options: options)
  }
}
