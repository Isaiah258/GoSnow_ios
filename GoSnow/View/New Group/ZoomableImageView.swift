//
//  ZoomableImageView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/10/1.
//

import SwiftUI

struct ZoomableImageView: View {
    var imageUrl: URL
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            AsyncImage(url: imageUrl) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = value
                                }
                        )
                case .failure(_):
                    Text("图片加载失败")
                default:
                    ProgressView() // 加载中的进度视图
                }
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

