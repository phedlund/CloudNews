//
//  AppDelegate.swift
//  iOCNews
//
//  Created by Peter Hedlund on 3/25/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

#if !targetEnvironment(simulator)
import KSCrash_Installations
import KSCrash_Reporting_Sinks
import KSCrash_Reporting_Tools
import KSCrash_Reporting_Filters_Tools
#endif
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        #if !targetEnvironment(simulator)
        let installation = makeEmailInstallation()
        installation?.install()
        #endif
        if let svc: UISplitViewController = window?.rootViewController as? UISplitViewController {
            svc.maximumPrimaryColumnWidth = svc.primaryColumnWidth
            if #available(iOS 14.0, *) {
                svc.presentsWithGesture = true
            } else {
                svc.presentsWithGesture = false
                if let navController = svc.viewControllers.last as? UINavigationController {
                    navController.topViewController?.navigationItem.leftBarButtonItem = svc.displayModeButtonItem
                }
            }
        }
        if SettingsStore.syncInBackground {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        } else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
        }

        if let cssTemplateURL = Bundle.main.url(forResource: "rss", withExtension: "css") {
            do {
                let cssTemplate = try String(contentsOf: cssTemplateURL, encoding: .utf8)
                if let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    try cssTemplate.write(to: docDir.appendingPathComponent("rss.css"), atomically: true, encoding: .utf8)
                }
            } catch { }
        }

        #if !targetEnvironment(simulator)
        installation?.sendAllReports { (reports, completed, error) -> Void in
            if completed {
                print("Sent \(reports?.count ?? 0) reports")
            } else {
                print("Failed to send reports: \(String(describing: error))")
            }
        }
        #endif

        _ = ThemeManager.shared
        return true
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        OCNewsHelper.shared()?.sync({ result in
            completionHandler(result)
        })
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge]) { (_, _) in
            //
        }
    }

    #if !targetEnvironment(simulator)
    func makeEmailInstallation() -> KSCrashInstallation? {
        if let email = KSCrashInstallationEmail.sharedInstance() {
            let emailAddress = "support@pbh.dev";
            email.recipients = [emailAddress];
            email.subject = NSLocalizedString("CloudNews Crash Report", comment: "Crash report email subject")
            email.message = NSLocalizedString("<Please provide as much details as possible about what you were doing when the crash occurred.>", comment: "Crash report email body placeholder")
            email.filenameFmt = "crash-report-%d.txt.gz"

            email.addConditionalAlert(withTitle: NSLocalizedString("Crash Detected", comment: "Alert view title"),
                                      message: NSLocalizedString("CloudNews crashed last time it was launched. Do you want to send a report to the developer?", comment: ""),
                                      yesAnswer: NSLocalizedString("Yes, please!", comment: ""),
                                      noAnswer:NSLocalizedString("No thanks", comment: ""))

            email.setReportStyle(KSCrashEmailReportStyleApple, useDefaultFilenameFormat: true)
            return email
        }
        return nil
    }
    #endif

}
