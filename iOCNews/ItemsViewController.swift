//
//  ItemsViewController.swift
//  iOCNews
//
//  Created by Peter Hedlund on 4/3/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import Kingfisher
import UIKit

class ItemsViewController: BaseCollectionViewController {

    @IBOutlet var markBarButton: UIBarButtonItem!
    @IBOutlet var sideGestureRecognizer: UIScreenEdgePanGestureRecognizer!
    @IBOutlet var markGestureRecognizer: UISwipeGestureRecognizer!

    private var fetchedItems = [Item]()
    private var itemProviderOperationQueue = OperationQueue()
    private var operations = [IndexPath: BlockOperation]()
    private var fetchedItemProviders = [IndexPath: ItemProvider]()
    private var observers = [NSObjectProtocol]()
    private var networkErrorObserver: NSObjectProtocol?
    private var markingAllItemsRead = false
    private var comingFromDetail = false

    private lazy var refreshControl: UIRefreshControl =  {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        return  refreshControl
    }()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        UserDefaults.standard.addObserver(self, forKeyPath: SettingKeys.hideRead, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: SettingKeys.showThumbnails, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: SettingKeys.showFavIcons, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: SettingKeys.sortOldestFirst, options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: SettingKeys.compactView, options: .new, context: nil)
    }

    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: SettingKeys.hideRead)
        UserDefaults.standard.removeObserver(self, forKeyPath: SettingKeys.showThumbnails)
        UserDefaults.standard.removeObserver(self, forKeyPath: SettingKeys.showFavIcons)
        UserDefaults.standard.removeObserver(self, forKeyPath: SettingKeys.sortOldestFirst)
        UserDefaults.standard.removeObserver(self, forKeyPath: SettingKeys.compactView)
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        fetchedResultsController?.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationItem.leftItemsSupplementBackButton = true
        if #available(iOS 14.0, *) {
            //
        } else {
            navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        }
        navigationItem.rightBarButtonItem = markBarButton
        markBarButton.isEnabled = false
        collectionView.register(UINib(nibName: "ArticleCellWithThumbnail", bundle: nil), forCellWithReuseIdentifier: "ArticleCellWithThumbnail")
        collectionView.scrollsToTop = false
        collectionView.addGestureRecognizer(markGestureRecognizer)
        collectionView.addGestureRecognizer(sideGestureRecognizer)

        aboutToFetch = false

        observers.append(NotificationCenter.default.addObserver(forName: .networkCompleted, object: nil, queue: .main, using: {[weak self] _ in
            self?.refreshControl.endRefreshing()
        }))
        observers.append(NotificationCenter.default.addObserver(forName: .drawerOpened, object: nil, queue: .main, using: { [weak self] _ in
            NotificationCenter.default.removeObserver(self?.networkErrorObserver as Any)
            self?.collectionView.scrollsToTop = false
        }))
        observers.append(NotificationCenter.default.addObserver(forName: .drawerClosed, object: nil, queue: .main, using: { [weak self] _ in
            self?.networkErrorObserver = NotificationCenter.default.addObserver(forName: .networkError, object: self, queue: .main) { notification in
                if let title = notification.userInfo?["Title"] as? String, let body = notification.userInfo?["Message"] as? String {
                    Messenger.showMessage(title: title, body: body, theme: .error)
                }
            }
            self?.collectionView.scrollsToTop = true
        }))
        observers.append(NotificationCenter.default.addObserver(forName: .themeUpdate, object: nil, queue: .main, using: {[weak self] _ in
            self?.collectionView.reloadData()
        }))
        observers.append(NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: OCNewsHelper.shared()?.context, queue: .main, using: { [weak self] _ in
            self?.contextSaved()
        }))
        observers.append(NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.collectionView.reloadData()
        }))
        observers.append(NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main, using: { [weak self] _ in
            if let visibleItems = self?.collectionView.indexPathsForVisibleItems {
                self?.collectionView.reloadItems(at: visibleItems)
            }
        }))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !comingFromDetail {
            configureView()
        }
        comingFromDetail = false
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showArticleSegue", let articleController = segue.destination as? ArticleViewController {
            articleController.feed = feed
            articleController.folderId = folderId;
            articleController.aboutToFetch = true
            do {
                try articleController.fetchedResultsController?.performFetch()
                articleController.aboutToFetch = false
                if let item = sender as? Item, let items = fetchedResultsController?.fetchedObjects as? [Item] {
                    articleController.selectedArticle = item
                    articleController.items = items
                    articleController.articleListController = self
                    comingFromDetail = true
                }
            } catch { }
        }
    }

    // MARK: - Public Functions

    func createItemProvider(for indexPath: IndexPath, preFetching: Bool = true) -> ItemProvider? {
        guard collectionView.isIndexPathAvailable(indexPath),
              let item = fetchedResultsController?.object(at: indexPath) as? Item,
              let feed = OCNewsHelper.shared()?.feed(withId: Int(item.feedId)) else {
            return nil
        }

        var itemData = ItemProviderStruct()
        itemData.title = item.title
        itemData.myID = Int(item.myId)
        itemData.author = item.author
        itemData.pubDate = Int(item.pubDate)
        itemData.body = item.body
        itemData.feedId = Int(item.feedId)
        itemData.starred = item.starred
        itemData.unread = item.unread
        itemData.imageLink = item.imageLink
        itemData.readable = item.readable
        itemData.url = item.url
        itemData.favIconLink = feed.faviconLink
        itemData.feedTitle = feed.title
        itemData.feedPreferWeb = feed.preferWeb
        itemData.feedUseReader = feed.useReader
        let provider = ItemProvider(item: itemData)

        if preFetching {
            let blockOperation = BlockOperation()
            blockOperation.addExecutionBlock { [weak self, weak blockOperation] in
                if blockOperation?.isCancelled ?? false {
                    self?.operations[indexPath] = nil
                    return
                }
                DispatchQueue.main.async {
                    if let visibleCells = self?.collectionView.indexPathsForVisibleItems, visibleCells.contains(indexPath),
                       let cell = self?.collectionView.cellForItem(at: indexPath) as? BaseArticleCell {
                        cell.item = provider
                    }
                }
            }
            
            itemProviderOperationQueue.addOperation(blockOperation)
            operations[indexPath] = blockOperation
        }
        fetchedItemProviders[indexPath] = provider
        return provider
    }

    // MARK: - Private Functions

    private func unreadCount() -> Int {
        var result = 0
        if let feed = feed {
            if feed.myId == -2 && folderId > 0 {
                let folder = OCNewsHelper.shared()?.folder(withId: folderId)
                result = Int(folder?.unreadCount ?? 0)
            } else {
                result = Int(feed.unreadCount)
            }
        }
        return result
    }

    private func contextSaved() {
        if markingAllItemsRead {
            markingAllItemsRead = false
            aboutToFetch = true
            do {
                try fetchedResultsController?.performFetch()
                self.aboutToFetch = false
                fetchedItems = fetchedResultsController?.fetchedObjects as? [Item] ?? [Item]()
                refresh()
            } catch { }
        }
    }

    private func refresh() {
        let unreadCount = self.unreadCount
        collectionView?.reloadData()
        markBarButton.isEnabled = unreadCount() > 0
    }

    private func cancelCellPrefetch(for indexPath: IndexPath) {
        if let operation = operations[indexPath] {
            operation.cancel()
            operations[indexPath] = nil
        }
    }

    func configureView() {
        if let feed = self.feed {
            if feed.myId == -2 {
                if let folder = OCNewsHelper.shared()?.folder(withId: folderId) {
                    if let folderName = folder.name, !folderName.isEmpty {
                        if SettingsStore.hideRead {
                            navigationItem.title = String(format: "All Unread %@ Articles", folderName)
                        } else {
                            navigationItem.title = String(format: "All %@ Articles", folderName)
                        }
                    } else {
                        navigationItem.title = feed.title
                    }
                }
            } else {
                self.navigationItem.title = feed.title
            }
            aboutToFetch = true
            do {
                try fetchedResultsController?.performFetch()
                aboutToFetch = false
                fetchedItems = fetchedResultsController?.fetchedObjects as? [Item] ?? [Item]()
                let unreadCount = self.unreadCount
                collectionView?.reloadData()
                markBarButton.isEnabled = unreadCount() > 0
            } catch {
                fetchedItems = [Item]()
                navigationItem.title = feed.title
            }
            if feed.myId > -2 {
                collectionView?.refreshControl = refreshControl
            } else {
                collectionView?.refreshControl = nil
            }
            refresh()
            if !comingFromDetail {
                if fetchedItems.count > 0 {
                    collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
                }
            }
            collectionView?.scrollsToTop = true
        }
    }

    private func updateUnreadCount(itemsToUpdate: [Int32], at indexPaths: [IndexPath]) {
            let set = Set(itemsToUpdate)
            let nsSet = NSMutableSet(set: set)
            OCNewsHelper.shared()?.markItemsReadOffline(nsSet)
            for indexPath in indexPaths {
                _ = createItemProvider(for: indexPath)
            }
            refresh()
    }

    private func markRowsRead() {
        if SettingsStore.markReadWhileScrolling {
            var unreadCount = self.unreadCount()
            if unreadCount > 0 {
                let visibleCells = self.collectionView.indexPathsForVisibleItems
                if visibleCells.count > 0 {
                    let items = visibleCells.map { $0.item }
                    let topVisibleRow = items.min()
                    if let fetchedItems = fetchedResultsController?.fetchedObjects as? [Item] {
                        var idsToMarkRead = [Int32]()
                        var indexPaths = [IndexPath]()
                        for (index, item) in fetchedItems.enumerated() {
                            if index > topVisibleRow ?? 0 {
                                break
                            }
                            if item.unread {
                                item.unread = false
                                indexPaths.append(IndexPath(item: index, section: 0))
                                idsToMarkRead.append(item.myId)
                            }
                        }
                        unreadCount = unreadCount - idsToMarkRead.count
                        updateUnreadCount(itemsToUpdate: idsToMarkRead, at: indexPaths)
                        markBarButton.isEnabled = (unreadCount > 0)
                    }
                }
            }
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath {
            switch keyPath {
            case "HideRead", "ShowThumbnails", "ShowFavicons", "CompactView":
                refresh()
            case "SortOldestFirst":
                let sortDescriptor = NSSortDescriptor(key: "myId", ascending: SettingsStore.sortOldestFirst)
                fetchedResultsController?.fetchRequest.sortDescriptors = [sortDescriptor]
                refresh()
            default:
                break
           }
        }
    }

    @IBAction func onRefresh(_ sender: Any) {
        if let feed = feed {
            OCNewsHelper.shared()?.updateFeed(withId: Int(feed.myId))
        }
    }

    @IBAction func onMarkRead(_ sender: Any) {
        markingAllItemsRead = true
        var idsToMarkRead = [Int32]()
        var indexPaths = [IndexPath]()
        let unreadCount = self.unreadCount()
        if unreadCount > 0 {
            if let fetchedItems = fetchedResultsController?.fetchedObjects as? [Item] {

                for (index, item) in fetchedItems.enumerated() {
                    if item.unread {
                        item.unread = false
                        idsToMarkRead.append(item.myId)
                        indexPaths.append(IndexPath(item: index, section: 0))
                    }
                }
            }
        }

        markBarButton.isEnabled = false
        if (traitCollection.horizontalSizeClass == .compact) {
            navigationController?.navigationController?.popToRootViewController(animated: true)
        } else {
            UIView.animate(withDuration: 0.3) { [weak self] in
                if self?.traitCollection.userInterfaceIdiom == .pad {
                    self?.splitViewController?.preferredDisplayMode = .allVisible
                } else {
                    if UIApplication.shared.statusBarOrientation.isLandscape {
                        self?.splitViewController?.preferredDisplayMode = .allVisible
                    } else {
                        self?.splitViewController?.preferredDisplayMode = .automatic
                    }
                }
            }
        }
        self.updateUnreadCount(itemsToUpdate: idsToMarkRead, at: indexPaths)
    }

    @IBAction func onCellSwipe(_ gestureRecognizer: UISwipeGestureRecognizer) {
        //http://stackoverflow.com/a/14364085/2036378 (why it's sometimes a good idea to retrieve the cell)
        if gestureRecognizer.state == .ended {
            let point = gestureRecognizer.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: point),
               indexPath.section == 0,
               let item = fetchedResultsController?.object(at: indexPath) as? Item {
                if item.unread {
                    item.unread = false
                    updateUnreadCount(itemsToUpdate: [item.myId], at: [indexPath])
                } else {
                    if (item.starred) {
                        item.starred = false
                        OCNewsHelper.shared().unstarItemOffline(Int(item.myId))
                    } else {
                        item.starred = true
                        OCNewsHelper.shared()?.starItemOffline(Int(item.myId))
                    }
                }
            }
        }
    }

    @IBAction func onSideGestureRecognizer(_ sender: Any) {
        if sideGestureRecognizer.translation(in: collectionView).x > 10 {
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.splitViewController?.preferredDisplayMode = .allVisible
            } completion: { [weak self] finished in
                if finished {
                    self?.collectionView.reloadData()
                }
            }
        }
    }

}

extension ItemsViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var result = true
        if gestureRecognizer == markGestureRecognizer,
           traitCollection.horizontalSizeClass != .compact,
           splitViewController?.displayMode != .primaryHidden {
            result = false
        }
        return result
    }

}

extension ItemsViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let selectedItem = fetchedResultsController?.object(at: indexPath) as? Item {
        let id = selectedItem.myId
            splitViewController?.preferredDisplayMode = .primaryHidden
            navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(), style: .plain, target: nil, action: nil)
            performSegue(withIdentifier: "showArticleSegue", sender: selectedItem)
            if selectedItem.unread {
                selectedItem.unread = false
            }
            updateUnreadCount(itemsToUpdate: [id], at: [indexPath])
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }

}

extension ItemsViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var result = 0
        if feed != nil, let sectionInfo = fetchedResultsController?.sections?[section] {
            result = sectionInfo.numberOfObjects
        }
        return result
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArticleCellWithThumbnail", for: indexPath) as? ArticleCellWithThumbnail {
            if let itemProvider = fetchedItemProviders[indexPath] {
                cell.item = itemProvider
            } else {
                cell.item = createItemProvider(for: indexPath, preFetching: false)
            }
            return cell
        }
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let articleCell = cell as? ArticleCellWithThumbnail, let item = articleCell.item {
            if !item.isFavIconHidden, let url = item.favIconUrl {
                KF.url(url)
                    .loadDiskFileSynchronously()
                    .set(to: articleCell.favIconImage)
            }
            if !item.isThumbnailHidden, let url = item.imageUrl {
                KF.url(url)
                    .loadDiskFileSynchronously()
                    .set(to: articleCell.articleImage)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let articleCell = cell as? ArticleCellWithThumbnail {
            articleCell.favIconImage.kf.cancelDownloadTask()
            articleCell.articleImage.kf.cancelDownloadTask()
        }
    }

}

extension ItemsViewController: UICollectionViewDataSourcePrefetching {

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard fetchedItemProviders[indexPath] != nil else {
                _ = createItemProvider(for: indexPath)
                return
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if operations[indexPath] != nil {
                cancelCellPrefetch(for: indexPath)
            }
        }
    }

}

extension ItemsViewController: UIScrollViewDelegate {

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            markRowsRead()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        markRowsRead()
    }

}
