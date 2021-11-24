//
//  BaseItemCell.swift
//  iOCNews
//
//  Created by Peter Hedlund on 9/1/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import UIKit
import WebKit

protocol ItemCellProtocol {
    var item: ItemProvider? { get }
    var webView: WKWebView? { get set }
    func configureView(_ item: ItemProvider)
}

class BaseItemCell: UICollectionViewCell, ItemCellProtocol {
    var webView: WKWebView?

    private (set) var item: ItemProvider?

    var bottomBorder = CALayer()
    var starred: Bool {
        get {
            item?.starred ?? false
        }
        set {
            item?.starred = newValue
        }
    }
    var unread: Bool {
        get {
            item?.unread ?? true
        }
        set {
            item?.unread = newValue
        }
    }

    func configureView(_ item: ItemProvider) {
        self.item = item
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
        self.selectedBackgroundView?.backgroundColor = ThemeColors().pbhCellBackground
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
