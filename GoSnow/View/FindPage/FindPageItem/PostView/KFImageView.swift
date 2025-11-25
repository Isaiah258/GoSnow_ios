//
//  KFImageView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/7/25.
//

import SwiftUI
import Kingfisher

struct KFImageView: View {
    let url: URL?
    var cornerRadius: CGFloat = 8
    var contentMode: SwiftUI.ContentMode = .fill

    var body: some View {
        KFImage(url)
            .resizable()
            .placeholder {
                ProgressView()
            }
            .aspectRatio(contentMode: contentMode)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}


