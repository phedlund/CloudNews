//
//  UIImageViewExtension.swift
//  iOCNews
//
//  Created by Peter Hedlund on 1/7/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import Foundation
import Kingfisher

@objc
extension UIImageView {
    
    func setFavIcon(for feed: Feed) {
        func useFeedURL() {
            if let feedUrl = URL(string: feed.link ?? ""), let host = feedUrl.host, let url = URL(string: "https://icons.duckduckgo.com/ip3/\(host).ico") {
                let processor = IcoDataProcessor()
                self.kf.setImage(with: url, options: [.processor(processor)]) { result in
                    switch result {
                    case .success(_):
                        feed.faviconLink = url.absoluteString
                        OCNewsHelper.shared()?.saveContext()
                    case .failure(_):
                        self.image = UIImage(named: "favicon")
                    }
                }
            } else {
                self.image = UIImage(named: "favicon")
            }
        }
        
        if let link = feed.faviconLink, link != "favicon", let url = URL(string: link), let scheme = url.scheme, ArticleImage.validSchemas.contains(scheme) {
            self.kf.setImage(with: url) { result in
                switch result {
                case .success(_):
                    break
                case .failure(_):
                    useFeedURL()
                }
            }
        } else {
            useFeedURL()
        }
    }
}

struct IcoDataProcessor: ImageProcessor {

    // `identifier` should be the same for processors with the same properties/functionality
    // It will be used when storing and retrieving the image to/from cache.
    let identifier = "dev.pbh.icodataprocessor"
    
    // Convert input data/image to target image and return it.
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> UIImage? {
        switch item {
        case .image(let image):
            print("already an image")
            return image
        case .data(let data):
            return UIImage(data: data)
        }
    }
}
