//
//  ContentView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/6/18.
//

import SwiftUI

// MARK: - 仅保留三个 Tab（记录/雪场/雪圈）
enum MainTab: CaseIterable, Hashable {
    case home, resorts, community

    var icon: String {
        switch self {
        case .home:      return "record.circle.fill"
        case .resorts:   return "map.fill"
        case .community: return "sparkles"
        }
    }
}

// MARK: - 悬浮栏可见性
final class FloatingTabBarState: ObservableObject {
    @Published var isVisible: Bool = true
}

struct ContentView: View {
    @StateObject var userData = UserData()
    let statsStore: StatsStore

    // 只出现一次：欢迎页标记
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    // 登录状态
    @ObservedObject private var auth = AuthManager.shared

    @EnvironmentObject private var tabBarState: FloatingTabBarState

    // 选项卡
    @State private var tab: MainTab = .home
    @State private var visited: Set<MainTab> = [.home]
    @State private var tabBarHeight: CGFloat = 0
    private let allTabs = MainTab.allCases

    // Gate
    @State private var showWelcomeGate = false   // 欢迎页（登录后且未看过）
    @State private var showLoginGate   = false   // 登录入口

    var body: some View {
        ZStack {
            // 背景与首页一致
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            // 每个 tab 自己的 NavigationStack
            ZStack {
                switch tab {
                case .home:
                    NavigationStack { HomeDashboardView(store: statsStore) }
                case .resorts:
                    NavigationStack { ResortsCommunityView() }
                case .community:
                    NavigationStack { DailySnowView() }
                }
            }
            .animation(.easeInOut(duration: 0.18), value: tab)
        }
        // 悬浮胶囊 TabBar（仅图标）
        .safeAreaInset(edge: .bottom) {
            if tabBarState.isVisible {
                FloatingTabBar(selection: $tab, tabs: allTabs) { $0.icon }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: tabBarState.isVisible)
                    .background(
                        GeometryReader { g in
                            Color.clear.preference(key: TabBarHeightKey.self, value: g.size.height)
                        }
                    )
            }
        }
        .onPreferenceChange(TabBarHeightKey.self) { tabBarHeight = $0 }
        .environmentObject(userData)
        .preferredColorScheme(.light)
        .onChange(of: tab) { _, new in visited.insert(new) }
        .onChange(of: hasSeenOnboarding) { _, seen in
            if seen {
                showWelcomeGate = false
                tabBarState.isVisible = true
            }
        }


        .fullScreenCover(isPresented: $showWelcomeGate) {
            WelcomeFlowView()
                .hidesFloatingTabBar(tabBarState)
                .interactiveDismissDisabled(true)
        }


        // ② 登录入口（未登录时）
        .fullScreenCover(isPresented: $showLoginGate) {
            WelcomeAuthIntroView()
                .interactiveDismissDisabled(true)
                .onDisappear { Task { await AuthManager.shared.bootstrap() } }
                .hidesFloatingTabBar()
        }

        // 冷启动：拉会话 -> 决定先登录还是直接欢迎
        .task {
            await AuthManager.shared.bootstrap()
            if auth.session == nil {
                // 未登录 → 先登录
                showLoginGate = true
                tabBarState.isVisible = false
            } else if !hasSeenOnboarding {
                // 已登录但没看过欢迎页 → 弹欢迎
                showWelcomeGate = true
                tabBarState.isVisible = false
            }
        }

        // 会话变化联动
        .onChange(of: auth.session) { _, session in
            if session == nil {
                // 丢会话 → 去登录
                if !showWelcomeGate {
                    showLoginGate = true
                    tabBarState.isVisible = false
                }
            } else {
                // 登录成功 → 若尚未看过欢迎页，则弹出欢迎；否则恢复主界面
                if !hasSeenOnboarding {
                    showWelcomeGate = true
                } else {
                    showLoginGate = false
                    tabBarState.isVisible = true
                }
            }
        }

        // 兼容你的登出广播
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("userDidSignOut"))) { _ in
            if !showWelcomeGate {
                showLoginGate = true
                tabBarState.isVisible = false
            }
        }
    }

    // 包装每个 Tab 的可见与点击
    @ViewBuilder
    private func forTab<Content: View>(_ t: MainTab, @ViewBuilder _ content: () -> Content) -> some View {
        content()
            .opacity(t == tab ? 1 : 0)
            .allowsHitTesting(t == tab)
            .onAppear { visited.insert(t) }
    }
}

// MARK: - 悬浮胶囊 TabBar
private struct FloatingTabBar<Tab: Hashable>: View {
    @Binding var selection: Tab
    let tabs: [Tab]
    let icon:  (Tab) -> String

    @Namespace private var anim
    @Environment(\.colorScheme) private var scheme

    private var surface: Color { scheme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.10) : .white }
    private var border:  Color { scheme == .dark ? .white.opacity(0.10) : .black.opacity(0.08) }
    private var shadow:  Color { scheme == .dark ? .clear : .black.opacity(0.12) }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tabs, id: \.self) { tab in
                let isSel = (tab == selection)
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        selection = tab
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }
                } label: {
                    Image(systemName: icon(tab))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSel ? .primary : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if isSel {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill((scheme == .dark ? .white.opacity(0.10) : .black.opacity(0.06)))
                                        .matchedGeometryEffect(id: "pill", in: anim)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(border, lineWidth: 1 / UIScreen.main.scale)
                )
                .shadow(color: shadow, radius: 18, x: 0, y: 10)
        )
    }
}

struct HideFloatingTabBarInjected: ViewModifier {
    let state: FloatingTabBarState?
    func body(content: Content) -> some View {
        content
            .onAppear { withAnimation(.easeInOut(duration: 0.2)) { state?.isVisible = false } }
            .onDisappear { withAnimation(.easeInOut(duration: 0.2)) { state?.isVisible = true } }
    }
}
extension View {
    /// 显式传入状态（无则不做操作，也不崩）
    func hidesFloatingTabBar(_ state: FloatingTabBarState?) -> some View {
        modifier(HideFloatingTabBarInjected(state: state))
    }
    
}

// MARK: - TabBar 高度 PreferenceKey
private struct TabBarHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}


import SwiftUI



// MARK: - Root Flow (TabView 分页 + 统一 CTA)
struct WelcomeFlowView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                WelcomePage1View().tag(0)
                WelcomePage2View().tag(1)
                WelcomePage3View().tag(2)
                WelcomePage4View().tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // 统一底部 CTA（黑底白字）
            Button {
                if page < 3 {
                    page += 1
                    lightHaptic()
                } else {
                    rigidHaptic()        // 最后一页 rigid 触感
                    hasSeenOnboarding = true
                }
            } label: {
                Text(page == 3 ? "开始使用" : "继续")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.primary.opacity(0.9))              // 黑
                    .foregroundStyle(Color(UIColor.systemBackground))     // 白
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
        }
        .background(Color(UIColor.systemBackground))
        .interactiveDismissDisabled(true)
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








/*
 
 import SwiftUI

 // MARK: - 仅保留三个 Tab（记录/雪场/雪圈）
 enum MainTab: CaseIterable, Hashable {
     case home, resorts, community

     var icon: String {
         switch self {
         case .home:      return "record.circle.fill"
         case .resorts:   return "map.fill"
         case .community: return "sparkles"
         }
     }
 }

 // MARK: - 悬浮栏可见性
 final class FloatingTabBarState: ObservableObject {
     @Published var isVisible: Bool = true
 }

 struct ContentView: View {
     @StateObject var userData = UserData()
     let statsStore: StatsStore

     // 首次安装标记
     @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true

     // 登录状态
     @ObservedObject private var auth = AuthManager.shared

     @EnvironmentObject private var tabBarState: FloatingTabBarState

     // 选项卡
     @State private var tab: MainTab = .home
     @State private var visited: Set<MainTab> = [.home]
     @State private var tabBarHeight: CGFloat = 0
     private let allTabs = MainTab.allCases

     // Gate
     @State private var showWelcomeGate = false
     @State private var showLoginGate   = false

     var body: some View {
         ZStack {
             // 背景与首页一致
             LinearGradient(
                 colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                 startPoint: .top, endPoint: .bottom
             ).ignoresSafeArea()

             // 每个 tab 自己的 NavigationStack，互不干扰
             ZStack {
             switch tab {
             case .home:
                 NavigationStack { HomeDashboardView(store: statsStore) }
             case .resorts:
                 NavigationStack { ResortsCommunityView() }
             case .community:
                 NavigationStack { DailySnowView() }
                 }
             }
             .animation(.easeInOut(duration: 0.18), value: tab)
         }
         // 悬浮胶囊 TabBar（仅图标）
         .safeAreaInset(edge: .bottom) {
             if tabBarState.isVisible {
                 FloatingTabBar(selection: $tab, tabs: allTabs) { $0.icon }
                     .padding(.horizontal, 20)
                     .padding(.bottom, 8)
                     .transition(.move(edge: .bottom).combined(with: .opacity))
                     .animation(.easeInOut(duration: 0.2), value: tabBarState.isVisible)
                     .background(
                         GeometryReader { g in
                             Color.clear.preference(key: TabBarHeightKey.self, value: g.size.height)
                         }
                     )
             }
         }
         .onPreferenceChange(TabBarHeightKey.self) { tabBarHeight = $0 }
         .environmentObject(userData)
         .preferredColorScheme(.light)
         .onChange(of: tab) { _, new in visited.insert(new) }

         // ① 欢迎页（仅首次安装）
         .fullScreenCover(isPresented: $showWelcomeGate) {
             WelcomeView {                      // 最后一页按钮回调
                 isFirstLaunch = false
                 showWelcomeGate = false
                 if auth.session == nil {        // 欢迎后若未登录 → 立刻弹登录
                     showLoginGate = true
                     tabBarState.isVisible = false
                 }
             }
             .hidesFloatingTabBar(tabBarState)
             .interactiveDismissDisabled(true)   // 禁止下滑关闭
         }

         // ② 登录入口页（欢迎页之后或无会话时）
         // 这里呈现 WelcomeAuthIntroView，内部按钮会 push 到 LoginView()
         .fullScreenCover(isPresented: $showLoginGate) {
             WelcomeAuthIntroView()
                 .interactiveDismissDisabled(true)                 // 仍然禁止下滑
                 .onDisappear { Task { await AuthManager.shared.bootstrap() } } // 登录成功后收起时刷新会话
                 .hidesFloatingTabBar()                             // 隐藏底部浮动 TabBar（保持与原来一致）
         }


         // 冷启动：拉会话 -> 决定弹哪个
         .task {
             await AuthManager.shared.bootstrap()
             if isFirstLaunch {
                 showWelcomeGate = true
                 tabBarState.isVisible = false
             } else if auth.session == nil {
                 showLoginGate = true
                 tabBarState.isVisible = false
             }
         }

         // 会话变化联动
         .onChange(of: auth.session) { _, session in
             if session == nil {
                 // 非首次时丢会话 → 弹登录
                 if !showWelcomeGate {
                     showLoginGate = true
                     tabBarState.isVisible = false
                 }
             } else {
                 showLoginGate = false
                 tabBarState.isVisible = true
             }
         }

         // 兼容你的登出广播
         .onReceive(NotificationCenter.default.publisher(for: Notification.Name("userDidSignOut"))) { _ in
             if !showWelcomeGate {
                 showLoginGate = true
                 tabBarState.isVisible = false
             }
         }
     }

     // 包装每个 Tab 的可见与点击
     @ViewBuilder
     private func forTab<Content: View>(_ t: MainTab, @ViewBuilder _ content: () -> Content) -> some View {
         content()
             .opacity(t == tab ? 1 : 0)
             .allowsHitTesting(t == tab)
             .onAppear { visited.insert(t) }
     }
 }

 // MARK: - 悬浮胶囊 TabBar
 private struct FloatingTabBar<Tab: Hashable>: View {
     @Binding var selection: Tab
     let tabs: [Tab]
     let icon:  (Tab) -> String

     @Namespace private var anim
     @Environment(\.colorScheme) private var scheme

     private var surface: Color { scheme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.10) : .white }
     private var border:  Color { scheme == .dark ? .white.opacity(0.10) : .black.opacity(0.08) }
     private var shadow:  Color { scheme == .dark ? .clear : .black.opacity(0.12) }

     var body: some View {
         HStack(spacing: 8) {
             ForEach(tabs, id: \.self) { tab in
                 let isSel = (tab == selection)
                 Button {
                     withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                         selection = tab
                         UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                     }
                 } label: {
                     Image(systemName: icon(tab))
                         .font(.system(size: 20, weight: .semibold))
                         .foregroundStyle(isSel ? .primary : .secondary)
                         .padding(.horizontal, 14)
                         .padding(.vertical, 12)
                         .background(
                             ZStack {
                                 if isSel {
                                     RoundedRectangle(cornerRadius: 16, style: .continuous)
                                         .fill((scheme == .dark ? .white.opacity(0.10) : .black.opacity(0.06)))
                                         .matchedGeometryEffect(id: "pill", in: anim)
                                 }
                             }
                         )
                 }
                 .buttonStyle(.plain)
             }
         }
         .padding(.horizontal, 10)
         .padding(.vertical, 10)
         .background(
             RoundedRectangle(cornerRadius: 24, style: .continuous)
                 .fill(surface)
                 .overlay(
                     RoundedRectangle(cornerRadius: 24, style: .continuous)
                         .stroke(border, lineWidth: 1 / UIScreen.main.scale)
                 )
                 .shadow(color: shadow, radius: 18, x: 0, y: 10)
         )
     }
 }

 struct HideFloatingTabBarInjected: ViewModifier {
     let state: FloatingTabBarState?
     func body(content: Content) -> some View {
         content
             .onAppear { withAnimation(.easeInOut(duration: 0.2)) { state?.isVisible = false } }
             .onDisappear { withAnimation(.easeInOut(duration: 0.2)) { state?.isVisible = true } }
     }
 }
 extension View {
     /// 显式传入状态（无则不做操作，也不崩）
     func hidesFloatingTabBar(_ state: FloatingTabBarState?) -> some View {
         modifier(HideFloatingTabBarInjected(state: state))
     }
 }


 // MARK: - TabBar 高度 PreferenceKey
 private struct TabBarHeightKey: PreferenceKey {
     static var defaultValue: CGFloat = 0
     static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
         value = max(value, nextValue())
     }
 }


 import SwiftUI

 struct WelcomeView: View {
     var onFinished: (() -> Void)? = nil       // ← 新增：完成回调
     @State private var currentPageIndex = 0

     var body: some View {
         VStack {
             TabView(selection: $currentPageIndex) {
                 Welcome1View().tag(0)
                 Welcome2View().tag(1)
                 Welcome3View().tag(2)
             }
             .tabViewStyle(.page)

             Button {
                 if currentPageIndex < 2 {
                     currentPageIndex += 1
                 } else {
                     onFinished?()              // 完成欢迎 → 交给 ContentView 决定是否弹登录
                 }
             } label: {
                 Text(currentPageIndex < 2 ? "下一步" : "开始使用")
                     .fontWeight(.semibold)
                     .font(.title3)
                     .frame(maxWidth: .infinity)
                     .padding(.vertical, 10)
             }
             .buttonStyle(.borderedProminent)
             .padding()
         }
         .interactiveDismissDisabled(true)     // 禁止下滑
         .onAppear {
             UIPageControl.appearance().currentPageIndicatorTintColor = .label
             UIPageControl.appearance().pageIndicatorTintColor = .systemGray
         }
         .hidesFloatingTabBar()                // 欢迎期间隐藏悬浮栏
     }
 }

 
 
 */

