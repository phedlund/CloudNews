//
//  ThemeSettings.swift
//  iOCNews
//
//  Created by Peter Hedlund on 3/24/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit

class ThemeSettings: UITableViewController {

    @IBOutlet var defaultCell: UITableViewCell!
    @IBOutlet var sepiaCell: UITableViewCell!
    @IBOutlet var nightCell: UITableViewCell!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = ThemeColors().pbhPopoverBackground
        NotificationCenter.default.addObserver(forName: .themeUpdate, object: nil, queue: .main) { _ in
            self.tableView.backgroundColor = ThemeColors().pbhPopoverBackground
        }
        update()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let newTheme = AppTheme(rawValue: indexPath.row) {
            ThemeManager.shared.theme = newTheme
            update()
        }
    }

    private func update() {
        defaultCell.accessoryType = .none
        sepiaCell.accessoryType = .none
        nightCell.accessoryType = .none
        switch ThemeManager.shared.theme {
        case .light:
            defaultCell.accessoryType = .checkmark
        case .sepia:
            sepiaCell.accessoryType = .checkmark
        case .dark:
            nightCell.accessoryType = .checkmark
        }
    }

}
