//
//  NSNotificationExtension.swift
//  iOCNews
//
//  Created by Peter Hedlund on 3/18/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    static let themeUpdate = NSNotification.Name("ThemeUpdate")
    static let syncNews = NSNotification.Name("SyncNews")
    static let networkCompleted = NSNotification.Name("NetworkCompleted")
    static let networkError = NSNotification.Name("NetworkError")
    static let drawerOpened = NSNotification.Name("DrawerOpened")
    static let drawerClosed = NSNotification.Name("DrawerClosed")
}
