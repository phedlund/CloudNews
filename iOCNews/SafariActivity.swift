import UIKit

class SafariActivity: UIActivity {
    
    private var activityURL: URL?

    override init() {
        super.init()
    }
    
    override var activityType: UIActivity.ActivityType? {
        UIActivity.ActivityType("SafariActivity")
    }

    override var activityTitle: String? {
        NSLocalizedString("Open in Safari", comment: "Title for Open In Safari activity")
    }
    
    override var activityImage: UIImage? {
        UIImage(named: "safari")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if let url = item as? URL, UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if let url = item as? URL {
                activityURL = url
            }
        }
    }
    
    override func perform() {
        if let url = activityURL {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:]) { success in
                    self.activityDidFinish(success)
                }
            } else {
                let completed = UIApplication.shared.openURL(url)
                self.activityDidFinish(completed)

            }
        }
    }
    
}
