//
//  NewsTextView.swift
//  iOCNews
//
//  Created by Peter Hedlund on 3/25/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit

class NewsTextView: UITextView {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addObserver(self, forKeyPath: "contentSize", options:.new, context: nil)
    }

    deinit {
        removeObserver(self, forKeyPath: "contentSize")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !__CGSizeEqualToSize(bounds.size, intrinsicContentSize) {
            invalidateIntrinsicContentSize()
        }
    }

    override var textContainerInset: UIEdgeInsets {
        get {
            return .zero
        }
        set {
            super.textContainerInset = newValue
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let textView = object as? UITextView {
            var topOffset = (textView.bounds.size.height - textView.contentSize.height * textView.zoomScale) / 2
            topOffset = topOffset < 0 ? 0 : topOffset
            textView.contentOffset = CGPoint(x: 0, y: -topOffset)
        }
    }

}
