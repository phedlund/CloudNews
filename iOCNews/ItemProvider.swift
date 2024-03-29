//
//  ItemProvider.swift
//  iOCNews
//
//  Created by Peter Hedlund on 2/14/19.
//  Copyright © 2019 Peter Hedlund. All rights reserved.
//

import Foundation

struct ItemProviderStruct {
    var myID: Int = -1
    var title: String?
    var author: String?
    var pubDate: Int = 0
    var body: String?
    var feedId: Int = -1
    var starred: Bool = false
    var unread: Bool = true
    var imageLink: String?
    var favIconLink: String?
    var readable: String?
    var url: String?

    var feedTitle: String?
    var feedPreferWeb: Bool = false
    var feedUseReader: Bool = false
}


struct ItemProvider {
    
    var item: ItemProviderStruct

    var titleFont: UIFont {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        }
        return UIFont.systemFont(ofSize: 17.0, weight: .semibold)
    }

    var dateFont: UIFont {
        let font = UIFont.preferredFont(forTextStyle: .subheadline)
        let desc = font.fontDescriptor
        if let italic = desc.withSymbolicTraits(.traitItalic) {
            return UIFont(descriptor: italic, size: 0.0)
        }
        return font
    }
    
    var summaryFont: UIFont {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let desc = font.fontDescriptor
        let smaller = desc.withSize(desc.pointSize - 1)
        return UIFont(descriptor: smaller, size: 0.0)
    }
    
    var title: String = ""
    var dateText: String = ""
    var summaryText: String = ""
    var isSummaryTextHidden = false
    var titleColor: UIColor = .black
    var dateColor: UIColor = .black
    var summaryColor: UIColor = .black
    var imageAlpha: CGFloat = 1.0
    var isFavIconHidden: Bool = false
    var isThumbnailHidden: Bool = false
    var starIcon: UIImage?
    var url: String?
    var starred: Bool = false
    var unread: Bool = true
    var myId: Int = -1
    var favIconUrl: URL?
    var feedTitle: String?
    var imageUrl: URL?

    init(item: ItemProviderStruct) {
        self.item = item
        self.url = item.url
        self.starred = item.starred
        self.unread = item.unread
        self.myId = item.myID
        self.feedTitle = item.feedTitle
        self.isFavIconHidden = !SettingsStore.showFavIcons
        self.isThumbnailHidden = !SettingsStore.showThumbnails
        isSummaryTextHidden = SettingsStore.compactView

        if let link = item.imageLink, let url = URL(string: link), let scheme = url.scheme, ArticleImage.validSchemas.contains(scheme) {
            self.imageUrl = url
        }
        if let link = item.favIconLink, link != "favicon", let url = URL(string: link), let scheme = url.scheme, ArticleImage.validSchemas.contains(scheme) {
            self.favIconUrl = url
        } else if let itemUrl = URL(string: item.url ?? ""), let host = itemUrl.host, let url = URL(string: "https://icons.duckduckgo.com/ip3/\(host).ico") {
            self.favIconUrl = url
        } else {
            self.favIconUrl = URL.localURLForXCAsset(name: "favicon")
        }
        
        let title = item.title
        self.title = title?.convertingHTMLToPlainText() ?? ""
        var dateLabelText = ""
        let date = Date(timeIntervalSince1970: TimeInterval(item.pubDate))
        let currentLocale = Locale.current
        let dateComponents = "MMM d"
        let dateFormatString = DateFormatter.dateFormat(fromTemplate: dateComponents, options: 0, locale: currentLocale)
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = dateFormatString
        dateLabelText = dateLabelText + dateFormat.string(from: date)
        
        if dateLabelText.count > 0 {
            dateLabelText = dateLabelText  + " | "
        }
        
        if let author = item.author {
            if author.count > 0 {
                let clipLength = UIDevice.current.userInterfaceIdiom == .pad ? 50 : 25
                if author.count > clipLength {
                    dateLabelText = dateLabelText + author.prefix(clipLength)
                } else {
                    dateLabelText = dateLabelText + author
                }
            }
        }
        
        if let title = self.feedTitle {
            if let author = item.author, author.count > 0 {
                if title != author {
                    dateLabelText = dateLabelText + " | "
                }
            }
            dateLabelText = dateLabelText + title
        }
        self.dateText = dateLabelText
        
        
        if var summary = item.body {
            if summary.range(of: "<style>", options: .caseInsensitive) != nil {
                if summary.range(of: "</style>", options: .caseInsensitive) != nil {
                    if let start = summary.range(of:"<style>", options: .caseInsensitive)?.lowerBound , let end = summary.range(of: "</style>", options: .caseInsensitive)?.upperBound {
                        let sub = summary[start..<end]
                        summary = summary.replacingOccurrences(of: sub, with: "")
                    }
                }
            }
            self.summaryText = summary.convertingHTMLToPlainText()
            if item.starred {
                self.starIcon = UIImage(named: "star_icon")
            }
            if item.unread == true {
                self.summaryColor = ThemeColors().pbhText
                self.titleColor = ThemeColors().pbhText
                self.dateColor = ThemeColors().pbhText
                self.imageAlpha = 1.0
            } else {
                self.summaryColor = ThemeColors().pbhReadText
                self.titleColor = ThemeColors().pbhReadText
                self.dateColor = ThemeColors().pbhReadText
                self.imageAlpha = 0.4
            }
        }
        
    }
}

extension URL {

    static func localURLForXCAsset(name: String) -> URL? {
        let fileManager = FileManager.default
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {return nil}
        let url = cacheDirectory.appendingPathComponent("\(name)").appendingPathExtension("png")
        let path = url.path
        if !fileManager.fileExists(atPath: path) {
            guard let image = UIImage(named: name), let data = image.pngData() else {
                return nil
            }
            fileManager.createFile(atPath: path, contents: data, attributes: nil)
        }
        return url
    }

}
