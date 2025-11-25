//
//  OnboardingView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/17.
//

import SwiftUI

// MARK: - Root Flow

struct OnboardingFlowView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    @State private var page: Int = 0
    @State private var showConfetti = false

    var onFinish: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Background gradient changes with page
            backgroundForPage(page)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Spacer()
                    Button("跳过") {
                        finish()
                    }
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 12)
                    .padding(.trailing, 20)
                }
                .frame(height: 44)

                // Pages
                TabView(selection: $page) {
                    Page1_Record()
                        .tag(0)
                    Page2_ResortInfo()
                        .tag(1)
                    Page3_CommunityAndLost()
                        .tag(2)
                    Page4_Together()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .animation(.easeInOut(duration: 0.28), value: page)

                // Bottom CTA
                VStack(spacing: 12) {
                    PrimaryCTAButton(
                        title: page == 3 ? "开始使用" : "继续",
                        action: {
                            if page < 3 {
                                page += 1
                                lightHaptic()
                            } else {
                                // Confetti + finish
                                rigidHaptic()
                                withAnimation(.easeOut(duration: 0.5)) {
                                    showConfetti = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    withAnimation(.easeIn(duration: 0.25)) {
                                        showConfetti = false
                                    }
                                    finish()
                                }
                            }
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }

            // Confetti overlay
            if showConfetti {
                SnowConfettiView()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
    }

    private func finish() {
        hasSeenOnboarding = true
        onFinish?()
    }

    @ViewBuilder
    private func backgroundForPage(_ page: Int) -> some View {
        switch page {
        case 0:
            LinearGradient(
                colors: [Color(hex: 0x0B1E3C), Color(hex: 0x0C6C6E)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1:
            LinearGradient(
                colors: [Color(hex: 0x0E3A8A), Color(hex: 0x1D4ED8)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2:
            LinearGradient(
                colors: [Color(hex: 0x3730A3), Color(hex: 0x4F46E5)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            LinearGradient(
                colors: [Color(hex: 0x0C6C6E), Color(hex: 0xEEF2FF)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func lightHaptic() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    private func rigidHaptic() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        #endif
    }
}

// MARK: - Page 1: 记录每一公里

struct Page1_Record: View {
    @State private var appear = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 12)

            // Hero
            HeroRecordCard()
                .scaleEffect(appear ? 1.0 : 0.94)
                .opacity(appear ? 1 : 0)
                .shadow(color: .black.opacity(0.1), radius: 16, y: 10)
                .animation(.spring(response: 0.55, dampingFraction: 0.86, blendDuration: 0.2), value: appear)

            // Texts
            VStack(spacing: 6) {
                Text("记录每一公里")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 10)
                    .animation(.easeOut(duration: 0.25).delay(0.05), value: appear)

                Text("自动生成日记与里程，成长一目了然。")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 10)
                    .animation(.easeOut(duration: 0.25).delay(0.12), value: appear)
            }

            Spacer()
        }
        .onAppear { appear = true }
    }
}

// MARK: - Page 2: 雪场信息 + 社区

struct Page2_ResortInfo: View {
    @State private var appear = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 12)

            HeroResortInfoCard()
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 18)
                .animation(.spring(response: 0.5, dampingFraction: 0.9), value: appear)

            VStack(spacing: 6) {
                Text("实时雪场信息与社区")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 10)
                    .animation(.easeOut(duration: 0.25).delay(0.05), value: appear)

                Text("开放/雪况/风温/人流，搭配真实分享，帮你选对雪场。")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 10)
                    .animation(.easeOut(duration: 0.25).delay(0.12), value: appear)
            }

            Spacer()
        }
        .onAppear { appear = true }
    }
}

// MARK: - Page 3: 雪圈 + 失物招领

struct Page3_CommunityAndLost: View {
    @State private var appearLeft = false
    @State private var appearRight = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 12)

            HeroCommunityStack(appearLeft: appearLeft, appearRight: appearRight)

            VStack(spacing: 6) {
                Text("雪圈与失物招领")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("经验分享、现场提醒与失物找回，让每次出雪都更顺。")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            .opacity(appearLeft && appearRight ? 1 : 0)
            .offset(y: appearLeft && appearRight ? 0 : 10)
            .animation(.easeOut(duration: 0.25), value: appearRight)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                appearLeft = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.12)) {
                appearRight = true
            }
        }
    }
}

// MARK: - Page 4: 共建 & 号召

struct Page4_Together: View {
    @State private var appear = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 12)

            HeroFinalBanner()
                .opacity(appear ? 1 : 0)
                .scaleEffect(appear ? 1.0 : 0.96)
                .shadow(color: .black.opacity(0.1), radius: 16, y: 8)
                .animation(.spring(response: 0.55, dampingFraction: 0.9), value: appear)

            VStack(spacing: 6) {
                Text("上雪，和你一起完善")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("你的一次补充，能帮到很多雪友。现在就开始吧！")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 10)
            .animation(.easeOut(duration: 0.25).delay(0.08), value: appear)

            Spacer()
        }
        .onAppear { appear = true }
    }
}

// MARK: - Hero: Record Card

struct HeroRecordCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animateCount = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("今日滑行", systemImage: "snowflake")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Date(), style: .date)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // Big number (today km)
            CountingNumberText(
                target: 7.8,
                duration: reduceMotion ? 0.0 : 0.9,
                format: .number.precision(.fractionLength(1))
            )
            .font(.system(size: 44, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
            .overlay(alignment: .trailing) {
                Text(" km")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary.opacity(0.9))
                    .baselineOffset(2)
                    .padding(.leading, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Chips
            HStack(spacing: 8) {
                MetricChip(symbol: "figure.skiing.downhill", title: "总里程", value: 235.4, unit: "km", duration: 0.8)
                MetricChip(symbol: "calendar", title: "在雪天数", value: 21, unit: "天", duration: 0.8)
                MetricChip(symbol: "clock", title: "累计时长", value: 58, unit: "h", duration: 0.8, fractionDigits: 0)
            }
        }
        .padding(20)
        .frame(maxWidth: 360)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Hero: Resort Info Card

struct HeroResortInfoCard: View {
    struct Item: Identifiable { let id = UUID(); let icon: String; let title: String; let value: String }

    @State private var appear = false

    private let items: [Item] = [
        .init(icon: "checkmark.seal.fill", title: "开放", value: "正常"),
        .init(icon: "wind", title: "风速", value: "6 m/s"),
        .init(icon: "thermometer.snowflake", title: "温度", value: "-5 ℃"),
        .init(icon: "person.3", title: "人流", value: "适中")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("雪场概览", systemImage: "mountain.2")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.1.id) { idx, item in
                    HStack(spacing: 10) {
                        Image(systemName: item.icon)
                            .font(.title3.weight(.semibold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.footnote).foregroundStyle(.secondary)
                            Text(item.value).font(.callout.weight(.semibold))
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(.gray.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .opacity(appear ? 1 : 0)
                    .offset(x: appear ? 0 : offsetForIndex(idx).width,
                            y: appear ? 0 : offsetForIndex(idx).height)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.05 * Double(idx)), value: appear)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: 360)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .onAppear { appear = true }
    }

    private func offsetForIndex(_ idx: Int) -> CGSize {
        switch idx {
        case 0: return CGSize(width: -20, height: -8) // 12 点方向
        case 1: return CGSize(width: 20, height: -8)  // 3 点方向
        case 2: return CGSize(width: -20, height: 8)  // 9 点方向
        default: return CGSize(width: 20, height: 8)  // 6 点方向
        }
    }
}

// MARK: - Hero: Community + Lost & Found

struct HeroCommunityStack: View {
    let appearLeft: Bool
    let appearRight: Bool

    var body: some View {
        ZStack {
            // Right card (Lost & Found)
            VStack(alignment: .leading, spacing: 10) {
                Label("失物招领", systemImage: "magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("不再担心发现或丢失物品时无从下手")
                    .font(.callout)
                HStack {
                    TagText("滑雪镜")
                    TagText("手套")
                    TagText("对讲机")
                }
            }
            .padding(18)
            .frame(width: 300)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .rotationEffect(.degrees(appearRight ? 0 : 3))
            .offset(x: appearRight ? 24 : 60, y: appearRight ? 20 : 40)
            .opacity(appearRight ? 1 : 0)

            // Left card (Snow Circle)
            VStack(alignment: .leading, spacing: 10) {
                Label("雪圈时刻", systemImage: "pencil.and.scribble")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("经验分享、现场提醒与实时雪况")
                    .font(.callout)
                HStack(spacing: 8) {
                    Image(systemName: "hand.thumbsup.fill"); Text("128")
                    Image(systemName: "message.fill"); Text("24")
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(width: 300)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .rotationEffect(.degrees(appearLeft ? 0 : -3))
            .offset(x: appearLeft ? -24 : -60, y: appearLeft ? -12 : -40)
            .opacity(appearLeft ? 1 : 0)
        }
        .frame(maxWidth: 360, minHeight: 260)
    }
}

// MARK: - Hero: Final Banner

struct HeroFinalBanner: View {
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.blue.opacity(0.12)).frame(width: 64, height: 64)
                Image(systemName: "snowflake")
                    .font(.title2.weight(.bold))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("一起把滑雪信息做对、做全")
                    .font(.headline)
                Text("你的每次补充，都可能帮到无数雪友。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: 360)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Components

struct PrimaryCTAButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}

struct TagText: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 999))
    }
}

struct MetricChip: View {
    let symbol: String
    let title: String
    let value: Double
    let unit: String
    let duration: Double
    var fractionDigits: Int = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.callout.weight(.semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 2) {
                    CountingNumberText(
                        target: value,
                        duration: reduceMotion ? 0 : duration,
                        format: .number.precision(.fractionLength(fractionDigits))
                    )
                    .font(.callout.weight(.semibold))
                    Text(unit).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// Counting numeric text with smooth animation + numericText transition
struct CountingNumberText: View {
    let target: Double
    let duration: Double
    let format: FloatingPointFormatStyle<Double>

    @State private var animValue: Double = 0

    var body: some View {
        Text(animValue, format: format)
            .contentTransition(.numericText())
            .onAppear {
                animValue = 0
                withAnimation(.easeOut(duration: max(0, duration))) {
                    animValue = target
                }
            }
            .onChange(of: target) { _, new in
                withAnimation(.easeOut(duration: max(0, duration))) {
                    animValue = new
                }
            }
    }
}

// Simple snow confetti using Canvas
struct SnowConfettiView: View {
    @State private var time: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60.0)) { timeline in
            Canvas { ctx, size in
                let t = time
                let count = 28
                for i in 0..<count {
                    let progress = (CGFloat(i) / CGFloat(count))
                    let x = size.width * progress + sin(t + progress * 10) * 20
                    let y = (t * 120 + CGFloat(i) * 12).truncatingRemainder(dividingBy: max(size.height, 1))
                    var path = Path()
                    let r: CGFloat = 3 + (CGFloat(i).truncatingRemainder(dividingBy: 5))
                    path.addRoundedRect(in: CGRect(x: x, y: y, width: r, height: r), cornerSize: CGSize(width: r/2, height: r/2))
                    ctx.fill(path, with: .color(.white.opacity(0.9)))
                }
            }
            .onChange(of: timeline.date) { _, _ in
                time += 0.016
            }
        }
        .ignoresSafeArea()
        .transition(.opacity)
    }
}

// MARK: - Utils

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xff) / 255.0
        let g = Double((hex >> 8) & 0xff) / 255.0
        let b = Double(hex & 0xff) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - Preview

struct OnboardingFlow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingFlowView()
                .previewDisplayName("Onboarding - iPhone")
                .environment(\.colorScheme, .dark)
                .previewDevice("iPhone 15 Pro")

            OnboardingFlowView()
                .previewDisplayName("Onboarding - iPad")
                .environment(\.colorScheme, .dark)
                .previewDevice("iPad Pro (11-inch) (4th generation)")
        }
    }
}
