//
//  BaseArticleCell.swift
//  iOCNews
//
//  Created by Peter Hedlund on 9/1/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import UIKit

@objc protocol ArticleCellProtocol {
    var item: ItemProvider? {get set}
    func configureView()
}

class BaseArticleCell: UICollectionViewCell, ArticleCellProtocol {

    var item: ItemProvider? {
        didSet {
            self.configureView()
        }
    }

    var bottomBorder = CALayer()
    
    func configureView() {
        //
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        self.selectedBackgroundView = UIView()
        self.selectedBackgroundView?.backgroundColor = UIColor.ph_cellBackground
        bottomBorder.backgroundColor = UIColor(white: 0.8, alpha: 1.0).cgColor
        self.layer.addSublayer(bottomBorder)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        let height = SettingsStore.compactView ? Constants.itemHeightCompact : Constants.itemHeightRegular
        let width = layoutAttributes.frame.size.width
        self.contentView.frame.size.width = width
        bottomBorder.frame = CGRect(x: 15, y: height - 1, width: width - 30, height: 0.5)
    }

}
