//
//  ArticleCellWithThumbnail.swift
//  iOCNews
//
//  Created by Peter Hedlund on 9/3/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import UIKit
import Kingfisher

class ArticleCellWithThumbnail: BaseArticleCell {
    @IBOutlet var contentContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var articleImage: UIImageView!
    @IBOutlet var articleImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet var articleImageWidthContraint: NSLayoutConstraint!
    @IBOutlet var titleLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var summaryLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var mainSubviewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var articleImageCenterYConstraint: NSLayoutConstraint!
    
    override func configureView() {
        super.configureView()
        guard let item = self.item else {
            return
        }
        let isCompactView = UserDefaults.standard.bool(forKey: "CompactView")
        mainSubviewHeightConstraint.constant = isCompactView ? Constants.itemHeightCompact - 1 : Constants.itemHeightRegular - 1
        if item.isSummaryTextHidden {
            summaryLabel.isHidden = true
            summaryLabel.text = nil
            summaryLabelLeadingConstraint.constant = 0
        } else {
            summaryLabel.isHidden = false
            summaryLabel.font = item.summaryFont
            summaryLabel.text = item.summaryText
            summaryLabel.setThemeTextColor(item.summaryColor)
            summaryLabel.highlightedTextColor = self.summaryLabel.textColor;
        }
        titleLabel.font = item.titleFont
        dateLabel.font = item.dateFont
                
        titleLabel.text = item.title
        dateLabel.text = item.dateText
        
        titleLabel.setThemeTextColor(item.titleColor)
        dateLabel.setThemeTextColor(item.dateColor)
        
        titleLabel.highlightedTextColor = self.titleLabel.textColor;
        dateLabel.highlightedTextColor = self.dateLabel.textColor;

        if item.isFavIconHidden {
            favIconImage.isHidden = true
            titleLabelLeadingConstraint.constant = 0
        } else {
            favIconImage.image = item.favIcon
            favIconImage.isHidden = false
            favIconImage.alpha = item.imageAlpha
            titleLabelLeadingConstraint.constant = 0
        }

        if item.isThumbnailHidden || item.imageLink == nil {
            articleImage.isHidden = true
            contentContainerLeadingConstraint.constant = 0
            articleImageWidthContraint.constant = 0
            summaryLabelLeadingConstraint.constant = 0
        } else {
            articleImage.isHidden = false
            contentContainerLeadingConstraint.constant = 10
            if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
                articleImageWidthContraint.constant = 66
                articleImageCenterYConstraint.constant = isCompactView ? 0 : -37
                summaryLabelLeadingConstraint.constant = -74
            } else {
                articleImageHeightConstraint.constant = isCompactView ? 66 : 112
                articleImageWidthContraint.constant = isCompactView ? 66 : 112
                articleImageCenterYConstraint.constant = 0
                summaryLabelLeadingConstraint.constant = 5
            }
            if (item.thumbnail != nil) {
                articleImage.image = item.thumbnail
            } else {
                if let link = item.imageLink, let url = URL(string: link) {
                    articleImage.kf.setImage(with: url)
                }
            }
        }

        articleImage.alpha = item.imageAlpha
        starImage.image = item.starIcon

        isHighlighted = false
    }

}
