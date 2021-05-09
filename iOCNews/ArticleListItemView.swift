//
//  ArticleListItemView.swift
//  iOCNews
//
//  Created by Peter Hedlund on 5/1/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import Kingfisher
import SwiftUI

@available(iOS 13.0.0, *)
struct ArticleListItemView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State var provider: ItemProvider?

//    init(provider: ItemProvider) {
//        self.provider = provider
//        SettingsStore.theme = 0
//    }

    var body: some View {
        let isCompactView = SettingsStore.compactView
        let cellHeight: CGFloat = isCompactView ? 84 : 150
        if let provider = provider {
            GeometryReader { geometry in
                ZStack {
                    Rectangle().foregroundColor(Color(ThemeColors().pbhCellBackground)).edgesIgnoringSafeArea(.all)
                    VStack(content: {
                        HStack(alignment: .top, spacing: 10, content: {
                            if SettingsStore.showThumbnails && provider.imageUrl != nil {
                                if isCompactView || horizontalSizeClass == .compact {
                                    VStack {
                                        KFImage(provider.imageUrl)
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 66, height: 66, alignment: .center)
                                            .clipped()
                                            .cornerRadius(6.0)
                                            .opacity(Double(provider.imageAlpha))
                                    }
                                    .padding(EdgeInsets(top: 6, leading: 6, bottom: 0, trailing: 0))
                                } else {
                                    VStack {
                                        Spacer()
                                        KFImage(provider.imageUrl)
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 112, height: 112, alignment: .center)
                                            .clipped()
                                            .cornerRadius(12.0)
                                            .opacity(Double(provider.imageAlpha))
                                        Spacer()
                                    }
                                }
                            } else {
                                EmptyView()
                            }
                            HStack {
                                VStack(alignment: .leading, spacing: 8, content: {
                                    Text(provider.title)
                                        .font(.headline)
                                        .foregroundColor(Color(provider.titleColor))
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true) //force wrapping
                                    HStack {
                                        if SettingsStore.showFavIcons {
                                            KFImage(provider.favIconUrl!)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 16, height: 16, alignment: .center)
                                                .opacity(Double(provider.imageAlpha))
                                        } else {
                                            EmptyView()
                                        }
                                        Text(provider.dateText)
                                            .font(.subheadline)
                                            .foregroundColor(Color(provider.dateColor))
                                            .italic()
                                            .lineLimit(1)
                                    }
                                    if isCompactView || horizontalSizeClass == .compact {
                                        EmptyView()
                                    } else {
                                        Text(provider.summaryText)
                                            .font(.subheadline)
                                            .foregroundColor(Color(provider.summaryColor))
                                    }
                                    if isCompactView || horizontalSizeClass == .compact {
                                        EmptyView()
                                    } else {
                                        Spacer()
                                    }
                                })
                                .padding(EdgeInsets(top: 6, leading: 0, bottom: 0, trailing: 0))
                                Spacer()
                            }
                            .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 0))
                            VStack {
                                if provider.starred {
                                    Image(systemName: "star.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 16, height: 16, alignment: .center)
                                } else {
                                    HStack {
                                        Spacer()
                                    }
                                    .frame(width: 16)
                                }
                            }
                            .padding(EdgeInsets(top: 6, leading: 0, bottom: 0, trailing: 0))
                        })
                        if horizontalSizeClass == .compact && !isCompactView  {
                            Text(provider.summaryText)
                                .font(.subheadline)
                                .foregroundColor(Color(provider.summaryColor))
                                .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 26))
                        } else {
                            EmptyView()
                        }
                    })
                    .frame(minWidth: geometry.size.width * 0.95,
                           idealWidth: min(geometry.size.width * 0.95, 690),
                           maxWidth: min(geometry.size.width * 0.95, 690),
                           minHeight: 75,
                           idealHeight: cellHeight,
                           maxHeight: cellHeight,
                           alignment: .center)
                    .padding([.leading, .trailing], 2)
                    .background(Color(ThemeColors().pbhCellBackground) // any non-transparent background
                                    .shadow(color: Color(white: 0.5, opacity: 0.25), radius: 2, x: 0, y: 0))
                }
            }}
        else {
            EmptyView()
        }
    }
}

//@available(iOS 13.0, *)
//struct ArticleListItemView_Previews: PreviewProvider {
//    static var previews: some View {
//        let data = previewData()
//        Group {
//            List(/*@START_MENU_TOKEN@*/0 ..< 5/*@END_MENU_TOKEN@*/) { item in
//                ArticleListItemView(provider: data[item])
//            }
//            List(/*@START_MENU_TOKEN@*/0 ..< 5/*@END_MENU_TOKEN@*/) { item in
//                ArticleListItemView(provider: data[item])
//            }
//            .previewDevice("iPhone 12 Pro")
//        }
//    }
//}

//@available(iOS 13.0, *)
//struct Show: ViewModifier {
//    @Binding var isVisible: Bool
//
//    @ViewBuilder
//    func body(content: Content) -> some View {
//        if isVisible {
//            content
//        } else {
//            content.hidden()
//        }
//    }
//}
//
//@available(iOS 13.0, *)
//extension View {
//    func show(isVisible: Binding<Bool>) -> some View {
//        ModifiedContent(content: self, modifier: Show(isVisible: isVisible))
//    }
//}
