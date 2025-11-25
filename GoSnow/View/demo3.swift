//
//  demo3.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/16.
//
/*
import SwiftUI
import Combine

// MARK: - Demo Container (10 effects)
struct TextAnimationDemo: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                FadeSlideInText(text: "你好世界")
                StaggeredLettersText(text: "你好世界")
                ShimmerText(text: "你好世界")
                BlurInText(text: "你好世界")
                WordCascadeText(text: "Hello World")
                TypewriterText(text: "你好世界")
                NumericCounterText()
                ErrorShakeText(text: "你好世界")
                PulseEmphasisText(text: "你好世界")
                WaveBaselineText(text: "你好世界")
            }
            .padding(24)
        }
        .background(Color.black.opacity(0.92).ignoresSafeArea())
    }
}

// 共用的卡片样式（可按需改）
private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.white.opacity(0.06), in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12))
            }
    }
}
private extension View { func cardStyle() -> some View { modifier(CardStyle()) } }

// MARK: - 1) 淡入 + 上移（保留）
struct FadeSlideInText: View {
    let text: String
    @State private var appear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("1) Fade + Slide In", systemImage: "arrow.down.forward.and.arrow.up.backward")
                .font(.caption).foregroundStyle(.white.opacity(0.6))

            Text(text)
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 12)
                .animation(.easeOut(duration: 0.5), value: appear)

            Button("Replay") { replay() }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.12)).foregroundStyle(.white)
        }
        .cardStyle()
        .onAppear { replay() }
    }
    private func replay() {
        appear = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appear = true }
    }
}

// MARK: - 2) 按字母错峰淡入（保留）
struct StaggeredLettersText: View {
    let text: String
    @State private var started = false
    var letters: [String] { text.map { String($0) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("2) Staggered Letters", systemImage: "textformat.abc")
                .font(.caption).foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 0) {
                ForEach(Array(letters.enumerated()), id: \.offset) { index, ch in
                    Text(ch)
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .opacity(started ? 1 : 0)
                        .offset(y: started ? 0 : 8)
                        .animation(
                            .spring(duration: 0.5, bounce: 0.4)
                                .delay(Double(index) * 0.04),
                            value: started
                        )
                }
            }

            Button("Replay") { started = false; kick() }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.12)).foregroundStyle(.white)
        }
        .cardStyle()
        .onAppear { kick() }
    }
    private func kick() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { started = true }
    }
}

// MARK: - 3) Shimmer 扫光（保留）
struct ShimmerText: View {
    let text: String
    @State private var phase: CGFloat = -1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("3) Shimmer", systemImage: "sparkles")
                .font(.caption).foregroundStyle(.white.opacity(0.6))

            Text(text)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.25))
                .overlay {
                    LinearGradient(
                        colors: [.white.opacity(0), .white.opacity(0.85), .white.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .scaleEffect(x: 0.2, anchor: .center)
                    .offset(x: phase * 300)
                    .mask(
                        Text(text).font(.system(size: 40, weight: .bold, design: .rounded))
                    )
                }
                .onAppear {
                    withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                        phase = 1.0
                    }
                }

            Button("Replay") {
                phase = -1.0
                withAnimation(.linear(duration: 1.8)) { phase = 1.0 }
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.12)).foregroundStyle(.white)
        }
        .cardStyle()
    }
}

// MARK: - 4) Blur-In 模糊入场
struct BlurInText: View {
    let text: String
    @State private var on = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("4) Blur-In", systemImage: "drop")
                .font(.caption).foregroundStyle(.white.opacity(0.6))

            Text(text)
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .opacity(on ? 1 : 0)
                .blur(radius: on ? 0 : 8)
                .scaleEffect(on ? 1 : 0.98)
                .animation(.easeOut(duration: 0.6), value: on)

            Button("Replay") { play() }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.12)).foregroundStyle(.white)
        }
        .cardStyle()
        .onAppear { play() }
    }
    private func play() {
        on = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { on = true }
    }
}

// MARK: - 5) 逐词级联（word-by-word）
struct WordCascadeText: View {
    let text: String
    @State private var on = false
    var words: [String] { text.split(separator: " ").map(String.init) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("5) Word Cascade", systemImage: "text.justify")
                .font(.caption).foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 8) {
                ForEach(Array(words.enumerated()), id: \.offset) { idx, w in
                    Text(w)
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .opacity(on ? 1 : 0)
                        .offset(y: on ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(Double(idx) * 0.12), value: on)
                }
            }

            Button("Replay") { on = false; kick() }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.12)).foregroundStyle(.white)
        }
        .cardStyle()
        .onAppear { kick() }
    }
    private func kick() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { on = true }
    }
}

// MARK: - 6) 打字机 + 光标闪烁
struct TypewriterText: View {
    let text: String
    @State private var visibleCount = 0
    @State private var caretBlink = false
    @State private var timerCancellable: AnyCancellable?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("6) Typewriter", systemImage: "keyboard")
                .font(.caption).foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 0) {
                Text(String(text.prefix(visibleCount)))
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                // 光标
                Rectangle()
                    .fill(.white)
                    .frame(width: 2, height: 34)
                    .opacity(caretBlink ? 1 : 0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(), value: caretBlink)
            }

            Button("Replay") { startTyping() }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.12)).foregroundStyle(.white)
        }
        .cardStyle()
        .onAppear { startTyping() }
        .onDisappear { timerCancellable?.cancel() }
    }

    private func startTyping() {
        timerCancellable?.cancel()
        visibleCount = 0
        caretBlink = true
        let pub = Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()
        timerCancellable = pub.sink { _ in
            if visibleCount < text.count {
                visibleCount += 1
            } else {
                // 停住显示，保留光标闪烁
                timerCancellable?.cancel()
            }
        }
    }
}

// MARK: - 7) 数值滚动（.numericText）+ 自动计数
struct NumericCounterText: View {
    @State private var value = 0
    @State private var target = 2025
    @State private var timerCancellable: AnyCancellable?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("7) Numeric Roll (.numericText)", systemImage: "number")
                .font(.caption).foregroundStyle(.white.opacity(0.6))

            Text("\(value)")
                .contentTransition(.numericText()) // iOS 17+
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .animation(.easeOut(duration: 0.25), value: value)

            HStack {
                Button("Replay") { play(to: Int.random(in: 1000...9999)) }
                Button("→ 2025") { play(to: 2025) }
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.12)).foregroundStyle(.white)
        }
        .cardStyle()
        .onAppear { play(to: target) }
        .onDisappear { timerCancellable?.cancel() }
    }

    private func play(to newTarget: Int) {
        timerCancellable?.cancel()
        let start = value
        let diff = newTarget - start
        guard diff != 0 else { return }

        let steps = max(20, min(80, abs(diff))) // 控制步数
        var tick = 0
        target = newTarget

        let pub = Timer.publish(every: 0.015, on: .main, in: .common).autoconnect()
        timerCancellable = pub.sink { _ in
            tick += 1
            let progress = Double(tick) / Double(steps)
            // 缓动：easeOut
            let eased = 1 - pow(1 - progress, 3)
            value = start + Int(Double(diff) * eased)
            if tick >= steps {
                value = newTarget
                timerCancellable?.cancel()
            }
        }
    }
}

// MARK: - 8) 错误抖动（Shake）
struct ErrorShakeText: View {
    let text: String
    @State private var shakes: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("8) Error Shake", systemImage: "exclamationmark.triangle")
                .font(.caption).foregroundStyle(.white.opacity(0.6))

            Text(text)
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .modifier(ShakeEffect(animatableData: shakes))

            HStack {
                Button("Trigger Error") { withAnimation(.easeIn(duration: 0.6)) { shakes += 1 } }
                Button("Replay") { shakes = 0; withAnimation(.easeIn(duration: 0.6)) { shakes += 1 } }
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.12)).foregroundStyle(.white)
        }
        .cardStyle()
    }
}
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * shakesPerUnit * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// MARK: - 9) 脉冲强调（Pulse）
struct PulseEmphasisText: View {
    let text: String
    @State private var on = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("9) Pulse Emphasis", systemImage: "dot.radiowaves.left.and.right")
                .font(.caption).foregroundStyle(.white.opacity(0.6))

            Text(text)
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .scaleEffect(on ? 1.0 : 0.94)
                .shadow(color: .white.opacity(on ? 0.35 : 0.0), radius: 12)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: on)

            Button("Replay") { on = false; kick() }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.12)).foregroundStyle(.white)
        }
        .cardStyle()
        .onAppear { kick() }
    }
    private func kick() {
        DispatchQueue.main.async {
            on = true
        }
    }
}

// MARK: - 10) 波浪基线（Wave Baseline）
struct WaveBaselineText: View {
    let text: String
    @State private var phase: CGFloat = 0
    var letters: [String] { text.map { String($0) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("10) Baseline Wave", systemImage: "waveform.path")
                .font(.caption).foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 0) {
                ForEach(Array(letters.enumerated()), id: \.offset) { i, ch in
                    Text(ch)
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .baselineOffset(sin((phase + CGFloat(i)) / 3) * 6) // 波幅
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    phase = 24 // 控制波速/相位
                }
            }

            Button("Replay") { phase = 0; withAnimation(.linear(duration: 1.6)) { phase = 24 } }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.12)).foregroundStyle(.white)
        }
        .cardStyle()
    }
}

// MARK: - Preview
#Preview {
    TextAnimationDemo()
        .preferredColorScheme(.dark)
}
*/
