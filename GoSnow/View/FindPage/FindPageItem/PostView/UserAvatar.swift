//
//  UserAvatar.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/14.
//

import SwiftUI
import Kingfisher

struct UserAvatar: View {
    let source: String?                  // 可能是 https URL，也可能是内置 asset 名
    let placeholderSystemName: String    // 占位 SF Symbol

    var body: some View {
        Group {
            if let src = source, src.hasPrefix("http"), let url = URL(string: src) {
                KFImage.url(url)
                    .loadDiskFileSynchronously()
                    .cacheOriginalImage() // 原图+处理后图都缓存，供全屏预览复用
                    .setProcessor(DownsamplingImageProcessor(size: targetPixelSize))
                    .scaleFactor(UIScreen.main.scale)
                    .fade(duration: 0.2)
                    .placeholder {
                        Image(systemName: placeholderSystemName)
                            .resizable().scaledToFill().foregroundColor(.gray)
                    }
                    .resizable()
                    .scaledToFill()
            } else if let name = source, let ui = UIImage(named: name) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Image(systemName: placeholderSystemName)
                    .resizable().scaledToFill().foregroundColor(.gray)
            }
        }
    }

    private var targetPixelSize: CGSize {
        // 头像通常 40~80，这里给 80pt 对应的像素，外层 frame 会裁剪
        let side = 80 * UIScreen.main.scale
        return CGSize(width: side, height: side)
    }
}



