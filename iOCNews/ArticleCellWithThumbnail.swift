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
    @IBOutlet var mainStackView: UIStackView!
    @IBOutlet var articleImage: UIImageView!
    @IBOutlet var favIconImage: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var summaryLabel: UILabel!

    @IBOutlet var starImage: UIImageView!

    @IBOutlet var articleImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet var articleImageWidthContraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.autoresizingMask.insert(.flexibleWidth)
        self.contentView.autoresizingMask.insert(.flexibleHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        mainStackView.frame = contentView.frame
    }

    override func configureView() {
        super.configureView()
        guard let item = self.item else {
            return
        }
        let isCompactView = SettingsStore.compactView
        if item.isThumbnailHidden || item.imageUrl == nil {
            articleImage.isHidden = true
            articleImageWidthContraint.constant = 0
        } else {
            articleImage.isHidden = false
            if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
                articleImageWidthContraint.constant = 66
            } else {
                articleImageHeightConstraint.constant = isCompactView ? 66 : 112
                articleImageWidthContraint.constant = isCompactView ? 66 : 112
            }
            articleImage.alpha = item.imageAlpha
        }
        summaryLabel.isHidden = false
        summaryLabel.font = item.summaryFont
        summaryLabel.text = item.summaryText
        summaryLabel.setThemeColor(isCompactView ? .clear : item.summaryColor)
        summaryLabel.highlightedTextColor = self.summaryLabel.textColor
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

        isHighlighted = false
    }

}
