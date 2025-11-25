//
//  WelcomeView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/31.
//

import SwiftUI



// MARK: - Page 1｜滑雪记录（首入主卡 0.94→1.0 回弹）


import SwiftUI

struct WelcomePage1View: View {
    private let imageSpring = Animation.spring(response: 0.70, dampingFraction: 0.85) // 图的回弹
    private let textFade    = Animation.easeOut(duration: 0.45)                        // 文案淡入
    private let gap: Double = 0.30                                                     // 图与文的时间间隔

    @State private var imageIn = false
    @State private var textIn  = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // 标题 + 副文案（布局在上，但动效仍然 "先图后文"）
                VStack(spacing: 8) {
                    Text("记录每一公里")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    // 新增：副文案，样式与 Page2 一致
                    Text("轻量：即开即用，回归工具本质拒绝臃肿")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .opacity(textIn ? 1 : 0)
                .offset(y: textIn ? 0 : 8)
                .animation(textFade, value: textIn)

                .padding(.top, 24)

                // 图片（recording）——顶边做渐隐，入场 0.94→1.0 弹簧
                Group {
                    if let ui = UIImage(named: "recording") {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                            // 顶部 8% 渐隐，避免“被裁掉的上沿”显得突兀
                            .mask(
                                LinearGradient(stops: [
                                    .init(color: .clear, location: 0.00),
                                    .init(color: .black,  location: 0.08),
                                    .init(color: .black,  location: 1.00),
                                ], startPoint: .top, endPoint: .bottom)
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
                .scaleEffect(imageIn ? 1.0 : 0.94)
                .opacity(imageIn ? 1 : 0)
                .animation(imageSpring, value: imageIn)


                Spacer(minLength: 12)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            // 动效顺序：先图，再文
            imageIn = true
            DispatchQueue.main.asyncAfter(deadline: .now() + gap) {
                textIn = true
            }

        }
    }
}


// MARK: - Page 2｜雪场信息 + 社区（你的图片 + 轻入场）




struct WelcomePage2View: View {
    @State private var textIn  = false
    @State private var imageIn = false
    private let imageSpring = Animation.spring(response: 0.70, dampingFraction: 0.85)
    private let textFade    = Animation.easeOut(duration: 0.45)
    private let gap: Double = 0.35   // 建议 Page2 比 Page1 稍大一点

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // 图片在上（布局），但动效上“先文字后图片”
                Group {
                    if let ui = UIImage(named: "resort") {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                            // 底部 8% 渐隐，预留“被截断”的自然过渡
                            .mask(
                                LinearGradient(stops: [
                                    .init(color: .black,  location: 0.00),
                                    .init(color: .black,  location: 0.92),
                                    .init(color: .clear, location: 1.00),
                                ], startPoint: .top, endPoint: .bottom)
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
                .scaleEffect(imageIn ? 1.0 : 0.94)
                .opacity(imageIn ? 1 : 0)
                .animation(imageSpring, value: imageIn)


                // 仅保留两段文案
                VStack(spacing: 8) {
                    Text("实时雪场信息与社区")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text("开放/雪况/人流，搭配真实分享，帮你选对雪场。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .opacity(textIn ? 1 : 0)
                .offset(y: textIn ? 0 : 8)
                .animation(textFade, value: textIn)


                Spacer(minLength: 12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .onAppear {
            // 动效顺序：先文字，再图片
            textIn = true
            DispatchQueue.main.asyncAfter(deadline: .now() + gap) {
                imageIn = true
            }

        }
    }
}





// MARK: - Page 3：雪圈 + 失物招领（叠放但不遮挡）
struct WelcomePage3View: View {
    @State private var showTop = false
    @State private var showBottom = false

    // 动画参数（可调）
    private let springIn  = Animation.spring(response: 0.70, dampingFraction: 0.88)
    private let delayGap  = 0.12

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                // 标题与副文案保持不变（如需）
                VStack(spacing: 8) {
                    Text("雪圈与失物招领")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text("经验分享、现场提醒与失物找回，让每次上雪都更顺。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }

                // 两个叠放的白底气泡（错位更小，但不遮正文）
                ZStack {
                    // 下层卡：失物招领（明显向下，完全不挡上卡正文）
                    BubbleCard(
                        text:
"""
【失物招领】白色滑雪镜（紫镜片）从餐厅到 B 线路上丢的，捡到发我私信/交服务台就行，请你喝热可可 ☕️
"""
                    )
                    .opacity(showBottom ? 1 : 0)
                    .rotationEffect(.degrees(showBottom ? 0 : 2))                 // 轻旋转
                    .offset(x: showBottom ? 12 : 36, y: showBottom ? 56 : 72)     // 关键：更往下
                    .zIndex(1)
                    .animation(springIn.delay(delayGap), value: showBottom)

                    // 上层卡：雪况（微上移、轻旋转）
                    BubbleCard(
                        text:
"""
新雪 2–3cm 表层松软，阴坡很爽，人少雪好 速来～
"""
                    )
                    .opacity(showTop ? 1 : 0)
                    .rotationEffect(.degrees(showTop ? 0 : -2))
                    .offset(x: showTop ? -12 : -36, y: showTop ? -24 : -36)
                    .zIndex(2) // 上层
                    .animation(springIn, value: showTop)
                }
                .frame(maxWidth: 360, minHeight: 360) // 提高高度余量，避免裁切

                // 底部补充文案（与气泡保持间距）
                Text("再小的雪场，也有雪友和信息在。")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
                    .padding(.top, 12)

                Spacer(minLength: 12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
        .onAppear {
            showTop = true
            DispatchQueue.main.asyncAfter(deadline: .now() + delayGap) {
                showBottom = true
            }
        }
    }
}

// MARK: - 白底气泡卡（确保全文展示）
struct BubbleCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true) // 关键：纵向自适应，避免截断
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
        .accessibilityElement(children: .combine)
    }
}







// MARK: - Page 4｜社区共建 & 号召（三 Banner 依次出场）
struct WelcomePage4View: View {
    @State private var appear = false        // 标题/副文案
    @State private var showB1 = false        // Banner 1：一起把滑雪信息做对、做全（雪花）
    @State private var showB2 = false        // Banner 2：持续更新 · 更多精彩（sparkles）
    @State private var showB3 = false        // Banner 3：倾听体验，不断改进（气泡）

    // 动画与间隔（可微调）
    private let titleIn  = Animation.easeOut(duration: 0.45)
    private let cardIn   = Animation.spring(response: 0.70, dampingFraction: 0.88)
    private let gap12: Double = 0.35   // Banner1 -> Banner2 的间隔
    private let gap23: Double = 0.30   // Banner2 -> Banner3 的间隔

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                // 标题
                Text("上雪，和你一起完善")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 10)
                    .animation(titleIn, value: appear)

                // 副文案
                Text("你的一次补充，能帮到很多雪友。现在就开始吧！")
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 8)
                    .animation(titleIn.delay(0.05), value: appear)

                // Banner 1：原有（snowflake）
                HStack(spacing: 16) {
                    Image(systemName: "snowflake")
                        .font(.title2.weight(.bold))
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text("一起把滑雪信息做对、做全").font(.headline)
                        Text("开放更新、真实分享、共同完善。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(18)
                .frame(maxWidth: 360)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                .opacity(showB1 ? 1 : 0)
                .offset(y: showB1 ? 0 : 10)
                .animation(cardIn, value: showB1)

                // Banner 2：持续更新 · 更多精彩（sparkles）
                HStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.title2.weight(.bold))
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text("持续更新 · 更多精彩").font(.headline)
                        Text("功能会不断上线，欢迎提出建议与反馈。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(18)
                .frame(maxWidth: 360)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                .opacity(showB2 ? 1 : 0)
                .offset(y: showB2 ? 0 : 10)
                .animation(cardIn, value: showB2)

                // Banner 3：倾听体验，不断改进（聊天气泡）
                HStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.title2.weight(.bold))
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text("倾听体验，不断改进").font(.headline)
                        Text("我们会根据雪友的真实使用感受持续优化细节。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(18)
                .frame(maxWidth: 360)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                .opacity(showB3 ? 1 : 0)
                .offset(y: showB3 ? 0 : 10)
                .animation(cardIn, value: showB3)

                Spacer(minLength: 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        .onAppear {
            appear = true
            showB1 = true
            DispatchQueue.main.asyncAfter(deadline: .now() + gap12) {
                showB2 = true
                DispatchQueue.main.asyncAfter(deadline: .now() + gap23) {
                    showB3 = true
                }
            }
        }
    }
}


// MARK: - Image Helper（优先显示你的图片，缺失时给占位）
struct ImageOrPlaceholder: View {
    let name: String
    let label: String

    init(_ name: String, label: String) {
        self.name = name
        self.label = label
    }

    var body: some View {
        Group {
            if let ui = UIImage(named: name) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(label)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .padding(16)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

// MARK: - Previews
struct WelcomeFlow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WelcomeFlowView()
                .previewDisplayName("Onboarding - Light")
                .environment(\.colorScheme, .light)
                .previewDevice("iPhone 15 Pro")

            WelcomeFlowView()
                .previewDisplayName("Onboarding - Dark")
                .environment(\.colorScheme, .dark)
                .previewDevice("iPhone 15 Pro")
        }
    }
}
