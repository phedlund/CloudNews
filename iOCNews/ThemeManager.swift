//
//  ThemeManager.swift
//  iOCNews
//
//  Created by Peter Hedlund on 3/27/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit
import WebKit

enum AppTheme: Int {
    case light = 0
    case sepia = 1
    case dark = 2
}

extension AppTheme: CustomStringConvertible {
    var description: String {
        switch self {
        case .light:
            return NSLocalizedString("Default", comment: "Name of the default theme")
        case .sepia:
            return NSLocalizedString("Sepia", comment: "Name of the sepia theme")
        case .dark:
            return NSLocalizedString("Night", comment: "Name of the night theme")
       }
    }
}

extension UILabel {

    @objc func setThemeColor(_ color: UIColor) {
        textColor = color
    }

}

@objcMembers
class ThemeManager: NSObject {

    static let shared = ThemeManager()
    var theme: AppTheme {
        get {
            AppTheme(rawValue: SettingsStore.theme) ?? .light
        }
        set {
            updateTheme(theme: newValue)
        }
    }

    override init() {
        super.init()
        updateTheme(theme: AppTheme(rawValue: SettingsStore.theme) ?? .light)
    }

    private func updateTheme(theme: AppTheme) {
        SettingsStore.theme = theme.rawValue
        let themeColors = ThemeColors()

        if let window = UIApplication.shared.delegate?.window {
            window?.tintColor = themeColors.pbhIcon
        }

        UINavigationBar.appearance().barTintColor = themeColors.pbhPopoverButton
        var titleAttributes = Dictionary<NSAttributedString.Key, Any>()
        titleAttributes[NSAttributedString.Key.foregroundColor] = themeColors.pbhText
        UINavigationBar.appearance().titleTextAttributes = titleAttributes
        UINavigationBar.appearance().tintColor = themeColors.pbhIcon

        UIBarButtonItem.appearance().tintColor = themeColors.pbhText

        UITableViewCell.appearance().backgroundColor = themeColors.pbhCellBackground

        UIView.appearance(whenContainedInInstancesOf: [ItemsViewController.self]).backgroundColor = themeColors.pbhBackground
        UIView.appearance(whenContainedInInstancesOf: [FeedCell.self]).backgroundColor = themeColors.pbhPopoverBackground
        UIView.appearance(whenContainedInInstancesOf: [OCFeedListController.self]).backgroundColor = themeColors.pbhPopoverBackground
        UIView.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).backgroundColor = themeColors.pbhPopoverButton

        UICollectionView.appearance(whenContainedInInstancesOf: [ItemsViewController.self]).backgroundColor = themeColors.pbhCellBackground
        UICollectionView.appearance(whenContainedInInstancesOf: [ArticleViewController.self]).backgroundColor = themeColors.pbhCellBackground
        UITableView.appearance(whenContainedInInstancesOf: [OCFeedListController.self]).backgroundColor = themeColors.pbhPopoverBackground
        UITableView.appearance(whenContainedInInstancesOf: [SettingsViewController.self]).backgroundColor = themeColors.pbhPopoverBackground
        UITableView.appearance(whenContainedInInstancesOf: [ThemeSettings.self]).backgroundColor = themeColors.pbhPopoverBackground

        UIScrollView.appearance().backgroundColor = themeColors.pbhCellBackground
        UIScrollView.appearance(whenContainedInInstancesOf: [OCFeedListController.self]).backgroundColor = themeColors.pbhPopoverBackground

        UILabel.appearance().setThemeColor(themeColors.pbhText)

        UISwitch.appearance().onTintColor = themeColors.pbhPopoverBorder
        UISwitch.appearance().tintColor = themeColors.pbhPopoverBorder

        WKWebView.appearance().backgroundColor = themeColors.pbhCellBackground

        UILabel.appearance(whenContainedInInstancesOf: [UITextField.self]).setThemeColor(themeColors.pbhReadText)
        UITextField.appearance().textColor = themeColors.pbhText
        UITextView.appearance().textColor = themeColors.pbhText
        UIStepper.appearance().tintColor = themeColors.pbhText

        let windows = UIApplication.shared.windows

        for window in windows {
            for view in window.subviews {
                view.removeFromSuperview()
                window.addSubview(view)
            }
        }

        NotificationCenter.default.post(name: .themeUpdate, object: self)
    }

}
