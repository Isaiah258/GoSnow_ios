//
//  ImageViewerCenter.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/26.
//

import SwiftUI
import UIKit

// SwiftUI 视图：展示图片浏览器
struct PhotoViewer: View {
    let imageUrl: String
    @Binding var isPresented: Bool  // 控制关闭的状态
    
    var body: some View {
        VStack {
            PhotoViewerController(imageUrl: imageUrl, isPresented: $isPresented)
                .edgesIgnoringSafeArea(.all)  // 扩展到全屏
        }
    }
}

// UIKit 控件：UIScrollView + UIImageView
struct PhotoViewerController: UIViewControllerRepresentable {
    let imageUrl: String
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = PhotoViewerViewController()
        controller.imageUrl = imageUrl
        controller.onClose = {
            withAnimation {
                isPresented = false  // 点击关闭时修改状态
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 无需更新
    }
}

// UIKit 控制器：处理图片展示和手势
class PhotoViewerViewController: UIViewController, UIScrollViewDelegate {
    var imageUrl: String?
    var onClose: (() -> Void)?
    
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    private var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    // 设置 UIScrollView 和 UIImageView
    private func setupViews() {
        // 创建 scrollView
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.frame = view.bounds
        scrollView.backgroundColor = .black
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        view.addSubview(scrollView)
        
        // 创建 imageView
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds
        imageView.isUserInteractionEnabled = true
        if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            imageView.loadImage(from: url)  // 加载图片
        }
        scrollView.addSubview(imageView)
        
        // 添加手势：点击关闭
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        view.addGestureRecognizer(tapGesture)
        
        // 添加关闭按钮
        closeButton = UIButton(type: .system)
        closeButton.frame = CGRect(x: 20, y: 40, width: 50, height: 50)
        closeButton.setTitle("关闭", for: .normal)
        closeButton.addTarget(self, action: #selector(handleCloseButton), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // 添加上下滑动关闭手势
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        view.addGestureRecognizer(panGesture)
    }
    
    // 点击关闭按钮
    @objc private func handleCloseButton() {
        onClose?()
    }
    
    // 点击手势：关闭图片查看器
    @objc private func handleTapGesture() {
        onClose?()
    }
    
    // 上下滑动手势：返回关闭
    @objc private func handlePanGesture(panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: view)
        
        if panGesture.state == .changed {
            if translation.y > 100 {  // 上下滑动超过一定距离时触发关闭
                onClose?()
            }
        }
    }
    
    // UIScrollViewDelegate 方法：设置缩放视图
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

// 扩展 UIImageView 用于加载网络图片
extension UIImageView {
    func loadImage(from url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.image = image
                }
            }
        }
    }
}
