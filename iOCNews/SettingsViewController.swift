//
//  SettingsViewController.swift
//  iOCNews
//
//  Created by Peter Hedlund on 3/10/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit
import MessageUI

@objcMembers
class SettingsViewController: UITableViewController {

    @IBOutlet var syncOnStartSwitch: UISwitch!
    @IBOutlet var syncinBackgroundSwitch: UISwitch!
    @IBOutlet var showFaviconsSwitch: UISwitch!
    @IBOutlet var showThumbnailsSwitch: UISwitch!
    @IBOutlet var markWhileScrollingSwitch: UISwitch!
    @IBOutlet var sortOldestFirstSwitch: UISwitch!
    @IBOutlet var compactViewSwitch: UISwitch!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var themeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor.ph_popoverBackground
        NotificationCenter.default.addObserver(forName: .themeUpdate, object: nil, queue: .main) { _ in
            self.tableView.backgroundColor = UIColor.ph_popoverBackground
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncOnStartSwitch.isOn = SettingsStore.syncOnStart
        syncinBackgroundSwitch.isOn = SettingsStore.syncInBackground
        showFaviconsSwitch.isOn = SettingsStore.showFavIcons
        showThumbnailsSwitch.isOn = SettingsStore.showThumbnails
        markWhileScrollingSwitch.isOn = SettingsStore.markReadWhileScrolling
        sortOldestFirstSwitch.isOn = SettingsStore.sortOldestFirst
        compactViewSwitch.isOn = SettingsStore.compactView
        let reachability = OCAPIClient.shared()?.reachabilityManager.isReachable ?? false
        if reachability {
            statusLabel.text = NSLocalizedString("Logged In", comment:"A status label indicating that the user is logged in")
        } else {
            statusLabel.text =  NSLocalizedString("Not Logged In", comment:"A status label indicating that the user is not logged in")
        }
        themeLabel.text = PHThemeManager.shared().themeName
        tableView.backgroundColor = UIColor.ph_popoverBackground
    }
    
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        44.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 3 {
            if MFMailComposeViewController.canSendMail() {
                let mailViewController = MFMailComposeViewController()
                mailViewController.mailComposeDelegate = self
                mailViewController.setToRecipients(["support@pbh.dev"])
                mailViewController.setSubject(NSLocalizedString("CloudNews Support Request", comment: "Subject of support email"))
                mailViewController.setMessageBody(NSLocalizedString("<Please state your question or problem here>", comment: "body of support email"), isHTML: false)
                mailViewController.modalPresentationStyle = .formSheet
                present(mailViewController, animated: true, completion: nil)
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.navigationItem.rightBarButtonItem = nil
    }
    
    @IBAction func onSyncOnStartChanged(_ sender: Any) {
        SettingsStore.syncOnStart = (sender as! UISwitch).isOn
    }
    
    @IBAction func onSyncInBackgroundChanged(_ sender: Any) {
        SettingsStore.syncInBackground = (sender as! UISwitch).isOn
    }
    
    @IBAction func onShowFaviconsChanged(_ sender: Any) {
        SettingsStore.showFavIcons = (sender as! UISwitch).isOn        
    }
    
    @IBAction func onShowThumbnailsChanged(_ sender: Any) {
        SettingsStore.showThumbnails = (sender as! UISwitch).isOn
    }
    
    @IBAction func onMarkWhileScrollingChanged(_ sender: Any) {
        SettingsStore.markReadWhileScrolling = (sender as! UISwitch).isOn
    }
    
    @IBAction func onSortOldestFirstChanged(_ sender: Any) {
        SettingsStore.sortOldestFirst = (sender as! UISwitch).isOn
    }
    
    @IBAction func onCompactViewChanged(_ sender: Any) {
        SettingsStore.compactView = (sender as! UISwitch).isOn
    }
    
    @IBAction func onDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
    
}
