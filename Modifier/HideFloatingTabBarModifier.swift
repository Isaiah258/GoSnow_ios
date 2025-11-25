//
//  HideFloatingTabBarModifier.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/9/27.
//

// View+FloatingTabBar.swift
import SwiftUI

struct HideFloatingTabBarModifier: ViewModifier {
    @EnvironmentObject private var tabBarState: FloatingTabBarState

    func body(content: Content) -> some View {
        content
            .onAppear {
                withAnimation(.easeInOut(duration: 0.2)) { tabBarState.isVisible = false }
            }
            .onDisappear {
                withAnimation(.easeInOut(duration: 0.2)) { tabBarState.isVisible = true }
            }
    }
}

extension View {
    /// 在当前页面生命周期内隐藏自定义悬浮 TabBar
    func hidesFloatingTabBar() -> some View {
        modifier(HideFloatingTabBarModifier())
    }
}
