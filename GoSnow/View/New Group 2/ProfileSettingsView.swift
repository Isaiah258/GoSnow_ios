//
//  ProfileSettingsView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/9/22.
//

import SwiftUI
import UIKit

private enum Branding {
    static let wechatOfficialName = "雪兔滑行"
    static let wechatQRCodeAsset: String? = nil
}

struct ProfileSettingsView: View {
    @ObservedObject private var auth = AuthManager.shared

    @State private var showLoginSheet = false
    @State private var showSignoutConfirm = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // 头像 + 登录状态卡（只展示，不编辑）
                    RoundedContainer {
                        HStack(spacing: 14) {
                            // 头像
                            AvatarBubble(urlString: auth.userProfile?.avatar_url)
                                .frame(width: 56, height: 56)

                            // 昵称 + 状态
                            VStack(alignment: .leading, spacing: 6) {
                                Text(auth.userProfile?.user_name ?? "未设置昵称")
                                    .font(.title3.weight(.bold))
                                    .lineLimit(1)

                                HStack(spacing: 6) {
                                    Image(systemName: "person.text.rectangle")
                                        .font(.footnote.weight(.bold))
                                        .foregroundStyle(.secondary)
                                    Text(auth.session != nil ? "已登录" : "未登录")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()

                            if auth.session == nil {
                                Button {
                                    showLoginSheet = true
                                } label: {
                                    Text("登录 / 注册")
                                        .font(.subheadline.weight(.bold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(Color.black))
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.plain)
                            } else {
                                NavigationLink {
                                    EditProfile()
                                } label: {
                                    Text("编辑资料")
                                        .font(.subheadline.weight(.bold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(Color.black))
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // 分组：通用
                    SettingsGroupCardModern(title: "通用") {
                        NavigationLink {
                            AccountAndPrivate(isLoggedIn: .constant(auth.session != nil))
                        } label: {
                            SettingsRowModern(icon: "slider.vertical.3", tint: .blue, title: "账户与隐私")
                        }

                        Divider().padding(.leading, 56)
/*
                        NavigationLink {
                            QualificationApplyView()
                        } label: {
                            SettingsRowModern(icon: "figure.skiing.downhill", tint: .purple, title: "远程教练申请")
                        }

                        Divider().padding(.leading, 56)
*/
                        NavigationLink {
                            Feedback()
                        } label: {
                            SettingsRowModern(icon: "envelope.fill", tint: .indigo, title: "用户反馈")
                        }

                        Divider().padding(.leading, 56)

                        NavigationLink {
                            AboutUsHubView()
                        } label: {
                            SettingsRowModern(icon: "info.circle.fill", tint: .orange, title: "关于我们")
                        }

                        if auth.session != nil {
                            Divider().padding(.leading, 56)
                            Button(role: .destructive) {
                                showSignoutConfirm = true
                            } label: {
                                SettingsRowModern(
                                    icon: "rectangle.portrait.and.arrow.right",
                                    tint: .red,
                                    title: "退出登录",
                                    showChevron: false,
                                    titleColor: .red
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 24)
                }
            }
        }
        .navigationTitle("账户与设置")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLoginSheet) {
            LoginView()
                .onDisappear {
                    Task { await AuthManager.shared.bootstrap() }
                }
        }
        .task { await AuthManager.shared.bootstrap() }
        .confirmationDialog("确认退出登录", isPresented: $showSignoutConfirm, titleVisibility: .visible) {
            Button("退出登录", role: .destructive) { signOut() }
            Button("取消", role: .cancel) { }
        }
        .alert("错误", isPresented: $showError) {
            Button("好的", role: .cancel) { }
        } message: { Text(errorMessage ?? "未知错误") }
    }

    private func signOut() {
        Task {
            do {
                try await DatabaseManager.shared.client.auth.signOut()
                await AuthManager.shared.bootstrap()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// 小头像气泡（支持远程 URL/占位）
struct AvatarBubble: View {
    let urlString: String?
    var body: some View {
        Group {
            if let s = urlString, s.hasPrefix("http"), let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Circle().fill(Color.gray.opacity(0.15))
                            Image(systemName: "person.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            } else {
                ZStack {
                    Circle().fill(Color(.tertiarySystemFill))
                    Image(systemName: "person.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.primary)
                }
            }
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(.primary.opacity(0.1), lineWidth: 1))
    }
}




// ========== 你已有的 UI 组件（保持与首页同款风格） ==========

struct SettingsGroupCardModern<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            RoundedContainer {
                VStack(spacing: 0) { content }
                    .padding(.vertical, 2)
            }
        }
    }
}

struct SettingsRowModern: View {
    let icon: String
    let tint: Color
    let title: String
    var showChevron: Bool = true
    var titleColor: Color = .primary
    var body: some View {
        HStack(spacing: 12) {
            IconBadge(system: icon, tint: tint)
                .frame(width: 36, height: 36)
            Text(title)
                .foregroundStyle(titleColor)
                .font(.body)
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}


// MARK: - 资质申请（引导去公众号，仅“远程教练”）
struct QualificationApplyView: View {
    @State private var showCopied = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 官方公众号信息
                RoundedContainer {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            IconBadge(system: "bubble.left.and.bubble.right.fill", tint: .green)
                            Text("官方公众号").font(.headline)
                            Spacer()
                        }

                        HStack {
                            Text(Branding.wechatOfficialName)
                                .font(.title3.weight(.semibold))
                            Spacer()
                            Button {
                                UIPasteboard.general.string = Branding.wechatOfficialName
                                withAnimation { showCopied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    withAnimation { showCopied = false }
                                }
                            } label: {
                                Label("复制名称", systemImage: "doc.on.doc")
                                    .font(.footnote.weight(.bold))
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        if let asset = Branding.wechatQRCodeAsset,
                           let img = UIImage(named: asset) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary.opacity(0.15), lineWidth: 1))
                                .padding(.top, 6)
                            Text("长按识别二维码或搜索公众号名")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // 远程教练申请说明 + CTA
                RoundedContainer {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            IconBadge(system: "figure.skiing.downhill", tint: .purple)
                            Text("远程教练申请").font(.headline)
                            Spacer()
                        }

                        Text("目前资质申请仅支持“远程教练”。请前往微信公众号，通过菜单或回复关键字完成申请。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            StepRow(index: 1, text: "关注公众号：\(Branding.wechatOfficialName)")
                            StepRow(index: 2, text: "在对话框发送：远程教练申请")
                        }
                        .padding(.vertical, 4)

                        Button {
                            UIPasteboard.general.string = "远程教练申请"
                            withAnimation { showCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation { showCopied = false }
                            }
                        } label: {
                            Text("复制关键词“远程教练申请”")
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(Color.black))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(16)
                }
                .padding(.horizontal, 20)

                if showCopied {
                    Text("已复制到剪贴板")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                        .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1 / UIScreen.main.scale))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer(minLength: 24)
            }
        }
        .navigationTitle("资质申请")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 小步骤行（与首页风格一致）
struct StepRow: View {
    let index: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(index).")
                .font(.callout.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 22, alignment: .trailing)

            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// 预览
#Preview {
    NavigationStack { ProfileSettingsView().preferredColorScheme(.light) }
}





