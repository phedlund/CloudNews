//
//  ArticleListItemCell.swift
//  iOCNews
//
//  Created by Peter Hedlund on 5/4/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 13.0.0, *)
class ArticleListItemCell: UICollectionViewCell {

    var item: ItemProvider? //{
//        didSet {
//            self.configureView()
//        }
//    }

//    public override init(frame: CGRect) {
//        super.init(frame: .zero)
//    }
//
//    public required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }

    override func prepareForReuse() {
        super.prepareForReuse()
        item = nil
    }

    func configureView() {
//        if let item = item {
            let customView = UIHostingController(rootView: ArticleListItemView(provider: item))
            customView.view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(customView.view)
            
            customView.view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            customView.view.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
            customView.view.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
            customView.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
//        }
    }
//
//    let contentController: UIViewController
//
//    init(withContent content: UIViewController, reuseIdentifier: String) {
//        contentController = content
//        super.init()
//        contentController.view.translatesAutoresizingMaskIntoConstraints = false
//        contentController.view.frame = contentView.bounds
//        contentView.addSubview(contentController.view)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }

}
