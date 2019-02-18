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

    @IBOutlet var mainView: UIView!
    @IBOutlet var mainSubView: UIView!
    @IBOutlet var contentContainerView: UIView!
    @IBOutlet var starContainerView: UIView!
    @IBOutlet var starImage: UIImageView!
    @IBOutlet var favIconImage: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var summaryLabel: UILabel!
    
    @IBOutlet var dateLabelLeadingConstraint: NSLayoutConstraint!
    
    var item: ItemProvider? {
        didSet {
            self.configureView()
        }
    }
    
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
        self.selectedBackgroundView?.backgroundColor = UIColor.cellBackground()
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x: 0, y: 153.0, width: 10000.0, height: 0.5)
        bottomBorder.backgroundColor = UIColor(white: 0.8, alpha: 1.0).cgColor
        self.layer.addSublayer(bottomBorder)
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        self.contentView.frame.size.width = layoutAttributes.frame.size.width
    }
    
}
