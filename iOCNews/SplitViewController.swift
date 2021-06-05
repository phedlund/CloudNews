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
