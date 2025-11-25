//
//  demo4.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/16.
//
/*
import SwiftUI

// MARK: - 预览容器（10 种卡片出现方式 · 修正版）
struct CardAppearEffectsDemo: View {
    @State private var replayAllToken = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Header()

                    Group {
                        FadeCard(replayToken: replayAllToken)
                        FadeSlideUpCard(replayToken: replayAllToken)
                        PopInCard(replayToken: replayAllToken)
                        BlurInCard(replayToken: replayAllToken)
                        MaskWipeCard(replayToken: replayAllToken)
                        DirectionalSlideCard(replayToken: replayAllToken)
                        Tilt3DCard(replayToken: replayAllToken)
                        StrokeThenFillCard(replayToken: replayAllToken)
                        StaggeredRow(replayToken: replayAllToken)
                        LeadEmphasisRow(replayToken: replayAllToken)
                    }
                }
            }
            .scrollClipDisabled()                     // 关键：不让系统裁切滚动内容
           // .scrollContentMargins(.all, 20)           // iOS 17+ 统一边距；iOS 16 可改为 .padding
            .navigationTitle("Card Appear Effects")
            //.navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Replay All") { replayAllToken &+= 1 }
                }
            }
            .background(
                LinearGradient(colors: [Color(.systemBackground),
                                        Color(.secondarySystemBackground)],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            )
        }
    }
}

// MARK: - Demo Header
private struct Header: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("卡片出现方式 · 10 种").font(.title2.bold())
            Text("点各卡右上角 Replay 或使用导航栏的 Replay All 统一预览。")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 统一的卡片样式（修复裁切/描边）
struct CardShell<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let content: Content
    let replay: () -> Void

    private let outerRadius: CGFloat = 16
    private let innerRadius: CGFloat = 12

    init(title: String, subtitle: String, icon: String,
         replay: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.replay = replay
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconBadge(system: icon, tint: .blue)
                VStack(alignment: .leading) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Replay", action: replay)
                    .buttonStyle(.bordered)
            }

            // 内容区
            ZStack { content }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.06), in: .rect(cornerRadius: innerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: innerRadius)
                        .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                }
        }
        .padding(16)
        // 外层底板与描边（不裁剪内容，避免吃字）
        .background(.white.opacity(0.06), in: .rect(cornerRadius: outerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: outerRadius)
                .strokeBorder(.primary.opacity(0.12), lineWidth: 1)
        }
        .compositingGroup() // 减少半透明叠加伪影
    }
}



// MARK: 1) 淡入
struct FadeCard: View {
    @State private var on = false
    let replayToken: Int

    var body: some View {
        CardShell(title: "1) 淡入 (Fade In)",
                  subtitle: "最克制：180–280ms",
                  icon: "circle.lefthalf.filled",
                  replay: { play() }) {
            Text("内容区域")
                .font(.title3.weight(.semibold))
                .opacity(on ? 1 : 0)
                .animation(.easeOut(duration: 0.22), value: on)
        }
        .onAppear(perform: play)
        .onChange(of: replayToken) {  play() }
    }
    private func play() { on = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { on = true } }
}

// MARK: 2) 淡入 + 上移
struct FadeSlideUpCard: View {
    @State private var on = false
    let replayToken: Int

    var body: some View {
        CardShell(title: "2) 淡入 + 上移",
                  subtitle: "轻盈 8–12pt",
                  icon: "arrow.up.to.line",
                  replay: { play() }) {
            Text("内容区域")
                .font(.title3.weight(.semibold))
                .opacity(on ? 1 : 0)
                .offset(y: on ? 0 : 10)
                .animation(.easeOut(duration: 0.28), value: on)
        }
        .onAppear(perform: play)
        .onChange(of: replayToken) { play() }
    }
    private func play() { on = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { on = true } }
}

// MARK: 3) Pop 弹入（缩放）
struct PopInCard: View {
    @State private var on = false
    let replayToken: Int

    var body: some View {
        CardShell(title: "3) Pop 弹入",
                  subtitle: "scale 0.96 → 1.00 + 轻回弹",
                  icon: "sparkles",
                  replay: { play() }) {
            Text("内容区域")
                .font(.title3.weight(.semibold))
                .scaleEffect(on ? 1.0 : 0.96)
                .opacity(on ? 1 : 0)
                .animation(.spring(duration: 0.32, bounce: 0.35), value: on)
        }
        .onAppear(perform: play)
        .onChange(of: replayToken) { play() }
    }
    private func play() { on = false; DispatchQueue.main.async { on = true } }
}

// MARK: 4) Blur-In 模糊转清晰
struct BlurInCard: View {
    @State private var on = false
    let replayToken: Int

    var body: some View {
        CardShell(title: "4) Blur-In",
                  subtitle: "先虚后实 280–360ms",
                  icon: "drop",
                  replay: { play() }) {
            Text("内容区域")
                .font(.title3.weight(.semibold))
                .blur(radius: on ? 0 : 8)
                .opacity(on ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: on)
        }
        .onAppear(perform: play)
        .onChange(of: replayToken) {  play() }
    }
    private func play() { on = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { on = true } }
}

// MARK: 5) Mask Wipe 擦拭显现（遮罩仅作用内容区）
struct MaskWipeCard: View {
    @State private var progress: CGFloat = 0
    let replayToken: Int

    var body: some View {
        CardShell(title: "5) Mask Wipe 擦拭",
                  subtitle: "方向与列表一致（此处水平）",
                  icon: "rectangle.lefthalf.inset.filled",
                  replay: { play() }) {
            ZStack {
                Text("内容区域").font(.title3.weight(.semibold))
            }
            .mask(alignment: .leading) {           // 关键：只裁内容区，左贴齐
                GeometryReader { geo in
                    Rectangle()
                        .frame(width: geo.size.width * progress)
                }
            }
            .animation(.easeOut(duration: 0.34), value: progress)
        }
        .onAppear(perform: play)
        .onChange(of: replayToken) { play() }
    }
    private func play() {
        progress = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { progress = 1 }
    }
}

// MARK: 6) 方向滑入（从左）
struct DirectionalSlideCard: View {
    @State private var on = false
    let replayToken: Int

    var body: some View {
        CardShell(title: "6) 方向滑入（从左）",
                  subtitle: "16–24pt 位移 + 淡入",
                  icon: "arrow.right.to.line",
                  replay: { play() }) {
            Text("内容区域")
                .font(.title3.weight(.semibold))
                .opacity(on ? 1 : 0)
                .offset(x: on ? 0 : -18)
                .animation(.easeOut(duration: 0.28), value: on)
        }
        .onAppear(perform: play)
        .onChange(of: replayToken) {  play() }
    }
    private func play() { on = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { on = true } }
}

// MARK: 7) 轻微 3D Tilt 立起
struct Tilt3DCard: View {
    @State private var on = false
    let replayToken: Int

    var body: some View {
        CardShell(title: "7) 3D Tilt 立起",
                  subtitle: "4–6° → 0° + 阴影恢复",
                  icon: "cube.transparent",
                  replay: { play() }) {
            Text("内容区域")
                .font(.title3.weight(.semibold))
                .rotation3DEffect(.degrees(on ? 0 : 6), axis: (x: 1, y: 0, z: 0), anchor: .bottom)
                .shadow(color: .black.opacity(on ? 0.1 : 0.25), radius: on ? 8 : 16, y: on ? 6 : 12)
                .opacity(on ? 1 : 0.0)
                .animation(.easeOut(duration: 0.32), value: on)
        }
        .onAppear(perform: play)
        .onChange(of: replayToken) { play() }
    }
    private func play() { on = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { on = true } }
}

// MARK: 8) Stroke → Fill（轮廓先到、内容后到）
struct StrokeThenFillCard: View {
    @State private var strokeOn = false
    @State private var contentOn = false
    let replayToken: Int

    var body: some View {
        CardShell(title: "8) Stroke → Fill",
                  subtitle: "边框 160–200ms，内容随后",
                  icon: "square.dashed.inset.filled",
                  replay: { play() }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.blue, lineWidth: 2)
                    .opacity(strokeOn ? 1 : 0)
                    .animation(.easeOut(duration: 0.18), value: strokeOn)

                Text("内容区域")
                    .font(.title3.weight(.semibold))
                    .opacity(contentOn ? 1 : 0)
                    .animation(.easeOut(duration: 0.24).delay(0.12), value: contentOn)
            }
        }
        .onAppear(perform: play)
        .onChange(of: replayToken) {  play() }
    }
    private func play() {
        strokeOn = false; contentOn = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            strokeOn = true; contentOn = true
        }
    }
}

// MARK: 9) 错峰入场（水平精选行）
struct StaggeredRow: View {
    @State private var on = false
    let replayToken: Int
    private let items = Array(0..<5)

    var body: some View {
        CardShell(title: "9) 错峰入场（水平精选行）",
                  subtitle: "每张间隔 40–80ms，总时长 ≤ 600ms",
                  icon: "square.grid.2x2",
                  replay: { play() }) {
            HStack(spacing: 12) {
                ForEach(items, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white.opacity(0.08))
                        .frame(width: 90, height: 70)
                        .overlay { Text("卡 \(i+1)").font(.footnote.weight(.semibold)) }
                        .opacity(on ? 1 : 0)
                        .offset(y: on ? 0 : 10)
                        .animation(.easeOut(duration: 0.22).delay(Double(i) * 0.06), value: on)
                }
            }
        }
        .onAppear(perform: play)
        .onChange(of: replayToken) {  play() }
    }
    private func play() { on = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { on = true } }
}

// MARK: 10) 领头强调（首张轻弹，其余淡入）
struct LeadEmphasisRow: View {
    @State private var on = false
    let replayToken: Int
    private let items = Array(0..<5)

    var body: some View {
        CardShell(title: "10) 领头强调",
                  subtitle: "首张轻弹，其他淡入；聚焦但克制",
                  icon: "rectangle.leadinghalf.inset.filled",
                  replay: { play() }) {
            HStack(spacing: 12) {
                ForEach(items, id: \.self) { i in
                    let isLead = i == 0
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white.opacity(0.08))
                        .frame(width: 90, height: 70)
                        .overlay { Text(isLead ? "主卡" : "卡 \(i+1)").font(.footnote.weight(.semibold)) }
                        .scaleEffect(on ? 1.0 : (isLead ? 0.95 : 1.0))
                        .opacity(on ? 1 : 0)
                        .offset(y: on ? 0 : (isLead ? 0 : 8))
                        .animation(
                            isLead
                            ? .spring(duration: 0.34, bounce: 0.45)
                            : .easeOut(duration: 0.22).delay(Double(i) * 0.05),
                            value: on
                        )
                }
            }
        }
        .onAppear(perform: play)
        .onChange(of: replayToken) {  play() }
    }
    private func play() { on = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { on = true } }
}

// MARK: - 预览
#Preview("Card Effects · Fixed") {
    CardAppearEffectsDemo()
        .preferredColorScheme(.dark)
}


*/
