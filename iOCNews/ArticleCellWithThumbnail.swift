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
    @IBOutlet var mainSubView: UIView!
    @IBOutlet var contentContainerView: UIView!
    @IBOutlet var articleImage: UIImageView!
    @IBOutlet var favIconImage: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var summaryLabel: UILabel!
    @IBOutlet var starContainerView: UIView!
    @IBOutlet var starImage: UIImageView!

    @IBOutlet var contentContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var articleImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet var articleImageWidthContraint: NSLayoutConstraint!
    @IBOutlet var stackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var summaryLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var articleImageCenterYConstraint: NSLayoutConstraint!
    @IBOutlet var summaryLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet var summaryLabelVerticalSpacingConstraint: NSLayoutConstraint!
    @IBOutlet var titleStackviewHeightConstriant: NSLayoutConstraint!
    @IBOutlet var contentBottomToStackViewConstraint: NSLayoutConstraint!
    @IBOutlet var contentBottomToSummaryConstraint: NSLayoutConstraint!

    override func configureView() {
        super.configureView()
        guard let item = self.item else {
            return
        }
        let isCompactView = SettingsStore.compactView
        if isCompactView {
            stackViewLeadingConstraint.constant = 0
            summaryLabel.isHidden = true
            summaryLabel.text = nil
            summaryLabelLeadingConstraint.constant = 0
            summaryLabelTopConstraint.isActive = false
            summaryLabelVerticalSpacingConstraint.isActive = false
            titleStackviewHeightConstriant.isActive = true
            contentBottomToStackViewConstraint.isActive = true
            contentBottomToSummaryConstraint.isActive = false
        } else {
            summaryLabel.isHidden = false
            summaryLabel.font = item.summaryFont
            summaryLabel.text = item.summaryText
            summaryLabel.setThemeColor(item.summaryColor)
            summaryLabel.highlightedTextColor = self.summaryLabel.textColor
            summaryLabelTopConstraint.isActive = UIScreen.main.traitCollection.horizontalSizeClass == .regular
            summaryLabelVerticalSpacingConstraint.isActive = UIScreen.main.traitCollection.horizontalSizeClass == .regular
            titleStackviewHeightConstriant.isActive = false
            contentBottomToStackViewConstraint.isActive = false
            contentBottomToSummaryConstraint.isActive = true
        }
        titleLabel.font = item.titleFont
        dateLabel.font = item.dateFont
                
        titleLabel.text = item.title
        dateLabel.text = item.dateText
        
        titleLabel.setThemeColor(item.titleColor)
        dateLabel.setThemeColor(item.dateColor)
        
        titleLabel.highlightedTextColor = self.titleLabel.textColor;
        dateLabel.highlightedTextColor = self.dateLabel.textColor;

        starImage.image = item.starIcon
        favIconImage.isHidden = item.isFavIconHidden
        favIconImage.alpha = item.imageAlpha

        summaryLabelTopConstraint.constant = 76
        if item.isThumbnailHidden || item.imageUrl == nil {
            articleImage.isHidden = true
            contentContainerLeadingConstraint.constant = 0
            stackViewLeadingConstraint.constant = 0
            articleImageWidthContraint.constant = 0
            summaryLabelLeadingConstraint.constant = 0
            summaryLabelVerticalSpacingConstraint.isActive = UIScreen.main.traitCollection.horizontalSizeClass == .compact
        } else {
            articleImage.isHidden = false
            contentContainerLeadingConstraint.constant = 10
            if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
                articleImageWidthContraint.constant = 66
                articleImageCenterYConstraint.constant = isCompactView ? 0 : -37
                stackViewLeadingConstraint.constant = 0
                summaryLabelTopConstraint.isActive = true
                summaryLabelLeadingConstraint.constant = -74
            } else {
                articleImageHeightConstraint.constant = isCompactView ? 66 : 112
                articleImageWidthContraint.constant = isCompactView ? 66 : 112
                articleImageCenterYConstraint.constant = 0
                stackViewLeadingConstraint.constant = 5
                summaryLabelLeadingConstraint.constant = 5
            }
            articleImage.alpha = item.imageAlpha
        }

        isHighlighted = false
    }

}
