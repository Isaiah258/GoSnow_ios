//
//  AboutUsHubView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/9/23.
//


import SwiftUI

struct AboutUsHubView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // 文档分组
                    SettingsGroupCardModern(title: "文档") {
                        NavigationLink {
                            // 你已有的社区准则页面
                            CommunityGuidelinesView()
                        } label: {
                            SettingsRowModern(icon: "hand.raised.fill", tint: .pink, title: "社区准则")
                        }

                        Divider().padding(.leading, 56)

                        NavigationLink {
                            // 你已有的隐私政策页面
                            TermsView()
                        } label: {
                            SettingsRowModern(icon: "lock.shield.fill", tint: .green, title: "隐私政策")
                        }
                    }
                    .padding(.horizontal, 20)

                    
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle("关于我们")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { AboutUsHubView().preferredColorScheme(.light) }
}

