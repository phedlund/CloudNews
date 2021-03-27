//
//  SettingsStore.swift
//  iOCNotes
//
//  Created by Peter Hedlund on 6/18/19.
//  Copyright © 2019-2021 Peter Hedlund. All rights reserved.
//

import Foundation
import KeychainAccess

@objcMembers
class SettingKeys: NSObject {
    static let username = String(kSecAttrAccount)
    static let password = String(kSecValueData)
    static let server = "Server"
    static let newsVersion = "Version"
    static let syncOnStart = "SyncOnStart"
    static let offlineMode = "OfflineMode"
    static let isloggedIn = "LoggedIn"
    static let allowUntrustedCertificate = "AllowUntrustedCertificate"
    static let dbReset = "dbReset"
    static let syncInBackground = "SyncInBackground"
    static let lastModified = "LastModified"
    static let category = "category"
    static let starred = "Starred"
    static let unread = "Unread"
    static let fontSize = "FontSize"
    static let lineHeight = "LineHeight"
    static let marginPortrait = "MarginPortrait"
    static let marginLandscape = "MarginLandscape"
    static let showFavIcons = "ShowFavicons"
    static let showThumbnails = "ShowThumbnails"
    static let compactView = "CompactView"
    static let theme = "CurrentTheme"
    static let markReadWhileScrolling = "MarkWhileScrolling"
    static let sortOldestFirst = "SortOldestFirst"
    static let hideRead = "HideRead"
    static let previousPasteboardURL = "PreviousPasteboardURL"
    static let backgrounds = "Backgrounds"
    static let foldersToAdd = "FoldersToAdd"
    static let foldersToDelete = "FoldersToDelete"
    static let foldersToRename = "FoldersToRename"
    static let feedsToAdd = "FeedsToAdd"
    static let feedsToDelete = "FeedsToDelete"
    static let feedsToRename = "FeedsToRename"
    static let feedsToMove = "FeedsToMove"
    static let itemsToMarkRead = "ItemsToMarkRead"
    static let itemsToMarkUnread = "ItemsToMarkUnread"
    static let itemsToStar = "ItemsToStar"
    static let itemsToUnstar = "ItemsToUnstar"
}

@propertyWrapper class UserDefaultsBacked<Value> {
    let key: String
    let defaultValue: Value
    var storage: UserDefaults = .standard

    init(key: String, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: Value {
        get {
            let value = storage.value(forKey: key) as? Value
            return value ?? defaultValue
        }
        set {
            storage.setValue(newValue, forKey: key)
        }
    }
}

@propertyWrapper struct KeychainBacked<String> {
    let key: String
    let defaultValue: String
    var storage = Keychain(service: "com.peterandlinda.iOCNews")
        .accessibility(.afterFirstUnlock)

    var wrappedValue: String {
        get {
            let value = storage["\(key)"] as? String
            return value ?? defaultValue
        }
        set {
            storage["\(key)"] = (newValue as! Swift.String)
        }
    }
}

@objcMembers
class SettingsStore: NSObject {

    @KeychainBacked(key: SettingKeys.username, defaultValue: "")
    static var username: String

    @KeychainBacked(key: SettingKeys.password, defaultValue: "")
    static var password: String

    @UserDefaultsBacked(key: SettingKeys.server, defaultValue: "")
    static var server: String

    @UserDefaultsBacked(key: SettingKeys.newsVersion, defaultValue: "")
    static var newsVersion: String
    
    @UserDefaultsBacked(key: SettingKeys.allowUntrustedCertificate, defaultValue: false)
    static var allowUntrustedCertificate: Bool

    @UserDefaultsBacked(key: SettingKeys.dbReset, defaultValue: false)
    var dbReset: Bool

    @UserDefaultsBacked(key: SettingKeys.syncOnStart, defaultValue: false)
    static var syncOnStart: Bool

    @UserDefaultsBacked(key: SettingKeys.syncInBackground, defaultValue: false)
    static var syncInBackground: Bool

    @UserDefaultsBacked(key: SettingKeys.lastModified, defaultValue: 0)
    static var lastModified: Int

    @UserDefaultsBacked(key: SettingKeys.starred, defaultValue: false)
    static var starred: Bool

    @UserDefaultsBacked(key: SettingKeys.unread, defaultValue: false)
    static var unread: Bool

    @UserDefaultsBacked(key: SettingKeys.fontSize, defaultValue: 13) // TODO 16 for iPad
    static var fontSize: Int

    @UserDefaultsBacked(key: SettingKeys.lineHeight, defaultValue: 1.4)
    static var lineHeight: Double

    @UserDefaultsBacked(key: SettingKeys.marginPortrait, defaultValue: 70)
    static var marginPortrait: Int

    @UserDefaultsBacked(key: SettingKeys.marginLandscape, defaultValue: 70)
    static var marginLandscape: Int

    @UserDefaultsBacked(key: SettingKeys.showFavIcons, defaultValue: true)
    static var showFavIcons: Bool

    @UserDefaultsBacked(key: SettingKeys.showThumbnails, defaultValue: true)
    static var showThumbnails: Bool

    @UserDefaultsBacked(key: SettingKeys.compactView, defaultValue: false)
    static var compactView: Bool

    @UserDefaultsBacked(key: SettingKeys.theme, defaultValue: 0)
    static var theme: Int

    @UserDefaultsBacked(key: SettingKeys.markReadWhileScrolling, defaultValue: true)
    static var markReadWhileScrolling: Bool

    @UserDefaultsBacked(key: SettingKeys.sortOldestFirst, defaultValue: false)
    static var sortOldestFirst: Bool

    @UserDefaultsBacked(key: SettingKeys.hideRead, defaultValue: false)
    static var hideRead: Bool

    @UserDefaultsBacked(key: SettingKeys.previousPasteboardURL, defaultValue: "")
    static var previousPasteboardURL: String

    @UserDefaultsBacked(key: SettingKeys.backgrounds, defaultValue: ["#FFFFFF", "#F5EFDC", "#000000"])
    static var backgrounds: [String]

    @UserDefaultsBacked(key: SettingKeys.foldersToAdd, defaultValue: [])
    static var foldersToAdd: [String]

    @UserDefaultsBacked(key: SettingKeys.foldersToDelete, defaultValue: [])
    static var foldersToDelete: [String]

    @UserDefaultsBacked(key: SettingKeys.foldersToRename, defaultValue: [])
    static var foldersToRename: [String]

    @UserDefaultsBacked(key: SettingKeys.feedsToAdd, defaultValue: [])
    static var feedsToAdd: [String]

    @UserDefaultsBacked(key: SettingKeys.feedsToDelete, defaultValue: [])
    static var feedsToDelete: [String]

    @UserDefaultsBacked(key: SettingKeys.feedsToRename, defaultValue: [])
    static var feedsToRename: [String]

    @UserDefaultsBacked(key: SettingKeys.feedsToMove, defaultValue: [])
    static var feedsToMove: [String]

    @UserDefaultsBacked(key: SettingKeys.itemsToMarkRead, defaultValue: [])
    static var itemsToMarkRead: [Int]

    @UserDefaultsBacked(key: SettingKeys.itemsToMarkUnread, defaultValue: [])
    static var itemsToMarkUnread: [Int]

    @UserDefaultsBacked(key: SettingKeys.itemsToStar, defaultValue: [])
    static var itemsToStar: [Int]

    @UserDefaultsBacked(key: SettingKeys.itemsToUnstar, defaultValue: [])
    static var itemsToUnstar: [Int]

}
