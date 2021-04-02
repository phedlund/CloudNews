//
//  CollectionViewExtension.swift
//  iOCNews
//
//  Created by Peter Hedlund on 4/1/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit

@objc
extension UICollectionView {

    func isIndexPathAvailable(_ indexPath: IndexPath) -> Bool {
        var result = false
        if dataSource != nil {
            if indexPath.section < numberOfSections, indexPath.item < numberOfItems(inSection: indexPath.section) {
                result = true
            }
        }
        return result
    }

    func scrollToItemIfAvailable(_ indexPath: IndexPath, atScrollPosition scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        if isIndexPathAvailable(indexPath) {
            scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }

}
