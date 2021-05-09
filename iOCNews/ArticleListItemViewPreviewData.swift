//
//  ArticleListItemViewPreviewData.swift
//  iOCNews
//
//  Created by Peter Hedlund on 5/2/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import Foundation

func previewData() -> [ItemProvider] {
    var itemData = ItemProviderStruct()
    itemData.title = "An interesting article"
    itemData.myID = 1
    itemData.author = "Peter Hedlund"
    itemData.pubDate = Int(Date().timeIntervalSince1970)
    itemData.body = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nunc orci, adipiscing a quam ac, eleifend hendrerit metus. Cras fringilla vel enim ut tristique. Mauris vestibulum pulvinar convallis. Proin in ante a tellus blandit sagittis sed et magna."
    itemData.feedId = 1
    itemData.starred = false
    itemData.unread = false
    itemData.imageLink = "https://pbh.dev/images/apps/cloudnotes/iphone2_tn.png"
    itemData.readable = nil
    itemData.url = ""
    itemData.favIconLink = "https://pbh.dev/images/favicon.png"
    itemData.feedTitle = "PBH.dev"
    itemData.feedPreferWeb = false
    itemData.feedUseReader = false
    let provider = ItemProvider(item: itemData)

    var itemData2 = ItemProviderStruct()
    itemData2.title = "An interesting article with a very long title that is bound to wrap on some devices."
    itemData2.myID = 2
    itemData2.author = "Peter Hedlund"
    itemData2.pubDate = Int(Date().timeIntervalSince1970)
    itemData2.body = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nunc orci, adipiscing a quam ac, eleifend hendrerit metus. Cras fringilla vel enim ut tristique. Mauris vestibulum pulvinar convallis. Proin in ante a tellus blandit sagittis sed et magna."
    itemData2.feedId = 1
    itemData2.starred = true
    itemData2.unread = true
    itemData2.imageLink = nil
    itemData2.readable = nil
    itemData2.url = ""
    itemData2.favIconLink = "https://pbh.dev/images/favicon.png"
    itemData2.feedTitle = "PBH.dev"
    itemData2.feedPreferWeb = false
    itemData2.feedUseReader = false
    let provider2 = ItemProvider(item: itemData2)

    var itemData3 = ItemProviderStruct()
    itemData3.title = "An interesting article without favicon."
    itemData3.myID = 3
    itemData3.author = "Peter Hedlund"
    itemData3.pubDate = Int(Date().timeIntervalSince1970)
    itemData3.body = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed nunc orci, adipiscing a quam ac, eleifend hendrerit metus. Cras fringilla vel enim ut tristique. Mauris vestibulum pulvinar convallis. Proin in ante a tellus blandit sagittis sed et magna."
    itemData3.feedId = 1
    itemData3.starred = false
    itemData3.unread = true
    itemData3.imageLink = "https://pbh.dev/images/apps/cloudnotes/iphone1_tn.png"
    itemData3.readable = nil
    itemData3.url = ""
    itemData3.favIconLink = nil
    itemData3.feedTitle = "PBH.dev"
    itemData3.feedPreferWeb = false
    itemData3.feedUseReader = false
    let provider3 = ItemProvider(item: itemData3)

    return [provider, provider2, provider3, provider, provider2]
}
