//
//  KFUserAvatar.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/15.
//

// KFUserAvatar.swift
import SwiftUI
import Kingfisher

struct KFUserAvatar: View {
    let urlString: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let s = urlString, s.hasPrefix("http"), let url = URL(string: s) {
                KFImage(url)
                    .placeholder { Color.gray.opacity(0.15) }
                    .cacheOriginalImage()
                    .onFailure { _ in }
                    .resizable()
                    .scaledToFill()
            } else if let name = urlString, let ui = UIImage(named: name) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable().scaledToFill()
                    .foregroundColor(.gray)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

