//
//  ZoomableImageFullScreen.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/20.
//

import SwiftUI

// MARK: - SwiftUI 封装：全屏查看器（外层壳）
struct ZoomableImageFullScreen: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ZoomableRemoteImage(url: url)
                .ignoresSafeArea()

            // 右上角关闭按钮
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(radius: 2)
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 14)
                }
                Spacer()
            }
        }
        .statusBarHidden(true)
    }
}

// MARK: - UIKit 容器：真正的可缩放视图
struct ZoomableRemoteImage: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .black
        scrollView.maximumZoomScale = 4.0
        scrollView.minimumZoomScale = 1.0
        scrollView.delegate = context.coordinator
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true

        // 双击放大/还原
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTap)

        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView
        context.coordinator.scrollView = scrollView

        // 异步加载图片
        context.coordinator.load(url: url)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // 尺寸变化（横竖屏等）时，重新适配缩放
        context.coordinator.updateMinZoomScaleForSize(scrollView.bounds.size)
        context.coordinator.centerImage()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?
        weak var scrollView: UIScrollView?
        private var imageSize: CGSize = .zero

        // 图片加载
        func load(url: URL) {
            // 简单直连加载；你也可以替换为缓存库
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self, let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self.imageSize = img.size
                    self.imageView?.image = img
                    self.imageView?.frame = CGRect(origin: .zero, size: img.size)
                    self.scrollView?.contentSize = img.size
                    if let sv = self.scrollView {
                        self.updateMinZoomScaleForSize(sv.bounds.size)
                        sv.zoomScale = sv.minimumZoomScale // 初始完整适配
                        self.centerImage()
                    }
                }
            }.resume()
        }

        // 计算最小缩放（完整适配）
        func updateMinZoomScaleForSize(_ size: CGSize) {
            guard imageSize.width > 0, imageSize.height > 0, let sv = scrollView else { return }
            let widthScale  = size.width  / imageSize.width
            let heightScale = size.height / imageSize.height
            let minScale = min(widthScale, heightScale)

            sv.minimumZoomScale = minScale
            if sv.zoomScale < minScale {
                sv.zoomScale = minScale
            }
        }

        // 居中显示（缩小时图片不要贴边）
        func centerImage() {
            guard let sv = scrollView, let iv = imageView else { return }
            let offsetX = max((sv.bounds.size.width  - sv.contentSize.width)  * 0.5, 0)
            let offsetY = max((sv.bounds.size.height - sv.contentSize.height) * 0.5, 0)
            iv.center = CGPoint(x: sv.contentSize.width * 0.5 + offsetX,
                                y: sv.contentSize.height * 0.5 + offsetY)
        }

        // 双击放大/还原
        @objc func doubleTapped(_ recognizer: UITapGestureRecognizer) {
            guard let sv = scrollView else { return }
            let pointInView = recognizer.location(in: imageView)
            let newZoomScale: CGFloat
            if abs(sv.zoomScale - sv.minimumZoomScale) < 0.01 {
                newZoomScale = min(sv.maximumZoomScale, sv.minimumZoomScale * 2.0)
            } else {
                newZoomScale = sv.minimumZoomScale
            }

            let w = sv.bounds.size.width / newZoomScale
            let h = sv.bounds.size.height / newZoomScale
            let x = pointInView.x - (w * 0.5)
            let y = pointInView.y - (h * 0.5)

            let rectToZoom = CGRect(x: x, y: y, width: w, height: h)
            sv.zoom(to: rectToZoom, animated: true)
        }

        // MARK: UIScrollViewDelegate
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerImage()
        }

        func scrollViewDidLayoutSubviews(_ scrollView: UIScrollView) {
            updateMinZoomScaleForSize(scrollView.bounds.size)
            centerImage()
        }
    }
}
