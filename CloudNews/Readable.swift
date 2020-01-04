//
//  Readable.swift
//  CloudNews
//
//  Created by Peter Hedlund on 8/24/19.
//  Copyright © 2019 Peter Hedlund. All rights reserved.
//

import Foundation
import SwiftSoup

struct ReadableData {
    public let title: String
    public let description: String?
    public let text: String?
    public let image: String?
    public let video: String?
}

fileprivate struct Pattern {
    static let unlikely = "com(bx|ment|munity)|dis(qus|cuss)|e(xtra|[-]?mail)|foot|"
        + "header|menu|re(mark|ply)|rss|sh(are|outbox)|sponsor|"
        + "a(d|ll|gegate|rchive|ttachment)|(pag(er|ination))|popup|print|"
        + "login|si(debar|gn|ngle)"

    static let positive = "(^(body|content|h?entry|main|page|post|text|blog|story|haupt))"
        + "|arti(cle|kel)|instapaper_body"

    static let negative = "nav($|igation)|user|com(ment|bx)|(^com-)|contact|"
        + "foot|masthead|(me(dia|ta))|outbrain|promo|related|scroll|(sho(utbox|pping))|"
        + "sidebar|sponsor|tags|tool|widget|player|disclaimer|toc|infobox|vcard|post-ratings"

    static let elements = ["p", "div", "td", "h1", "h2", "article", "section", "pre"]
}

class Readable {

    private var unlikelyRegExp: NSRegularExpression?
    private var positiveRegExp: NSRegularExpression?
    private var negativeRegExp: NSRegularExpression?
    private var nodesRegExp: NSRegularExpression?

    private var highestPriorityElement: Element?
    private var document: Document?

    private let titleQueries: [(String, String?)] = [
        ("head > title", nil),
        ("head > meta[name='title']", "content"),
        ("head > meta[property='og:title']", "content"),
        ("head > meta[name='twitter:title']", "content")
    ]

    private let descriptionQueries: [(String, String?)] = [
        ("head > meta[name='description']", "content"),
        ("head > meta[property='og:description']", "content"),
        ("head > meta[name='twitter:description']", "content"),
        ("head > meta[property='twitter:description']", "content")
    ]

    private let imageQueries: [(String, String?)] = [
        ("head > meta[property='og:image']", "content"),
        ("head > meta[name='twitter:image']", "content"),
        ("link[rel='image_src']", "href"),
        ("head > meta[name='thumbnail']", "content"),
        ("img[img[src*=:small]]", "src")
    ]

    private let videoQueries: [(String, String?)] = [
        ("head > meta[property='og:video:url']", "content")
    ]

    class func parse(_ html: String) -> ReadableData? {
        let parser = Readable()
        return parser.parseHtml(html)
    }

    private func parseHtml(_ html: String) -> ReadableData? {
        guard let document = try? SwiftSoup.parse(html) else {
            return nil
        }
        self.document = document

        processDocument()

        return ReadableData(title: self.title() ?? "Untitled",
                            description: description(),
                            text: text(),
                            image: image(),
                            video: video())
    }

    private func processDocument() {
        var highestPriority = 0
        do {
            try unlikelyRegExp = NSRegularExpression(pattern: Pattern.unlikely, options: .caseInsensitive)
            try positiveRegExp = NSRegularExpression(pattern: Pattern.positive, options: .caseInsensitive)
            try negativeRegExp = NSRegularExpression(pattern: Pattern.negative, options: .caseInsensitive)
            if let body = self.document?.body() {
                let children = body.children().array()
                let contentElements = pickContentElements(incoming: children)
                for child in contentElements {
                    var weight = elementWeight(element: child)
                    guard let stringValue = try? child.text() else {
                        continue
                    }
                    weight += stringValue.count / 10
                    
                    weight += childElementWeight(element: child)
                    if (weight > highestPriority) {
                        highestPriority = weight
                        highestPriorityElement = child
                    }
                    
                    if weight > 200 {
                        break
                    }
                }
            }
        }
        catch { }
    }

    private func title() -> String? {
        return extractValue(usingQueries: titleQueries)
    }

    private func description() -> String? {
        var result: String?
        if let description = extractValue(usingQueries: descriptionQueries), !description.isEmpty {
            return description
        } else if let highestPriorityElement = highestPriorityElement {
            result = extractText(element: highestPriorityElement)
        }
        return result
    }

    private func text() -> String? {
        guard let highestPriorityElement = highestPriorityElement else {
            return nil
        }

        return extractFullText(element: highestPriorityElement)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func image() -> String? {
        var result: String?
        if let image = extractValue(usingQueries: imageQueries), !image.isEmpty {
            return image
        } else if let highestPriorityElement = highestPriorityElement,
            let imageNode = self.determineImageSource(element: highestPriorityElement) {
                result = try? imageNode.attr("src")
        }
        return result
    }

    private func video() -> String? {
        return extractValue(usingQueries: videoQueries)
    }

    private func pickContentElements(incoming: [Element]) -> [Element] {
        return incoming.filter({ Pattern.elements.contains($0.tagName())})
    }
    
    private func elementWeight(element: Element) -> Int {
        var weight = 0
        do {
            let className = try element.classNames().joined(separator: " ")
            let range = NSRange(location: 0, length: className.count)
            if let positiveRegExp = positiveRegExp,
                positiveRegExp.matches(in: className, options: .reportProgress, range: range).count > 0 {
                weight += 35
            }

            if let unlikelyRegExp = unlikelyRegExp,
                unlikelyRegExp.matches(in: className, options: .reportProgress, range: range).count > 0 {
                weight -= 20
            }

            if let negativeRegExp = negativeRegExp,
                negativeRegExp.matches(in: className, options: .reportProgress, range: range).count > 0 {
                weight -= 50
            }

            let id = element.id()
            let idRange = NSMakeRange(0, id.count)
            if let positiveRegExp = positiveRegExp,
                positiveRegExp.matches(in: id, options: .reportProgress, range: idRange).count > 0 {
                weight += 40
            }

            if let unlikelyRegExp = unlikelyRegExp,
                unlikelyRegExp.matches(in: id, options: .reportProgress, range: idRange).count > 0 {
                weight -= 20
            }

            if let negativeRegExp = negativeRegExp,
                negativeRegExp.matches(in: id, options: .reportProgress, range: idRange).count > 0 {
                weight -= 50
            }

            let style = try element.select("style").text()
            if let negativeRegExp = negativeRegExp,
                negativeRegExp.matches(in: style, options: .reportProgress, range: NSMakeRange(0, style.count)).count > 0 {
                weight -= 50
            }
        } catch { }

        return weight
    }

    private func childElementWeight(element: Element) -> Int {
        var weight = 0
        do {
            let childElements = try element.getAllElements().array()
            for child in childElements {
                guard let text = try? child.text() else {
                    return weight
                }
                
                let count = text.count
                if count < 20 {
                    return weight
                }
                
                if count > 200 {
                    weight += max(50, count / 10)
                }
                
                let tagName = element.tagName()
                if tagName == "h1" || tagName == "h2" {
                    weight += 30
                } else if tagName == "div" || tagName == "p" {
                    weight += calcWeightForChild(text: text)
                    
                    if let _ = try? element.className().lowercased() == "caption" {
                        weight += 30
                    }
                }
            }
        } catch { }
        
        
        return weight
    }

    private func calcWeightForChild(text: String) -> Int {
        var c = text.countInstances(of: "&quot;")
        c += text.countInstances(of: "&lt;")
        c += text.countInstances(of: "&gt;")
        c += text.countInstances(of: "px")

        var val = 0
        if c > 5 {
            val = -30
        } else {
            val = Int(Double(text.count) / 25.0)
        }

        return val
    }

    private func determineImageSource(element: Element) -> Element? {
        var maxImgWeight = 20.0
        var maxImgNode: Element?

        do {
            var imageNodes = try element.select("img")
            if imageNodes.array().isEmpty,
                let parent = element.parent() {
                imageNodes = try parent.select("img")
            }

            var score = 1.0


            for imageNode in imageNodes {
                guard let url = try? imageNode.select("src").text() else {
                    return nil
                }

                if url.countInstances(of: "ad") > 2 { //most likely an ad
                    return nil
                }

                var weight = Double(imageSizeWeight(element: imageNode) +
                    imageAltWeight(element: imageNode) +
                    imageTitleWeight(element: imageNode))

                if let parent = imageNode.parent(),
                    let _ = try? parent.attr("rel") {
                    weight -= 40.0
                }

                weight = weight * score

                if weight > maxImgWeight {
                    maxImgWeight = weight
                    maxImgNode = imageNode
                    score = score / 2.0
                }
            }
        } catch { }

        return maxImgNode
    }

    private func imageSizeWeight(element: Element) -> Int {
        var weight = 0
        if let widthStr = try? element.attr("width"),
            let width = Int(widthStr) {
            if width >= 50 {
                weight += 20
            }
            else {
                weight -= 20
            }
        }

        if let heightStr = try? element.attr("height"),
            let height = Int(heightStr) {
            if height >= 50 {
                weight += 20
            }
            else {
                weight -= 20
            }
        }
        return weight
    }

    private func imageAltWeight(element: Element) -> Int {
        var weight = 0
        if let altStr = try? element.attr("alt") {
            if (altStr.count > 35) {
                weight = 20
            }
        }
        return weight
    }

    private func imageTitleWeight(element: Element) -> Int {
        var weight = 0
        if let titleStr = try? element.attr("title") {
            if (titleStr.count > 35) {
                weight = 20
            }
        }
        return weight
    }

    private func extractText(element: Element) -> String?
    {
        guard let elements = try? element.getAllElements() else {
            return nil
        }
//        var texts = [String]()
        var importantTexts = [String]()
        let extractedTitle = title()
        for element in elements {
            for textNode in element.textNodes() {
                let length = textNode.text().count
                
                if let titleLength = extractedTitle?.count {
                    if length > titleLength {
                        importantTexts.append(textNode.text())
                    }
                    
                } else if length > 100 {
                    importantTexts.append(textNode.text())
                }
            }
        }
        return importantTexts.first?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractFullText(element: Element) -> String?
    {
        let elements = element.children()
        if elements.isEmpty() {
            return nil
        }

        //        let texts = elementText.replacingOccurrences(of: "\t", with: "").components(separatedBy: .newlines)
        var importantTexts = [String]()
        for element in elements {
            //            for textNode in element.textNodes() {
            let length = try? element.text().count
            if length ?? 0 > 100 {
                let text = try? element.html()
                importantTexts.append(text ?? "")
            }
            //            }
        }
        
        var fullText = importantTexts.reduce("", { $0 + "\n" + $1 })
        lowContentChildren(element: element).forEach { lowContent in
            fullText = fullText.replacingOccurrences(of: lowContent, with: "")
        }

        return fullText
    }

    private func lowContentChildren(element: Element) -> [String] {
        var contents = [String]()
        do {
            if element.children().array().isEmpty {
                let content = try element.html()
                let length = content.count
                if length > 3 && length < 175 {
                    contents.append(content)
                }
            }
            element.children().array().forEach { childNode in
                contents.append(contentsOf: lowContentChildren(element: childNode))
            }
        } catch { }
        return contents
    }

    private func extractValue(usingQueries queries: [(String, String?)]) -> String? {
        var result: String?
        if let document = document {
            do {
                for query in queries {
                    if let valueElement = try document.select(query.0).array().first {
                        if let attr = query.1 {
                            result = try valueElement.attr(attr)
                        } else {
                            result = try valueElement.text()
                        }
                    }
                    if result != nil {
                        break
                    }
                }
            } catch { }
        }
        return result
    }

}

extension String {
    /// stringToFind must be at least 1 character.
    func countInstances(of stringToFind: String) -> Int {
        assert(!stringToFind.isEmpty)
        var count = 0
        var searchRange: Range<String.Index>?
        while let foundRange = range(of: stringToFind, options: [], range: searchRange) {
            count += 1
            searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound, upper: endIndex))
        }
        return count
    }
}
