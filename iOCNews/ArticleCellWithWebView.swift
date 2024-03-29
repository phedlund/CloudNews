//
//  ArticleCellWithWebView.swift
//  iOCNews
//
//  Created by Peter Hedlund on 9/3/18.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit
import WebKit

class ArticleCellWithWebView: BaseItemCell {
    
    var webConfig: WKWebViewConfiguration {
        let result = WKWebViewConfiguration()
        result.allowsInlineMediaPlayback = true
        result.mediaTypesRequiringUserActionForPlayback = [.all]
        return result
    }

    private var internalWebView: WKWebView?
    override var webView: WKWebView? {
        get {
            if internalWebView == nil {
                internalWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), configuration: self.webConfig)
                if let result = internalWebView {
                    result.isOpaque = false
                    result.backgroundColor = UIColor.clear
                }
            }
            internalWebView?.scrollView.backgroundColor = ThemeColors().pbhBackground
            return internalWebView
        }
        set(newValue) {
            internalWebView = newValue
        }
    }
    
    func addWebView() {
        if let webView = self.webView {
            contentView.addSubview(webView)
            webView.translatesAutoresizingMaskIntoConstraints = false
            
            let topConstraint = NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0.0)
            let leadingConstraint = NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1.0, constant: 0.0)
            let bottomConstraint = NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem: webView, attribute: .bottom, multiplier: 1.0, constant: 0.0)
            let trailingConstraint = NSLayoutConstraint(item: contentView, attribute: .trailing, relatedBy: .equal, toItem: webView, attribute: .trailing, multiplier: 1.0, constant: 0.0)
            contentView.addConstraints([topConstraint, leadingConstraint, bottomConstraint, trailingConstraint])
        }
    }
    
    override func prepareForReuse() {
        webView?.removeFromSuperview()
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        webView = nil
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle, let item = self.item {
            configureView(item)
        }
    }
    
    override func configureView(_ item: ItemProvider) {
        super.configureView(item)
        bottomBorder.removeFromSuperlayer()
        addWebView()
        if item.item.feedPreferWeb == true {
            if item.item.feedUseReader == true {
                if let readable = item.item.readable, readable.count > 0 {
                    writeAndLoadHtml(html: readable, feedTitle: item.feedTitle)
                } else {
                    if let urlString = item.url {
                        OCAPIClient.shared().requestSerializer = OCAPIClient.httpRequestSerializer()
                        OCAPIClient.shared().get(urlString, parameters: nil, headers: nil, progress: nil, success: { [weak self] (task, responseObject) in
                            var html: String
                            if let response = responseObject as? Data, let source = String.init(data: response, encoding: .utf8), let url = task.response?.url {
                                if let article = ArticleHelper.readble(html: source, url: url) {
                                    html = article
                                } else {
                                    html = "<p style='color: #CC6600;'><i>(An article could not be extracted. Showing summary instead.)</i></p>"
                                    if let body = item.item.body {
                                        html = html + body
                                    }
                                }
                            } else {
                                html = "<p style='color: #CC6600;'><i>(An article could not be extracted. Showing summary instead.)</i></p>"
                                if let body = item.item.body {
                                    html = html + body
                                }
                            }
                            self?.writeAndLoadHtml(html: html, feedTitle: item.feedTitle)
                        }) { [weak self]  (_, _) in
                            var html = "<p style='color: #CC6600;'><i>(There was an error downloading the article. Showing summary instead.)</i></p>"
                            if let body = item.item.body {
                                html = html + body
                            }
                            self?.writeAndLoadHtml(html: html, feedTitle: item.feedTitle)
                        }
                    }
                }
            } else {
                if let url = URL(string: item.url ?? "") {
                    webView?.load(URLRequest(url: url))
                }
            }
        } else {
            if var html = item.item.body,
                let urlString = item.url,
                let url = URL(string: urlString) {
                let baseString = "\(url.scheme ?? "")://\(url.host ?? "")"
                if baseString.range(of: "youtu", options: .caseInsensitive) != nil {
                    if html.range(of: "iframe", options: .caseInsensitive) != nil {
                        html = ArticleHelper.createYoutubeItem(html: html, urlString: urlString)
                    } else if let urlString = item.url, urlString.contains("watch?v="), let equalIndex = urlString.firstIndex(of: "=") {
                        let videoIdStartIndex = urlString.index(after: equalIndex)
                        let videoId = String(urlString[videoIdStartIndex...])
                        let screenSize = UIScreen.main.nativeBounds.size
                        let margin = SettingsStore.marginPortrait
                        let currentWidth = Double(screenSize.width / UIScreen.main.scale) * (Double(margin) / 100.0)
                        let newheight = currentWidth * 0.5625
                        let embed = "<embed id=\"yt\" src=\"http://www.youtube.com/embed/\(videoId)?playsinline=1\" type=\"text/html\" frameborder=\"0\" width=\"\(Int(currentWidth))px\" height=\"\(Int(newheight))px\"></embed>"
                        html = embed
                    }
                }
                html = ArticleHelper.fixRelativeUrl(html: html, baseUrlString: baseString)
                writeAndLoadHtml(html: html, feedTitle: item.feedTitle)
            }
        }      
    }
    
    private func writeAndLoadHtml(html: String, feedTitle: String? = nil) {
        guard let item = self.item?.item else {
            return
        }
        if let url = ArticleHelper.saveItemSummary(html: html, item: item, feedTitle: feedTitle) {
            webView?.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

}
