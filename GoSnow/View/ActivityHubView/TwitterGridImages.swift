//
//  TwitterGridImages.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/26.
//

import SwiftUI
import Kingfisher

public struct TwitterGridImages: View {
    public let urls: [String]
    public var corner: CGFloat = 12
    public var gap: CGFloat = 6
    public var sidePadding: CGFloat = 16
    public var maxRowHeight: CGFloat = 300
    public var onTap: (Int) -> Void

    private var containerW: CGFloat {
        UIScreen.main.bounds.width - sidePadding * 2
    }

    public init(urls: [String],
                corner: CGFloat = 12,
                gap: CGFloat = 6,
                sidePadding: CGFloat = 16,
                maxRowHeight: CGFloat = 300,
                onTap: @escaping (Int) -> Void) {
        self.urls = urls
        self.corner = corner
        self.gap = gap
        self.sidePadding = sidePadding
        self.maxRowHeight = maxRowHeight
        self.onTap = onTap
    }

    public var body: some View {
        Group {
            switch urls.count {
            case 1:
                let rowH = min(maxRowHeight, containerW * 0.75)
                cell(urls[0], w: containerW, h: rowH, i: 0)
            case 2:
                let rowH = min(maxRowHeight, containerW * 0.56)
                HStack(spacing: gap) {
                    cell(urls[0], w: (containerW - gap)/2, h: rowH, i: 0)
                    cell(urls[1], w: (containerW - gap)/2, h: rowH, i: 1)
                }
            case 3:
                let rowH = min(maxRowHeight, containerW * 0.56)
                HStack(spacing: gap) {
                    cell(urls[0], w: (containerW - gap) * 0.6, h: rowH, i: 0)
                    VStack(spacing: gap) {
                        cell(urls[1], w: (containerW - gap) * 0.4, h: (rowH - gap)/2, i: 1)
                        cell(urls[2], w: (containerW - gap) * 0.4, h: (rowH - gap)/2, i: 2)
                    }
                }
            default:
                let cellW = (containerW - gap)/2
                let cellH = min(maxRowHeight/2, cellW)
                let shown = Array(urls.prefix(4))
                let extra = urls.count - shown.count
                VStack(spacing: gap) {
                    HStack(spacing: gap) {
                        cell(shown[0], w: cellW, h: cellH, i: 0)
                        cell(shown[1], w: cellW, h: cellH, i: 1)
                    }
                    HStack(spacing: gap) {
                        cell(shown[2], w: cellW, h: cellH, i: 2)
                        ZStack {
                            cell(shown[3], w: cellW, h: cellH, i: 3)
                            if extra > 0 {
                                Color.black.opacity(0.28)
                                    .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                                Text("+\(extra)").font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, sidePadding)
    }

    @ViewBuilder
    private func cell(_ s: String, w: CGFloat, h: CGFloat, i: Int) -> some View {
        if let url = URL(string: s) {
            KFImage(url)
                .placeholder { Rectangle().fill(Color.black.opacity(0.06)).overlay(Image(systemName: "photo")) }
                .setProcessor(DownsamplingImageProcessor(size: .init(width: 1000, height: 1000)))
                .cacheOriginalImage()
                .resizable()
                .scaledToFill()
                .frame(width: w, height: h)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                .contentShape(Rectangle())
                .onTapGesture { onTap(i) }
        } else {
            Rectangle().fill(Color.black.opacity(0.06))
                .frame(width: w, height: h)
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        }
    }
}
