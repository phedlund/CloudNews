//
//  BaseCollectionViewController.swift
//  iOCNews
//
//  Created by Peter Hedlund on 4/1/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit

@objcMembers
open class BaseCollectionViewController: UIViewController {

    var collectionView: UICollectionView!

    var folderId = 0
    var aboutToFetch = false
    var reloadItemsOnUpdate = true
    var blockOperations = [BlockOperation]()

    var feed: Feed? {
        didSet {
            fetchRequest = nil
            fetchedResultsController = nil
        }
    }

    private var internalFetchRequest: NSFetchRequest<NSFetchRequestResult>?
    private var fetchRequest: NSFetchRequest<NSFetchRequestResult>? {
        get {
            if internalFetchRequest == nil, let context = OCNewsHelper.shared()?.context {
                internalFetchRequest = NSFetchRequest()
                internalFetchRequest?.entity = NSEntityDescription.entity(forEntityName: "Item", in: context)
                internalFetchRequest?.fetchBatchSize = 25
                internalFetchRequest?.sortDescriptors = [NSSortDescriptor(key: "myId", ascending: SettingsStore.sortOldestFirst)]
            }
            return internalFetchRequest
        }
        set(newValue) {
            internalFetchRequest = newValue
        }
    }

    private var internalFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? {
        get {
            if internalFetchedResultsController == nil, let context = OCNewsHelper.shared()?.context, let request = fetchRequest {

                internalFetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                              managedObjectContext: context,
                                                                              sectionNameKeyPath: nil,
                                                                              cacheName: nil)
                if !aboutToFetch {
                    return internalFetchedResultsController
                }

                var fetchPredicate: NSPredicate?
                if let feed = self.feed {
                    if feed.myId == -1 {
                        fetchPredicate = NSPredicate(format: "starred == 1")
                        fetchRequest?.fetchLimit = Int(feed.unreadCount)
                    } else {
                        if SettingsStore.hideRead {
                            if feed.myId == -2 {
                                if self.folderId > 0 {
                                    var predicateArray = [NSPredicate]()
                                    if let folderFeeds = OCNewsHelper.shared()?.feedsInFolder(withId: folderId) as? [Feed] {
                                        var fetchLimit = 0
                                        for folderFeed in folderFeeds {
                                            predicateArray.append(NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "feedId == \(folderFeed.myId)"), NSPredicate(format: "unread == 1")]))
                                            fetchLimit += Int(folderFeed.articleCount)
                                        }
                                        fetchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicateArray)
                                        internalFetchedResultsController?.fetchRequest.fetchLimit = fetchLimit
                                    }
                                } else {
                                    fetchPredicate = NSPredicate(format: "unread == 1")
                                }
                            } else {
                                let pred1 = NSPredicate(format: "feedId == \(feed.myId)")
                                let pred2 = NSPredicate(format: "unread == 1")
                                fetchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
                                internalFetchedResultsController?.fetchRequest.fetchLimit = Int(feed.articleCount)
                            }
                            internalFetchedResultsController?.delegate = nil;
                        } else {
                            if feed.myId == -2 {
                                if folderId > 0 {
                                    var feedIdsArray = [Int]()
                                    if let folderFeeds = OCNewsHelper.shared()?.feedsInFolder(withId: folderId) as? [Feed] {
                                        var fetchLimit = 0
                                        for folderFeed in folderFeeds {
                                            feedIdsArray.append(Int(folderFeed.myId))
                                            fetchLimit += Int(feed.articleCount);
                                        }
                                        fetchPredicate = NSPredicate(format: "feedId IN %@", feedIdsArray)
                                        internalFetchedResultsController?.fetchRequest.fetchLimit = fetchLimit
                                    }
                                } else {
                                    fetchPredicate = nil;
                                    internalFetchedResultsController?.fetchRequest.fetchLimit = Int(feed.articleCount)
                                }
                            } else {
                                fetchPredicate = NSPredicate(format: "feedId == \(feed.myId)")
                                internalFetchedResultsController?.fetchRequest.fetchLimit = Int(feed.articleCount)
                            }
                            internalFetchedResultsController?.delegate = self
                        }
                    }
                }
                internalFetchedResultsController?.fetchRequest.predicate = fetchPredicate
            }
            return internalFetchedResultsController
        }
        set(newValue) {
            internalFetchedResultsController = newValue
        }
    }

}

@objc
extension BaseCollectionViewController: NSFetchedResultsControllerDelegate {

    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperations.removeAll()
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let collectionView = collectionView else {
            return
        }
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath, collectionView.isIndexPathAvailable(newIndexPath) {
                let operation = BlockOperation { [weak self] in
                    self?.collectionView.insertItems(at: [newIndexPath])
                }
                blockOperations.append(operation)
            }
        case .delete:
            if let currentIndexPath = indexPath, collectionView.isIndexPathAvailable(currentIndexPath) {
                let operation = BlockOperation { [weak self] in
                    self?.collectionView.deleteItems(at: [currentIndexPath])
                }
                blockOperations.append(operation)
            }
        case .update:
            if reloadItemsOnUpdate {
                if let currentIndexPath = indexPath, collectionView.isIndexPathAvailable(currentIndexPath) {
                    let operation = BlockOperation { [weak self] in
                        self?.collectionView.reloadItems(at: [currentIndexPath])
                    }
                    blockOperations.append(operation)
                }
            }
        case .move:
            if let currentIndexPath = indexPath, let newIndexPath = newIndexPath {
                let operation = BlockOperation { [weak self] in
                    self?.collectionView.moveItem(at: currentIndexPath, to: newIndexPath)
                }
                blockOperations.append(operation)
            }
        @unknown default:
            fatalError("Unhandled type")
        }
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let collectionView = collectionView else {
            return
        }
        collectionView.performBatchUpdates {
            for operation in blockOperations {
                operation.start()
            }
        } completion: { [weak self] _ in
            self?.blockOperations.removeAll()
        }
    }

}
