//
//  ItemsPageViewController.swift
//  iOCNews
//
//  Created by Peter Hedlund on 4/2/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit
import WebKit

class ItemsPageViewController: BaseCollectionViewController {

    @IBOutlet var backBarButton: UIBarButtonItem!
    @IBOutlet var forwardBarButton: UIBarButtonItem!
    @IBOutlet var reloadBarButton: UIBarButtonItem!
    @IBOutlet var stopBarButton: UIBarButtonItem!
    @IBOutlet var menuBarButton: UIBarButtonItem!
    @IBOutlet var actionBarButton: UIBarButtonItem!

    var selectedArticle: Item?
    var items = [Item]()
    var articleListController: ItemsListViewController?

    private var settingsPresentationController: UIPopoverPresentationController?
    private var currentCell: ArticleCellWithWebView?
    private var shouldScrollToInitialArticle = true
    private var loadingComplete = false
    private var loadingSummary = false

    private var isShowingASummary: Bool {
        var result = true
        if let webView = currentCell?.webView, let url = webView.url {
            result = url.scheme == "file" || url.scheme == "about"
        }
        return result
    }

    private var currentIndexPath: IndexPath {
        let currentPage = collectionView.contentOffset.x / collectionView.frame.size.width
        return IndexPath(item: Int(currentPage), section: 0)
    }

    private lazy var settingsViewController: ArticleSettings? = {
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "preferences") as? ArticleSettings {
            viewController.preferredContentSize = CGSize(width: 220, height: 245)
            viewController.modalPresentationStyle = .popover
            viewController.delegate = self
            return viewController
        }
        return nil
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        reloadItemsOnUpdate = false
        collectionView.register(ArticleCellWithWebView.self, forCellWithReuseIdentifier: "ArticleCellWithWebView")
        view.backgroundColor = ThemeColors().pbhBackground
        NotificationCenter.default.addObserver(forName: .themeUpdate, object: nil, queue: .main) { _ in
            self.view.backgroundColor = ThemeColors().pbhBackground
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        shouldScrollToInitialArticle = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if shouldScrollToInitialArticle {
            if let selectedArticle = self.selectedArticle, let itemIndex = items.firstIndex(of: selectedArticle) {
                let indexPath = IndexPath(item: itemIndex, section: 0)
                if let layout = collectionView.collectionViewLayout as? ArticleFlowLayout {
                    if let cell = collectionView(collectionView, cellForItemAt: indexPath) as? ArticleCellWithWebView {
                        currentCell = cell
                    }
                    layout.currentIndexPath = indexPath
                    collectionView.scrollToItemIfAvailable(indexPath, atScrollPosition: .top, animated: false)
                }
                if selectedArticle.unread {
                    self.selectedArticle?.unread = false
                    let set = Set([selectedArticle.myId])
                    let nsSet = NSMutableSet(set: set)
                    OCNewsHelper.shared().markItemsReadOffline(nsSet)
                }
                updateNavigationItemTitle()
            }
        }
    }

    // MARK: - Private Functions

    private func updateNavigationItemTitle() {
        if UIScreen.main.bounds.size.width > 414 { //should cover any phone in landscape and iPad
            if currentCell != nil {
                if !loadingComplete && loadingSummary {
                    navigationItem.title = currentCell?.item?.title
                } else {
                    navigationItem.title = currentCell?.webView?.title
                }
            } else {
                navigationItem.title = ""
            }
        } else {
            navigationItem.title = ""
        }
    }

    private func updateToolbar() {
        backBarButton.isEnabled = currentCell?.webView?.canGoBack ?? false
        forwardBarButton.isEnabled = currentCell?.webView?.canGoForward ?? false
        let refreshStopBarButtonItem = loadingComplete ? reloadBarButton : stopBarButton
        if currentCell != nil {
            actionBarButton.isEnabled = loadingComplete
            menuBarButton.isEnabled = loadingComplete
            refreshStopBarButtonItem?.isEnabled = true
        } else {
            actionBarButton.isEnabled = false
            menuBarButton.isEnabled = false
            refreshStopBarButtonItem?.isEnabled = false
        }
        navigationItem.leftItemsSupplementBackButton = true
        if #available(iOS 14.0, *) {
            navigationItem.leftBarButtonItems = [backBarButton, forwardBarButton, refreshStopBarButtonItem!]
        } else {
            if let modeButton = splitViewController?.displayModeButtonItem {
                navigationItem.leftBarButtonItems = [modeButton, backBarButton, forwardBarButton, refreshStopBarButtonItem!]
            } else {
                navigationItem.leftBarButtonItems = [backBarButton, forwardBarButton, refreshStopBarButtonItem!]
            }
        }

    }

    // MARK: - Actions

    @IBAction func onBackBarButton(_ sender: Any) {
        if currentCell?.webView?.canGoBack ?? false {
            _ = currentCell?.webView?.goBack()
        }
    }

    @IBAction func onForwardBarButton(_ sender: Any) {
        if currentCell?.webView?.canGoForward ?? false {
            _ = currentCell?.webView?.goForward()
        }
    }

    @IBAction func onReloadButton(_ sender: Any) {
        _ = currentCell?.webView?.reload()
    }

    @IBAction func onStopBarButton(_ sender: Any) {
        currentCell?.webView?.stopLoading()
        updateToolbar()
    }

    @IBAction func onMenuBarButton(_ sender: Any) {
        if let settingsViewController = settingsViewController,
           let settingsPresentationController = settingsViewController.popoverPresentationController {
            settingsPresentationController.delegate = self
            settingsPresentationController.barButtonItem = menuBarButton
            settingsPresentationController.permittedArrowDirections = .any
            settingsPresentationController.backgroundColor = ThemeColors().pbhPopoverBackground
            present(settingsViewController, animated: true, completion: nil)
        }
    }

    @IBAction func onActionBarButton(_ sender: Any) {
        var url: URL?
        var subject = ""
        if let webView = currentCell?.webView {
            url = webView.url
            subject = webView.title ?? ""
            if url?.absoluteString.hasSuffix("Documents/summary.html") ?? false {
                if let item = currentCell?.item, let urlString = item.url {
                    url = URL(string: urlString) ?? nil
                    subject = item.title
                }
            }
        }
        if let theUrl = url {
            let safariActivity = SafariActivity()
            let activities = [safariActivity]
            let sharingProvider = SharingProvider(placeholderItem: theUrl, subject: subject)
            let activityViewController = UIActivityViewController(activityItems: [sharingProvider], applicationActivities: activities)
            activityViewController.modalPresentationStyle = .popover
            present(activityViewController, animated:true, completion:nil)
            let presentationController = activityViewController.popoverPresentationController
            presentationController?.permittedArrowDirections = .any
            presentationController?.barButtonItem = actionBarButton
        }
    }
    
}

extension ItemsPageViewController: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let collectionView = scrollView as? UICollectionView {
            let indexPath = currentIndexPath
            if let cell = collectionView.cellForItem(at: indexPath) as? ArticleCellWithWebView {
                currentCell = cell
            }
                if let layout = collectionView.collectionViewLayout as? ArticleFlowLayout {
                    layout.currentIndexPath = indexPath
                }
            let item = items[indexPath.item]
            if item.unread {
                item.unread = false
                let set = Set([item.myId])
                let nsSet = NSMutableSet(set: set)
                OCNewsHelper.shared().markItemsReadOffline(nsSet)
                _ = articleListController?.createItemProvider(for: indexPath)
            }
            articleListController?.collectionView.scrollToItemIfAvailable(indexPath, atScrollPosition: .top, animated: false)
            updateNavigationItemTitle()
            updateToolbar()
        }
    }
}

extension ItemsPageViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("Getting cell for \(indexPath.description)")
        if let articleCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArticleCellWithWebView", for: indexPath) as? ArticleCellWithWebView {
            let cellItem = items[indexPath.item]
            let feed = OCNewsHelper.shared()?.feed(withId: Int(cellItem.feedId))
            var itemData = ItemProviderStruct()
            itemData.title = cellItem.title
            itemData.myID = Int(cellItem.myId)
            itemData.author = cellItem.author
            itemData.pubDate = Int(cellItem.pubDate)
            itemData.body = cellItem.body
            itemData.feedId = Int(cellItem.feedId)
            itemData.starred = cellItem.starred
            itemData.unread = cellItem.unread
            itemData.imageLink = cellItem.imageLink
            itemData.readable = cellItem.readable
            itemData.url = cellItem.url
            itemData.favIconLink = feed?.faviconLink
            itemData.feedTitle = feed?.title
            itemData.feedPreferWeb = feed?.preferWeb ?? false
            itemData.feedUseReader = feed?.useReader ?? false
            let provider = ItemProvider(item: itemData)
            articleCell.configureView(provider)
            if currentCell == nil {
                currentCell = articleCell
            }
            articleCell.webView?.navigationDelegate = self
            articleCell.webView?.uiDelegate = self
            return articleCell;
        } else  {
            return UICollectionViewCell()
        }
    }

}

extension ItemsPageViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if webView.url?.scheme == "file" || webView.url?.scheme?.hasPrefix("itms") ?? false {
            if let url = navigationAction.request.url {
                if url.absoluteString.contains("itunes.apple.com") || url.absoluteString.contains("apps.apple.com") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    decisionHandler(.cancel)
                    return
                }
                if navigationAction.navigationType != .other {
                    loadingSummary = url.scheme == "file" || url.scheme == "about"
                }
            }
        }
        decisionHandler(.allow);
        loadingComplete = false
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        updateToolbar()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        updateToolbar()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        updateToolbar()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.readyState") { [weak self] (response, error) in
            if let responseString = response as? String {
                if responseString == "complete" {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self?.loadingComplete = true
                    self?.updateNavigationItemTitle()
                }
            }
            self?.updateToolbar()
        }
    }

}

extension ItemsPageViewController: WKUIDelegate {

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if !(navigationAction.targetFrame?.isMainFrame ?? false) {
            webView.load(navigationAction.request)
        }
        return nil
    }

}

extension ItemsPageViewController: ArticleSettingsDelegate {
    var starred: Bool {
        get {
            currentCell?.item?.starred ?? false
        }
    }

    var unread: Bool {
        get {
            currentCell?.item?.unread ?? true
        }
    }

    func settingsChanged(_ reload: Bool) {
        let starred = SettingsStore.starred
        let unread = SettingsStore.unread
        articleListController?.updateItem(for: currentIndexPath, starred: starred, unread: unread)

        if starred != currentCell?.starred {
            currentCell?.starred = starred
            _ = articleListController?.createItemProvider(for: currentIndexPath)
            if let item = currentCell?.item {
                if starred {
                    OCNewsHelper.shared().starItemOffline(item.myId)
                } else {
                    OCNewsHelper.shared().unstarItemOffline(item.myId)
                }
            }
        }

        if unread != currentCell?.unread {
            currentCell?.unread = unread
            _ = articleListController?.createItemProvider(for: currentIndexPath)
            if let item = currentCell?.item {
                if unread {
                    OCNewsHelper.shared().markItemUnreadOffline(item.myId)
                } else {
                    let set = Set([item.myId])
                    let nsSet = NSMutableSet(set: set)
                    OCNewsHelper.shared().markItemsReadOffline(nsSet)
                }
            }
        }

        if currentCell?.webView != nil && reload {
            currentCell?.prepareForReuse()
            if let item = currentCell?.item {
                currentCell?.configureView(item)
            }
        }
    }

}

extension ItemsPageViewController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        .none
    }

}
