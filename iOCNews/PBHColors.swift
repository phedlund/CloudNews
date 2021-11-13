//
//  PBHColors.swift
//  iOCNews
//
//  Created by Peter Hedlund on 3/26/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import Foundation

@objc
extension UIColor {
    static let pbhWhiteBackground = UIColor(named: "PHWhiteBackground")!
    static let pbhSepiaBackground = UIColor(named: "PHSepiaBackground")!
    static let pbhDarkBackground = UIColor(named: "PHDarkBackground")!

    static let pbhWhiteCellBackground = UIColor(named: "PHWhiteCellBackground")!
    static let pbhSepiaCellBackground = UIColor(named: "PHSepiaCellBackground")!
    static let pbhDarkCellBackground = UIColor(named: "PHDarkCellBackground")!

    static let pbhWhiteCellSelection = UIColor(named: "PHWhiteCellSelection")!
    static let pbhSepiaCellSelection = UIColor(named: "PHSepiaCellSelection")!
    static let pbhDarkCellSelection = UIColor(named: "PHDarkCellSelection")!

    static let pbhWhiteIcon = UIColor(named: "PHWhiteIcon")!
    static let pbhSepiaIcon = UIColor(named: "PHSepiaIcon")!
    static let pbhDarkIcon = UIColor(named: "PHDarkIcon")!

    static let pbhWhiteText = UIColor(named: "PHWhiteText")!
    static let pbhSepiaText = UIColor(named: "PHSepiaText")!
    static let pbhDarkText = UIColor(named: "PHDarkText")!

    static let pbhWhiteReadText = UIColor(named: "PHWhiteReadText")!
    static let pbhSepiaReadText = UIColor(named: "PHSepiaReadText")!
    static let pbhDarkReadText = UIColor(named: "PHDarkReadText")!

    static let pbhWhiteLink = UIColor(named: "PHWhiteLink")!
    static let pbhSepiaLink = UIColor(named: "PHSepiaLink")!
    static let pbhDarkLink = UIColor(named: "PHDarkLink")!

    static let pbhWhitePopoverBackground = UIColor(named: "PHWhitePopoverBackground")!
    static let pbhSepiaPopoverBackground = UIColor(named: "PHSepiaPopoverBackground")!
    static let pbhDarkPopoverBackground = UIColor(named: "PHDarkPopoverBackground")!

    static let pbhWhitePopoverButton = UIColor(named: "PHWhitePopoverButton")!
    static let pbhSepiaPopoverButton = UIColor(named: "PHSepiaPopoverButton")!
    static let pbhDarkPopoverButton = UIColor(named: "PHDarkPopoverButton")!

    static let pbhWhitePopoverBorder = UIColor(named: "PHWhitePopoverBorder")!
    static let pbhSepiaPopoverBorder = UIColor(named: "PHSepiaPopoverBorder")!
    static let pbhDarkPopoverBorder = UIColor(named: "PHDarkPopoverBorder")!

    static let pbhWhiteSwitch = UIColor(named: "PHWhiteSwitch")!
    static let pbhSepiaSwitch = UIColor(named: "PHSepiaSwitch")!
    static let pbhDarkSwitch = UIColor(named: "PHWhiteSwitch")!

}

@objcMembers
class ThemeColors: NSObject {

    private let backgroundColors: [UIColor] = [.pbhWhiteBackground, .pbhSepiaBackground, .pbhDarkBackground]
    private let cellBackgroundColors: [UIColor] = [.pbhWhiteCellBackground, .pbhSepiaCellBackground, .pbhDarkCellBackground]
    private let cellSelectionColors: [UIColor] = [.pbhWhiteCellSelection, .pbhSepiaCellSelection, .pbhDarkCellSelection]
    private let iconColors: [UIColor] = [.pbhWhiteIcon, .pbhSepiaIcon, .pbhDarkIcon]
    private let textColors: [UIColor] = [.pbhWhiteText, .pbhSepiaText, .pbhDarkText]
    private let readTextColors: [UIColor] = [.pbhWhiteReadText, .pbhSepiaReadText, .pbhDarkReadText]
    private let linkColors: [UIColor] = [.pbhWhiteLink, .pbhSepiaLink, .pbhDarkLink]
    private let popoverBackgroundColors: [UIColor] = [.pbhWhitePopoverBackground, .pbhSepiaPopoverBackground, .pbhDarkPopoverBackground]
    private let popoverButtonColors: [UIColor] = [.pbhWhitePopoverButton, .pbhSepiaPopoverButton, .pbhDarkPopoverButton]
    private let popoverBorderColors: [UIColor] = [.pbhWhitePopoverBorder, .pbhSepiaPopoverBorder, .pbhDarkPopoverBorder]
    private let switchColors: [UIColor] = [.pbhWhiteSwitch, .pbhSepiaSwitch, .pbhWhiteSwitch]


    lazy var pbhBackground: UIColor = {
        backgroundColors[SettingsStore.theme]
    }()

    lazy var pbhCellBackground: UIColor = {
        cellBackgroundColors[SettingsStore.theme]
    }()

    lazy var pbhcellSelection: UIColor = {
        cellSelectionColors[SettingsStore.theme]
    }()

    lazy var pbhIcon: UIColor = {
        iconColors[SettingsStore.theme]
    }()

    lazy var pbhText: UIColor = {
        textColors[SettingsStore.theme]
    }()

    lazy var pbhReadText: UIColor = {
        readTextColors[SettingsStore.theme]
    }()

    lazy var pbhLink: UIColor = {
        linkColors[SettingsStore.theme]
    }()

    lazy var pbhPopoverBackground: UIColor = {
        popoverBackgroundColors[SettingsStore.theme]
    }()

    lazy var pbhPopoverButton: UIColor = {
        popoverButtonColors[SettingsStore.theme]
    }()

    lazy var pbhPopoverBorder: UIColor = {
        popoverBorderColors[SettingsStore.theme]
    }()

    lazy var pbhSwitch: UIColor = {
        switchColors[SettingsStore.theme]
    }()

}
