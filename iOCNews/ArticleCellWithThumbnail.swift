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
    @IBOutlet var articleImage: UIImageView!
    @IBOutlet var favIconImage: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var summaryLabelRegular: UILabel!
    @IBOutlet var summaryLabelCompact: UILabel!
    @IBOutlet var starContainerView: UIView!
    @IBOutlet var starImage: UIImageView!

    @IBOutlet var contentContainerToThumbnailLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var contentContainerToMainLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var articleImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet var articleImageWidthContraint: NSLayoutConstraint!
    @IBOutlet var compactSummaryTopConstraint: NSLayoutConstraint!
    @IBOutlet var compactSummaryVerticalConstraint: NSLayoutConstraint!
    
    override func configureView() {
        super.configureView()
        guard let item = self.item else {
            return
        }
        let isCompactView = SettingsStore.compactView
        if isCompactView {
            summaryLabelRegular.isHidden = true
            summaryLabelRegular.text = nil

            summaryLabelCompact.isHidden = true
            summaryLabelCompact.text = nil
        } else {
            summaryLabelRegular.isHidden = false
            summaryLabelRegular.font = item.summaryFont
            summaryLabelRegular.text = item.summaryText
            summaryLabelRegular.setThemeColor(item.summaryColor)
            summaryLabelRegular.highlightedTextColor = self.summaryLabelRegular.textColor

            summaryLabelCompact.isHidden = false
            summaryLabelCompact.font = item.summaryFont
            summaryLabelCompact.text = item.summaryText
            summaryLabelCompact.setThemeColor(item.summaryColor)
            summaryLabelCompact.highlightedTextColor = self.summaryLabelCompact.textColor
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
        favIconImage.isHidden = !SettingsStore.showFavIcons
        favIconImage.alpha = item.imageAlpha

        if !SettingsStore.showThumbnails || item.imageUrl == nil {
            hideItemImage()
            if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
                compactSummaryTopConstraint.isActive = false
                compactSummaryVerticalConstraint.constant = 8
            } else {
                compactSummaryTopConstraint.isActive = false
                compactSummaryVerticalConstraint.isActive = false
            }
        } else {
            showItemImage()
            if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
                compactSummaryVerticalConstraint.isActive = false
            } else {
                compactSummaryTopConstraint.isActive = false
                compactSummaryVerticalConstraint.isActive = false
            }
            articleImage.alpha = item.imageAlpha
        }

        isHighlighted = false
    }

    func hideItemImage() {
        articleImage.isHidden = true
        articleImageWidthContraint.isActive = false
        articleImageWidthContraint.constant = 0
        contentContainerToThumbnailLeadingConstraint.isActive = true
        contentContainerToMainLeadingConstraint.isActive = true
        if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
            contentContainerToThumbnailLeadingConstraint.constant = 0
            contentContainerToMainLeadingConstraint.constant = 0
        } else {
            contentContainerToThumbnailLeadingConstraint.constant = 0
            contentContainerToMainLeadingConstraint.constant = 10
        }
    }

    func showItemImage() {
        let isCompactView = SettingsStore.compactView
        contentContainerToMainLeadingConstraint.isActive = false
        contentContainerToThumbnailLeadingConstraint.isActive = true
        contentContainerToThumbnailLeadingConstraint.constant = 10
        articleImage.isHidden = false
        articleImageWidthContraint.isActive = true
        if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
            articleImageWidthContraint.constant = 66
        } else {
            articleImageHeightConstraint.constant = isCompactView ? 66 : 112
            articleImageWidthContraint.constant = isCompactView ? 66 : 112
        }
    }

}
