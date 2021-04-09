//
//  ArticleSettings.swift
//  iOCNews
//
//  Created by Peter Hedlund on 3/28/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit

@objc
protocol ArticleSettingsDelegate {
    var starred: Bool { get }
    var unread: Bool { get }
    func settingsChanged(_ reload: Bool)
}

@objcMembers
class ArticleSettings: UIViewController {

    @IBOutlet var markUnreadButton: UIButton!
    @IBOutlet var starButton: UIButton!
    @IBOutlet var decreaseFontSizeButton: UIButton!
    @IBOutlet var increaseFontSizeButton: UIButton!
    @IBOutlet var decreaseLineHeightButton: UIButton!
    @IBOutlet var increaseLineHeightButton: UIButton!
    @IBOutlet var decreaseMarginButton: UIButton!
    @IBOutlet var increaseMarginButton: UIButton!

    private let minFontSize = (UI_USER_INTERFACE_IDIOM() == .pad ? 11 : 9)
    private let maxFontSize = 30
    private let minLineHeight = 1.2
    private let maxLineHeight = 2.6
    private let minMarginWidth = 45 //%
    private let maxMarginWidth = 95 //%

    private var starred = false
    private var unread = false
    var delegate: ArticleSettingsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        configure(button: starButton)
        configure(button: markUnreadButton)
        configure(button: decreaseFontSizeButton)
        configure(button: increaseFontSizeButton)
        configure(button: decreaseLineHeightButton)
        configure(button: increaseLineHeightButton)
        configure(button: decreaseMarginButton)
        configure(button: increaseMarginButton)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTheming()
        starred = false
        unread = false
        if delegate != nil {
            starred = delegate?.starred ?? false
            SettingsStore.starred = starred;
            if starred {
                starButton.setImage(UIImage(named: "starred"), for: .normal)
            } else {
                starButton.setImage(UIImage(named: "unstarred"), for: .normal)
            }
            unread = delegate?.unread ?? false
            SettingsStore.unread = unread;
            if unread {
                markUnreadButton.setImage(UIImage(named: "unread"), for: .normal)
            } else {
                markUnreadButton.setImage(UIImage(named: "read"), for: .normal)
            }
        }
    }
    
    @IBAction func onButton(_ sender: UIButton) {

        var reload = true

        switch sender {
        case starButton:
            starred = !starred
            SettingsStore.starred = starred
            if starred {
                starButton.setImage(UIImage(named: "starred"), for: .normal)
            } else {
                starButton.setImage(UIImage(named: "unstarred"), for: .normal)
            }
            reload = false
        case markUnreadButton:
            unread = !unread
            SettingsStore.unread = unread
            if unread {
                markUnreadButton.setImage(UIImage(named: "unread"), for: .normal)
            } else {
                markUnreadButton.setImage(UIImage(named: "read"), for: .normal)
            }
            reload = false
        case decreaseFontSizeButton:
            var currentFontSize = SettingsStore.fontSize
            if currentFontSize > minFontSize {
                currentFontSize -= 1
            }
            SettingsStore.fontSize = currentFontSize

        case increaseFontSizeButton:
            var currentFontSize = SettingsStore.fontSize
            if currentFontSize < maxFontSize {
                currentFontSize += 1
            }
            SettingsStore.fontSize = currentFontSize
        case decreaseLineHeightButton:
            var currentLineHeight = SettingsStore.lineHeight
            if currentLineHeight > minLineHeight {
                currentLineHeight = currentLineHeight - 0.2
            }
            SettingsStore.lineHeight = currentLineHeight;

        case increaseLineHeightButton:
            var currentLineHeight = SettingsStore.lineHeight
            if currentLineHeight < maxLineHeight {
                currentLineHeight = currentLineHeight + 0.2
            }
            SettingsStore.lineHeight = currentLineHeight;
        case decreaseMarginButton:
            if UIApplication.shared.statusBarOrientation.isPortrait {
                var currentMargin = SettingsStore.marginPortrait
                if currentMargin < maxMarginWidth {
                    currentMargin += 5
                }
                SettingsStore.marginPortrait = currentMargin;
            } else {
                var currentMarginLandscape = SettingsStore.marginLandscape
                if currentMarginLandscape < maxMarginWidth {
                    currentMarginLandscape += 5
                }
                SettingsStore.marginLandscape = currentMarginLandscape
            }
        case increaseMarginButton:
            if UIApplication.shared.statusBarOrientation.isPortrait {
                var currentMargin = SettingsStore.marginPortrait
                if currentMargin > minMarginWidth {
                    currentMargin -= 5
                }
                SettingsStore.marginPortrait = currentMargin
            } else {
                var currentMarginLandscape = SettingsStore.marginLandscape
                if currentMarginLandscape > minMarginWidth {
                    currentMarginLandscape -= 5
                }
                SettingsStore.marginLandscape = currentMarginLandscape
            }
        default:
            break
        }

        delegate?.settingsChanged(reload)
    }

    private func configure(button: UIButton) {
        button.layer.cornerRadius = 8.0
        button.layer.masksToBounds = true
        button.layer.borderWidth = 0.75
        button.layer.borderColor = UIColor.darkGray.cgColor
    }

    private func updateTheming() {
        let themeColors = ThemeColors()
        view.backgroundColor = themeColors.pbhPopoverBackground;
        updateTheming(button: starButton, colors: themeColors)
        updateTheming(button: markUnreadButton, colors: themeColors)
        updateTheming(button: decreaseFontSizeButton, colors: themeColors)
        updateTheming(button: increaseFontSizeButton, colors: themeColors)
        updateTheming(button: decreaseLineHeightButton, colors: themeColors)
        updateTheming(button: increaseLineHeightButton, colors: themeColors)
        updateTheming(button: decreaseMarginButton, colors: themeColors)
        updateTheming(button: increaseMarginButton, colors: themeColors)
    }

    private func updateTheming(button: UIButton, colors: ThemeColors) {
        button.backgroundColor = colors.pbhPopoverButton
        button.layer.borderColor = colors.pbhPopoverBorder.cgColor
        button.tintColor = colors.pbhIcon
    }
}
