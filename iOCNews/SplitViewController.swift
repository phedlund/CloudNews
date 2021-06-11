//
//  SplitViewController.swift
//  iOCNews
//
//  Created by Peter Hedlund on 5/28/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.traitCollection.userInterfaceIdiom == .phone {
            self.delegate = self
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UIDevice.current.userInterfaceIdiom == .pad {
            if #available(iOS 14, *) {
                preferredDisplayMode = .oneBesideSecondary
            } else {
                preferredDisplayMode = .allVisible
            }
        } else {
            preferredDisplayMode = .automatic
        }
    }

}

extension SplitViewController: UISplitViewControllerDelegate {

    func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode {
        if svc.displayMode == .primaryHidden {
            if svc.traitCollection.horizontalSizeClass == .regular {
                if svc.traitCollection.userInterfaceIdiom == .pad {
                    return .allVisible
                } else if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
                    return .allVisible
                }
            }
            return .primaryOverlay
        }
        return .primaryHidden
    }

    @available(iOS 14.0, *)
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        .primary
    }

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if self.traitCollection.userInterfaceIdiom == .phone {
            if self.traitCollection.horizontalSizeClass == .compact {
                return true
            }
        }
        return false
    }

    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        if #available(iOS 14.0, *) {
            print("Display Mode: \(displayMode.rawValue)")
            let notification = Notification(name: .displayModeChanged, object: nil, userInfo: ["NewMode" : displayMode])
            NotificationCenter.default.post(notification)
        }
    }


}

