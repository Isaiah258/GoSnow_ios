//
//  WelcomeAuthIntroView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/17.
//

import SwiftUI
import AVFoundation
import AVKit

// MARK: - 顶部“自然比例”视频（循环）+ 底部整块卡片（无白框）
struct WelcomeAuthIntroView: View {
    @State private var videoAspect: CGFloat? = nil
    private let videoName = "login_intro_top"   // ← 你的内置视频（不含扩展名）
    private let videoExt  = "mp4"

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let W = geo.size.width
                // 对齐像素网格，避免 0.5pt 缝
                let rawH = videoAspect.map { W / $0 } ?? 240
                let scale = UIScreen.main.scale
                let naturalH = ceil(rawH * scale) / scale

                VStack(spacing: 0) {
                    // 顶部：按自然比例展示（不裁切），上沿贴齐；循环播放
                    TopAspectFitVideo(
                        name: videoName,
                        ext: videoExt,
                        autoPlay: true,
                        loop: true,              // ★ 循环
                        staysAtEnd: false,       // 循环时无需停留
                        aspect: $videoAspect
                    )
                    .frame(height: naturalH)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .background(Color.clear)
                    .ignoresSafeArea(edges: .top)

                    // 底部：整块卡片（仅上圆角、纯黑、无白框）
                    BottomFullWidthCard_NoBorder()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .overlay(
                            VStack(alignment: .leading, spacing: 16) {
                                Text("登录以继续")
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                                Text("使用手机号登录，继续你的体验。")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))

                                NavigationLink { LoginView() } label: {
                                    Text("使用手机号登录")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .foregroundStyle(.white)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(.white.opacity(0.12))
                                        )
                                }
                                .buttonStyle(.plain)

                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, max(12, geo.safeAreaInsets.bottom))
                        )
                }
                .background(Color.black)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - 底部整块卡片（仅上圆角、纯黑、无描边）
struct BottomFullWidthCard_NoBorder: View {
    var body: some View {
        ZStack {
            if #available(iOS 17.0, *) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 24,
                    style: .continuous
                )
                .fill(Color.black)
            } else {
                Color.black
                    .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - 顶部 AspectFit 播放器（透明底，支持循环）
struct TopAspectFitVideo: UIViewRepresentable {
    final class Container: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        private(set) var player: AVPlayer?
        var videoAspect: CGFloat? { didSet { setNeedsLayout() } }

        func configure(url: URL, loop: Bool, onAspect: @escaping (CGFloat?) -> Void) {
            let item = AVPlayerItem(url: url)
            let p = AVPlayer(playerItem: item)
            p.isMuted = true
            player = p

            // 透明底，避免 letterbox 露黑
            playerLayer.player = p
            playerLayer.videoGravity = .resizeAspect
            playerLayer.isOpaque = false
            playerLayer.backgroundColor = UIColor.clear.cgColor
            self.isOpaque = false
            self.backgroundColor = .clear

            // 读尺寸（iOS 16+ 新 API）
            let asset = AVAsset(url: url)
            if #available(iOS 16.0, *) {
                Task {
                    do {
                        let tracks = try await asset.loadTracks(withMediaType: .video)
                        guard let track = tracks.first else {
                            await MainActor.run { onAspect(nil) }
                            return
                        }
                        let natural = try await track.load(.naturalSize)
                        let transform = try await track.load(.preferredTransform)
                        let corrected = natural.applying(transform)
                        let w = abs(corrected.width), h = abs(corrected.height)
                        let aspect = (h == 0) ? nil : (w / h)
                        await MainActor.run {
                            self.videoAspect = aspect
                            onAspect(aspect)
                        }
                    } catch {
                        await MainActor.run {
                            self.videoAspect = 9.0/16.0
                            onAspect(9.0/16.0)
                        }
                    }
                }
            } else {
                if let track = asset.tracks(withMediaType: .video).first {
                    let size = track.naturalSize.applying(track.preferredTransform)
                    let w = abs(size.width), h = abs(size.height)
                    let aspect = (h == 0) ? 9.0/16.0 : (w / h)
                    self.videoAspect = aspect
                    onAspect(aspect)
                } else {
                    self.videoAspect = 9.0/16.0
                    onAspect(9.0/16.0)
                }
            }

            // 循环：监听结束后 seek + play
            NotificationCenter.default.addObserver(
                self, selector: #selector(didEnd(_:)),
                name: .AVPlayerItemDidPlayToEndTime, object: item
            )
            // 存在性检查用 tag
            objc_setAssociatedObject(self, &Container.loopKey, loop, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        @objc private func didEnd(_ note: Notification) {
            guard let player = player else { return }
            let loop: Bool = (objc_getAssociatedObject(self, &Container.loopKey) as? Bool) ?? false
            if loop {
                player.seek(to: .zero)
                player.play()
            } // 否则停在最后一帧
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
            playerLayer.contentsScale = UIScreen.main.scale
        }

        private static var loopKey: UInt8 = 0
    }

    let name: String
    let ext: String
    var autoPlay: Bool = true
    var loop: Bool = false
    var staysAtEnd: Bool = true
    @Binding var aspect: CGFloat?

    func makeUIView(context: Context) -> Container {
        let v = Container()
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            v.configure(url: url, loop: loop) { asp in
                DispatchQueue.main.async { self.aspect = asp }
            }
            if autoPlay { v.playerLayer.player?.play() }
        }
        return v
    }

    func updateUIView(_ uiView: Container, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator: NSObject {}
}

// MARK: - 预览
#Preview("WelcomeAuthIntroView") {
    WelcomeAuthIntroView()
        .preferredColorScheme(.dark)
}






