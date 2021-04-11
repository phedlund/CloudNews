//
//  SharingProvider.swift
//  iOCNews
//
//  Created by Peter Hedlund on 3/24/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit

class SharingProvider: UIActivityItemProvider {

    private var subject = ""

    init(placeholderItem: Any, subject: String) {
        super.init(placeholderItem: placeholderItem)
        self.subject = subject
    }

    override var item: Any {
        self.placeholderItem as Any
    }

    override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        if activityType == .mail {
            return subject
        }
        return ""
    }

}
