//
//  ArticleListFlowLayout.swift
//  iOCNews
//
//  Created by Peter Hedlund on 1/15/19.
//  Copyright © 2019 Peter Hedlund. All rights reserved.
//

import UIKit

struct Constants {
    static let itemHeightRegular: CGFloat = 154
    static let itemHeightCompact: CGFloat = 75
}

@objcMembers
class ArticleListFlowLayout: UICollectionViewFlowLayout {

    private var computedContentSize: CGSize = .zero
    private var cellAttributes = [IndexPath: UICollectionViewLayoutAttributes]()
    
    override func prepare() {
        guard let cv = self.collectionView else {
            return
        }

        computedContentSize = .zero
        cellAttributes.removeAll()
        
        let itemWidth = cv.frame.size.width
        let itemHeight = UserDefaults.standard.bool(forKey: "CompactView") ? Constants.itemHeightCompact : Constants.itemHeightRegular

        for section in 0 ..< cv.numberOfSections {
            for item in 0 ..< cv.numberOfItems(inSection: section) {
                let itemFrame = CGRect(x: 0, y: CGFloat(item) * itemHeight, width: itemWidth, height: itemHeight)
                let indexPath = IndexPath(item: item, section: section)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = itemFrame
                cellAttributes[indexPath] = attributes
            }
        }
        
        computedContentSize = CGSize(width: itemWidth, height: itemHeight * CGFloat(cv.numberOfItems(inSection: 0)))
    }
    
    override var collectionViewContentSize: CGSize {
        return computedContentSize
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributeList = [UICollectionViewLayoutAttributes]()
        
        for (_, attributes) in cellAttributes {
            if attributes.frame.intersects(rect) {
                attributeList.append(attributes)
            }
        }
        
        return attributeList
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cellAttributes[indexPath]
    }
    
}
