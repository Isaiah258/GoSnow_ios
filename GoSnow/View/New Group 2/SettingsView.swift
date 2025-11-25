//
//  SettingsView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/31.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showWelcome = false

    var body: some View {
        Form {
            Button("再次查看欢迎页") { showWelcome = true }
            Toggle("重置已看状态", isOn: Binding(
                get: { !hasSeenOnboarding },
                set: { hasSeenOnboarding = !$0 }
            ))
        }
        .fullScreenCover(isPresented: $showWelcome) {
            WelcomeFlowView()
        }
    }
}
