//
//  FeedSettings.swift
//  iOCNews
//
//  Created by Peter Hedlund on 3/18/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit

@objc
protocol FeedSettingsDelegate {
    func feedSettingsUpdate(settings: FeedSettings)
}

@objcMembers
class FeedSettings: UITableViewController {
    
    @IBOutlet var urlTextView: NewsTextView!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var fullArticleSwitch: UISwitch!
    @IBOutlet var readerModeSwitch: UISwitch!
    @IBOutlet var keepCountLabel: UILabel!
    @IBOutlet var keepCountStepper: UIStepper!
    
    var newFolderId = 0
    var delegate: FeedSettingsDelegate?
    var feed: Feed?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 44
        tableView.backgroundColor = UIColor.ph_popoverBackground
        NotificationCenter.default.addObserver(forName: .themeUpdate, object: nil, queue: .main) { _ in
            self.tableView.backgroundColor = UIColor.ph_popoverBackground
        }
        refresh()
    }
    
    private func refresh() {
        if let feed = self.feed {
            tableView.beginUpdates()
            urlTextView.text = feed.url
            titleTextField.text = feed.title
            fullArticleSwitch.isOn = feed.preferWeb
            readerModeSwitch.isOn = feed.useReader
            readerModeSwitch.isEnabled = fullArticleSwitch.isOn
            keepCountStepper.value = Double(feed.articleCount)
            keepCountLabel.text = String(format: "%.f", keepCountStepper.value)
            newFolderId = Int(feed.folderId)
            tableView.endUpdates()
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
    
    @IBAction func onFullArticleChanged(_ sender: Any) {
        readerModeSwitch.isEnabled = fullArticleSwitch.isOn;
    }
    
    @IBAction func onReaderModeChanged(_ sender: Any) {
        //
    }
    
    @IBAction func onKeepCounterChanged(_ sender: Any) {
        keepCountLabel.text = String(format: "%.f", keepCountStepper.value)
    }
    
    @IBAction func onSave(_ sender: Any) {
        if let feed = self.feed {
            feed.preferWeb = self.fullArticleSwitch.isOn
            feed.useReader = self.readerModeSwitch.isOn
            feed.articleCount = Int32(self.keepCountStepper.value)
            if feed.folderId != newFolderId {
                feed.folderId = Int32(newFolderId)
                OCNewsHelper.shared()?.moveFeedOffline(withId: Int(feed.myId), toFolderWithId: Int(feed.folderId))
            }
            if let newTitle = titleTextField.text, feed.title != newTitle, !newTitle.isEmpty {
                feed.title = newTitle
                OCNewsHelper.shared()?.renameFeedOffline(withId: Int(feed.myId), to: newTitle)
            }
            OCNewsHelper.shared()?.saveContext()
            self.delegate?.feedSettingsUpdate(settings: self)            
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onCancel(_ sender: Any) {
        if let delegate = self.delegate {
            delegate.feedSettingsUpdate(settings: self)
        }
        dismiss(animated: true, completion: nil)
    }
    
}

extension FeedSettings: FolderControllerDelegate {
    func folderSelected(folder: Int) {
        newFolderId = folder
    }
}
