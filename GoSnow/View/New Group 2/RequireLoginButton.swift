//
//  RequireLoginButton.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/9/24.
//

import SwiftUI

struct RequireLoginButton<Label: View>: View {
    @ObservedObject private var auth = AuthManager.shared
    @State private var showLogin = false

    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button {
            if auth.session != nil {
                action()
            } else {
                showLogin = true
            }
        } label: { label() }
        .sheet(isPresented: $showLogin) { LoginView() }
    }
}

