import Flutter
import UIKit
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let voiceChannel = FlutterMethodChannel(name: "com.krishi.dealer.retailer/voice_search",
                                              binaryMessenger: controller.binaryMessenger)

    voiceChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "startVoiceSearch" {
        // iOS doesn't have a built-in system voice search UI like Android's RecognizerIntent.
        // You can use the 'speech_to_text' package already in your pubspec.yaml
        // for a cross-platform implementation.
        result(FlutterError(code: "UNAVAILABLE",
                            message: "Voice search UI is not available on iOS. Use speech_to_text plugin instead.",
                            details: nil))
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    return result
  }
}


extension AppDelegate {
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}
