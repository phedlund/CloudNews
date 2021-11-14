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
                KF.url(url)
                    .setProcessor(processor)
                    .loadDiskFileSynchronously()
                    .onSuccess({ _ in
                        feed.faviconLink = url.absoluteString
                        OCNewsHelper.shared()?.saveContext()
                    })
                    .onFailure({ error in
                        self.image = UIImage(named: "favicon")
                    })
                    .set(to: self)
            } else {
                self.image = UIImage(named: "favicon")
            }
        }
        
        if let link = feed.faviconLink, link != "favicon", let url = URL(string: link), let scheme = url.scheme, ArticleImage.validSchemas.contains(scheme) {
            KF.url(url)
                .loadDiskFileSynchronously()
                .onFailure({ error in
                    useFeedURL()
                })
                .set(to: self)
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

struct SizeProcessor: ImageProcessor {
    // `identifier` should be the same for processors with the same properties/functionality
    // It will be used when storing and retrieving the image to/from cache.
    let identifier = "dev.pbh.sizeprocessor"

    // Convert input data/image to target image and return it.
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            let size = image.size
            if size.height > 100, size.width > 100 {
                return image
            }
            print("Small image: \(size)")
            return nil
        case .data(let data):
            if let image = KFCrossPlatformImage(data: data) {
                let size = image.size
                if size.height > 100, size.width > 100 {
                    return image
                }
                print("Small image: \(size)")
                return nil
            }
            return nil
        }
    }
}
