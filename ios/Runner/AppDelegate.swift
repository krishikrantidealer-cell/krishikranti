import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    if let controller = window?.rootViewController {
        controller.view.makeSecure()
    }
    
    return result
  }
}

extension UIView {
    func makeSecure() {
        DispatchQueue.main.async {
            let field = UITextField()
            field.isSecureTextEntry = true
            self.addSubview(field)
            
            field.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                field.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                field.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                field.widthAnchor.constraint(equalTo: self.widthAnchor),
                field.heightAnchor.constraint(equalTo: self.heightAnchor)
            ])
            
            self.layer.superlayer?.addSublayer(field.layer)
            field.layer.sublayers?.first?.addSublayer(self.layer)
            field.isUserInteractionEnabled = false
        }
    }
}
