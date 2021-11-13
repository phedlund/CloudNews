//
//  FeedCell.swift
//  iOCNews
//
//  Created by Peter Hedlund on 1/1/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit

@objcMembers
class FeedCell: UITableViewCell {

    var countBadge: BadgeView
   
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        countBadge = BadgeView(frame: CGRect(x: 0, y: 0, width: 55, height: 44))
        countBadge.value = 888
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        countBadge = BadgeView(frame: CGRect(x: 0, y: 0, width: 55, height: 44))
        countBadge.value = 888
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.addSubview(countBadge)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.layer.cornerRadius = 2.0
        let favIconOffset: CGFloat = 20.0

        var imageViewOffset: CGFloat = favIconOffset
        var accessoryOffset: CGFloat = 15.0

        if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
            if SettingsStore.showFavIcons {
                imageView?.frame = CGRect(x: favIconOffset, y: 10, width: 22, height: 22)
                imageViewOffset = 47
            } else {
                imageView?.frame = .zero
            }
            if #available(iOS 13, *) {
                accessoryOffset = 0
            }
            if self.accessoryType == .none {
                accessoryOffset = -20.0
                if #available(iOS 13, *) {
                    accessoryOffset = -30.0
                }
            }
            separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        } else { // regular size class
            if SettingsStore.showFavIcons {
                imageView?.frame = CGRect(x: favIconOffset, y: 10, width: 22, height: 22)
                imageViewOffset = 47
            } else {
                imageView?.frame = .zero
            }
            if #available(iOS 13, *) {
                accessoryOffset = 0
            }
            if self.accessoryType == .none {
                accessoryOffset = -20.0
                if #available(iOS 13, *) {
                    accessoryOffset = -26.0
                }
            }
            separatorInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 0)
        }

        countBadge.frame = CGRect(x: self.contentView.frame.size.width - self.countBadge.frame.size.width + accessoryOffset,
                                  y: self.countBadge.frame.origin.y,
                                  width: self.countBadge.frame.size.width,
                                  height: self.countBadge.frame.size.height)
        if let textLabel = textLabel {
            textLabel.frame = CGRect(x: imageViewOffset,
                                     y: textLabel.frame.origin.y,
                                     width: countBadge.frame.origin.x - imageViewOffset,
                                     height: textLabel.frame.size.height)
        }
    }
}
