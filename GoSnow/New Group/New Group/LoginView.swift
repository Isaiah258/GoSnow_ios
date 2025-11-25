//
//  LoginView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/9/3.
//

import SwiftUI
import Supabase

// ===== 审核直通参数（硬编码） =====
private let REVIEW_PHONE     = "12345678910"
private let REVIEW_OTP       = "123456"

// 测试账号（请在 Supabase 里预先创建；可按需改成你的）
private let REVIEW_EMAIL     = "testuser@gmail.com"
private let REVIEW_PASSWORD  = "123456"
// =================================

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var phoneNumber: String = ""
    @State private var otp: String = ""
    @State private var isOTPSent = false
    @State private var isSending = false
    @State private var isVerifying = false
    @State private var errorMessage: String?

    // 倒计时
    @State private var resendSeconds = 0
    @State private var resendTimer: Timer? = nil

    init() {}
    @available(*, deprecated, message: "Use LoginView() without bindings. Auth state comes from AuthManager.shared.")
    init(isLoggedIn: Binding<Bool>, userName: Binding<String?>, userAvatar: Binding<Image?>) {}

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    // 全局黑底
                    Color.black.ignoresSafeArea()

                    // 仅上圆角的大卡片，充满视图
                    Group {
                        if #available(iOS 17.0, *) {
                            UnevenRoundedRectangle(
                                topLeadingRadius: 24,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 24,
                                style: .continuous
                            )
                            .fill(Color.black)
                            .ignoresSafeArea(edges: .bottom)
                        } else {
                            Color.black
                                .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
                                .ignoresSafeArea(edges: .bottom)
                        }
                    }
                    .overlay(
                        // 表单内容
                        ScrollView {
                            VStack(alignment: .leading, spacing: 18) {
                                // 标题
                                Text("手机号登录")
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                                    .padding(.top, 6)

                                Text("新用户点击登录将自动创建账号")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))

                                // 手机号
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("手机号")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.7))

                                    TextField("输入 11 位手机号", text: $phoneNumber)
                                        .keyboardType(.phonePad)
                                        .textContentType(.telephoneNumber)
                                        .onChange(of: phoneNumber) { _, new in
                                            let cleaned = cleanedPhone(from: new)
                                            if phoneNumber != cleaned { phoneNumber = cleaned }
                                            isOTPSent = false
                                            stopResendCountdown()
                                            otp = ""
                                        }
                                        .modifier(DarkFieldStyle())
                                }

                                // 验证码 + 发送
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("验证码")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.7))

                                    HStack(spacing: 10) {
                                        TextField("输入 6 位验证码", text: $otp)
                                            .keyboardType(.numberPad)
                                            .textContentType(.oneTimeCode)
                                            .onChange(of: otp) { _, new in
                                                otp = String(new.filter(\.isNumber).prefix(6))
                                            }
                                            .modifier(DarkFieldStyle())

                                        Button {
                                            Task { await sendOTP() }
                                        } label: {
                                            if isSending {
                                                ProgressView().tint(.white)
                                                    .frame(minWidth: 86, minHeight: 44)
                                            } else {
                                                Text(resendSeconds > 0
                                                     ? "重发(\(resendSeconds)s)"
                                                     : (isOTPSent ? "重新发送" : "发送验证码"))
                                                .font(.subheadline.weight(.semibold))
                                                .frame(minWidth: 86, minHeight: 44)
                                            }
                                        }
                                        .disabled(!canSendOTP || isSending || resendSeconds > 0)
                                        .buttonStyle(.plain)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(.white.opacity((!canSendOTP || resendSeconds > 0) ? 0.08 : 0.16))
                                        )
                                        .foregroundStyle(.white.opacity((!canSendOTP || resendSeconds > 0) ? 0.6 : 1))
                                    }
                                }

                                // 登录按钮
                                Button {
                                    Task { await verifyAndSignIn() }
                                } label: {
                                    HStack {
                                        if isVerifying {
                                            ProgressView().tint(.black)
                                        } else {
                                            Text("登录").font(.headline)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(.white) // 白底黑字
                                    )
                                    .foregroundStyle(.black)
                                }
                                .disabled(!canVerify)
                                .opacity(canVerify ? 1 : 0.7)

                                // 错误提示
                                if let err = errorMessage, !err.isEmpty {
                                    Text(err)
                                        .foregroundStyle(.red)
                                        .font(.footnote)
                                        .padding(.top, 4)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }

                                // 协议
                                HStack(spacing: 6) {
                                    Text("登录即表示同意")
                                        .font(.footnote)
                                        .foregroundStyle(.white.opacity(0.5))

                                    NavigationLink {
                                        TermsView()
                                    } label: {
                                        Text("《服务条款与隐私》")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundStyle(.white)
                                            .underline()
                                    }
                                }
                                .padding(.top, 6)

                                Spacer(minLength: max(12, geo.safeAreaInsets.bottom))
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 12)
                        }
                    )
                }
            }
            .navigationTitle("")
            .scrollDisabled(true)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { BackButton() } }
        }
        .onDisappear { stopResendCountdown() }
    }

    // MARK: - Computed
    private var canSendOTP: Bool { phoneNumber.count == 11 }
    private var canVerify: Bool { canSendOTP && otp.count == 6 && !isVerifying }

    // MARK: - Countdown
    private func startResendCountdown(_ seconds: Int = 60) {
        resendTimer?.invalidate()
        resendSeconds = seconds
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if resendSeconds > 0 { resendSeconds -= 1 }
            else {
                resendTimer?.invalidate()
                resendTimer = nil
            }
        }
        if let t = resendTimer { RunLoop.main.add(t, forMode: .common) }
    }
    private func stopResendCountdown() {
        resendTimer?.invalidate()
        resendTimer = nil
        resendSeconds = 0
    }

    // MARK: - Actions
    private func cleanedPhone(from raw: String) -> String {
        String(raw.filter(\.isNumber).prefix(11))
    }

    private func sendOTP() async {
        guard canSendOTP else { return }
        errorMessage = nil
        isSending = true
        defer { isSending = false }

        // 命中审核手机号：不实际发短信，直接进入“已发送”态
        if phoneNumber == REVIEW_PHONE {
            await MainActor.run {
                isOTPSent = true
                startResendCountdown()
            }
            return
        }

        // 正常流程
        do {
            try await DatabaseManager.shared.client.auth.signInWithOTP(phone: "+86" + phoneNumber)
            await MainActor.run {
                isOTPSent = true
                startResendCountdown()
            }
        } catch {
            let ns = error as NSError
            let msg = (ns.code == 429) ? "发送过于频繁，请稍后再试" : ns.localizedDescription
            await MainActor.run {
                errorMessage = msg
                isOTPSent = false
                stopResendCountdown()
            }
        }
    }

    private func verifyAndSignIn() async {
        guard canVerify else { return }
        errorMessage = nil
        isVerifying = true
        defer { isVerifying = false }

        // 命中审核手机号 + 固定验证码：直接用测试账号登录（邮箱/密码）
        if phoneNumber == REVIEW_PHONE && otp == REVIEW_OTP {
            do {
                _ = try await DatabaseManager.shared.client.auth.signIn(
                    email: REVIEW_EMAIL,
                    password: REVIEW_PASSWORD
                )
                await AuthManager.shared.bootstrap()
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
            return
        }

        // 正常流程：校验短信验证码
        do {
            _ = try await DatabaseManager.shared.client.auth.verifyOTP(
                phone: "+86" + phoneNumber, token: otp, type: .sms
            )
            await AuthManager.shared.bootstrap()
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }
}

// MARK: - 小组件：深色输入框样式 & 返回按钮
private struct DarkFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.08))
            )
            .foregroundStyle(.white)
    }
}

private struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .padding(8)
                .background(.white.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LoginView()
        .preferredColorScheme(.dark)
}











/*
 11.2
 import SwiftUI
 import Supabase

 struct LoginView: View {
     @Environment(\.dismiss) private var dismiss

     @State private var phoneNumber: String = ""
     @State private var otp: String = ""
     @State private var isOTPSent = false
     @State private var isSending = false
     @State private var isVerifying = false
     @State private var errorMessage: String?

     // 倒计时
     @State private var resendSeconds = 0
     @State private var resendTimer: Timer? = nil

     

     init() {}
     @available(*, deprecated, message: "Use LoginView() without bindings. Auth state comes from AuthManager.shared.")
     init(isLoggedIn: Binding<Bool>, userName: Binding<String?>, userAvatar: Binding<Image?>) {}

     var body: some View {
         NavigationStack {
             GeometryReader { geo in
                 ZStack(alignment: .top) {
                     // 全局黑底
                     Color.black.ignoresSafeArea()

                     // 仅上圆角的大卡片，充满视图（与入口页风格一致、无白色描边）
                     Group {
                         if #available(iOS 17.0, *) {
                             UnevenRoundedRectangle(
                                 topLeadingRadius: 24,
                                 bottomLeadingRadius: 0,
                                 bottomTrailingRadius: 0,
                                 topTrailingRadius: 24,
                                 style: .continuous
                             )
                             .fill(Color.black)
                             .ignoresSafeArea(edges: .bottom)
                         } else {
                             Color.black
                                 .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
                                 .ignoresSafeArea(edges: .bottom)
                         }
                     }
                     .overlay(
                         // 表单内容
                         ScrollView {
                             VStack(alignment: .leading, spacing: 18) {
                                 // 标题
                                 Text("手机号登录")
                                     .font(.title3.bold())
                                     .foregroundStyle(.white)
                                     .padding(.top, 6)

                                 Text("新用户点击登录将自动创建账号")
                                     .font(.subheadline)
                                     .foregroundStyle(.white.opacity(0.7))

                                 // 手机号
                                 VStack(alignment: .leading, spacing: 8) {
                                     Text("手机号")
                                         .font(.footnote.weight(.semibold))
                                         .foregroundStyle(.white.opacity(0.7))

                                     TextField("输入 11 位手机号", text: $phoneNumber)
                                         .keyboardType(.phonePad)
                                         .textContentType(.telephoneNumber)
                                         .onChange(of: phoneNumber) { _, new in
                                             let cleaned = cleanedPhone(from: new)
                                             if phoneNumber != cleaned { phoneNumber = cleaned }
                                             isOTPSent = false
                                             stopResendCountdown()
                                             otp = ""
                                         }
                                         .modifier(DarkFieldStyle())
                                 }

                                 // 验证码 + 发送
                                 VStack(alignment: .leading, spacing: 8) {
                                     Text("验证码")
                                         .font(.footnote.weight(.semibold))
                                         .foregroundStyle(.white.opacity(0.7))

                                     HStack(spacing: 10) {
                                         TextField("输入 6 位验证码", text: $otp)
                                             .keyboardType(.numberPad)
                                             .textContentType(.oneTimeCode)
                                             .onChange(of: otp) { _, new in
                                                 otp = String(new.filter(\.isNumber).prefix(6))
                                             }
                                             .modifier(DarkFieldStyle())

                                         Button {
                                             Task { await sendOTP() }
                                         } label: {
                                             if isSending {
                                                 ProgressView().tint(.white)
                                                     .frame(minWidth: 86, minHeight: 44)
                                             } else {
                                                 Text(resendSeconds > 0
                                                      ? "重发(\(resendSeconds)s)"
                                                      : (isOTPSent ? "重新发送" : "发送验证码"))
                                                 .font(.subheadline.weight(.semibold))
                                                 .frame(minWidth: 86, minHeight: 44)
                                             }
                                         }
                                         .disabled(!canSendOTP || isSending || resendSeconds > 0)
                                         .buttonStyle(.plain)
                                         .background(
                                             RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                 .fill(.white.opacity((!canSendOTP || resendSeconds > 0) ? 0.08 : 0.16))
                                         )
                                         .foregroundStyle(.white.opacity((!canSendOTP || resendSeconds > 0) ? 0.6 : 1))
                                     }
                                 }

                                 // 登录按钮
                                 Button {
                                     Task { await verifyAndSignIn() }
                                 } label: {
                                     HStack {
                                         if isVerifying {
                                             ProgressView().tint(.black)
                                         } else {
                                             Text("登录").font(.headline)
                                         }
                                     }
                                     .frame(maxWidth: .infinity)
                                     .padding(.vertical, 16)
                                     .background(
                                         RoundedRectangle(cornerRadius: 16, style: .continuous)
                                             .fill(.white) // 反相主按钮：白底黑字
                                     )
                                     .foregroundStyle(.black)
                                 }
                                 .disabled(!canVerify)
                                 .opacity(canVerify ? 1 : 0.7)

                                 // 错误提示
                                 if let err = errorMessage, !err.isEmpty {
                                     Text(err)
                                         .foregroundStyle(.red)
                                         .font(.footnote)
                                         .padding(.top, 4)
                                         .transition(.opacity.combined(with: .move(edge: .top)))
                                 }

                                 // 在“协议”那行替换为：
                                 HStack(spacing: 6) {
                                     Text("登录即表示同意")
                                         .font(.footnote)
                                         .foregroundStyle(.white.opacity(0.5))

                                     NavigationLink {
                                         TermsView()                    // ← 你的条款/隐私页面（上雪版）
                                     } label: {
                                         Text("《服务条款与隐私》")
                                             .font(.footnote.weight(.semibold))
                                             .foregroundStyle(.white)   // 更明显
                                             .underline()
                                     }
                                 }
                                 .padding(.top, 6)


                                 Spacer(minLength: max(12, geo.safeAreaInsets.bottom))
                             }
                             .padding(.horizontal, 20)
                             .padding(.top, 20)
                             .padding(.bottom, 12)
                         }
                     )
                 }
             }
             .navigationTitle("") // 跟随卡片样式，隐藏标题
             .scrollDisabled(true)
             .navigationBarTitleDisplayMode(.inline)
             .navigationBarBackButtonHidden(true)
             .toolbar { ToolbarItem(placement: .navigationBarLeading) { BackButton() } }
         }
         .onDisappear { stopResendCountdown() }
     }

     // MARK: - Computed
     private var canSendOTP: Bool { phoneNumber.count == 11 }
     private var canVerify: Bool { canSendOTP && otp.count == 6 && !isVerifying }

     // MARK: - Countdown
     private func startResendCountdown(_ seconds: Int = 60) {
         resendTimer?.invalidate()
         resendSeconds = seconds
         resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
             if resendSeconds > 0 { resendSeconds -= 1 }
             else {
                 resendTimer?.invalidate()
                 resendTimer = nil
             }
         }
         if let t = resendTimer { RunLoop.main.add(t, forMode: .common) }
     }
     private func stopResendCountdown() {
         resendTimer?.invalidate()
         resendTimer = nil
         resendSeconds = 0
     }

     // MARK: - Actions
     private func cleanedPhone(from raw: String) -> String {
         String(raw.filter(\.isNumber).prefix(11))
     }

     private func sendOTP() async {
         guard canSendOTP else { return }
         errorMessage = nil

         
         isSending = true
         defer { isSending = false }

         do {
             try await DatabaseManager.shared.client.auth.signInWithOTP(phone: "+86" + phoneNumber)
             await MainActor.run {
                 isOTPSent = true
                 startResendCountdown()
             }
         } catch {
             let ns = error as NSError
             let msg = (ns.code == 429) ? "发送过于频繁，请稍后再试" : ns.localizedDescription
             await MainActor.run {
                 errorMessage = msg
                 isOTPSent = false
                 stopResendCountdown()
             }
         }
     }

     private func verifyAndSignIn() async {
         guard canVerify else { return }
         errorMessage = nil
         isVerifying = true
         defer { isVerifying = false }

         do {
             // 正常校验 OTP
             _ = try await DatabaseManager.shared.client.auth.verifyOTP(
                 phone: "+86" + phoneNumber, token: otp, type: .sms
             )
             await AuthManager.shared.bootstrap()
             await MainActor.run { dismiss() }
         } catch {
             await MainActor.run { errorMessage = error.localizedDescription }
         }
     }
 }

 // MARK: - 小组件：深色输入框样式 & 返回按钮
 private struct DarkFieldStyle: ViewModifier {
     func body(content: Content) -> some View {
         content
             .textInputAutocapitalization(.never)
             .autocorrectionDisabled(true)
             .padding(.horizontal, 14)
             .padding(.vertical, 12)
             .background(
                 RoundedRectangle(cornerRadius: 12, style: .continuous)
                     .fill(.white.opacity(0.08)) // 与入口页一致：无描边
             )
             .foregroundStyle(.white)
     }
 }

 private struct BackButton: View {
     @Environment(\.dismiss) private var dismiss
     var body: some View {
         Button {
             dismiss()
         } label: {
             Image(systemName: "chevron.left")
                 .font(.system(size: 17, weight: .semibold))
                 .foregroundStyle(.white)
                 .padding(8)
                 .background(.white.opacity(0.08), in: Circle())
         }
         .buttonStyle(.plain)
     }
 }

 // 预览
 #Preview {
     LoginView()
         .preferredColorScheme(.dark)
 }


 
 
 */





/*
 import SwiftUI
 import PhotosUI

 struct ProfileView: View {
     @State private var selectedFilter: ProfileFilterModel = .setting
     @Namespace var animation
     @State private var isLoggedIn: Bool = false  // 模拟用户登录状态
     @State private var showLoginView = false     // 控制是否显示登录页面
     @State private var userName: String? = nil   // 用户名（未登录为nil）
     @State private var userAvatar: Image? = nil  // 用户头像（未登录为nil）

     var body: some View {
         NavigationStack {
             ScrollView {
                 VStack {
                     ProfileHeader()

                     FilterBar

                     switch selectedFilter {
                     case .setting:
                         SettingView(isLoggedIn: $isLoggedIn)
                     case .sportData:
                         SportDataView()
                     }
                 }
             }
             .sheet(isPresented: $showLoginView) {
                 LoginView(isLoggedIn: $isLoggedIn, userName: $userName, userAvatar: $userAvatar)
             }
         }
         .onAppear {
             loadUserData() // 加载用户数据
         }
     }
     
     @ViewBuilder
     func ProfileHeader() -> some View {
         VStack {
             if isLoggedIn {
                 // 已登录状态，显示用户自定义头像和名称
                 (userAvatar ?? Image(systemName: "person.crop.circle"))
                     .resizable()
                     .frame(width: 80, height: 80)
                     .clipShape(Circle())
                 
                 Text(userName ?? "用户名")
                     .font(.headline)
                 
                 NavigationLink(destination: EditProfile()) {
                     Text("编辑资料")
                         .padding(.horizontal)
                         .overlay(
                             RoundedRectangle(cornerRadius: 25)
                                 .stroke(Color.black, lineWidth: 1)
                         )
                 }
                     
             } else {
                 // 未登录状态，显示默认头像和提示文本
                 Image(systemName: "person.crop.circle.fill")
                     .resizable()
                     .frame(width: 80, height: 80)
                     .clipShape(Circle())
                     .foregroundColor(.gray) // 默认头像颜色
                 
                 Text("点击注册/登录")
                     .font(.headline)
                     .foregroundColor(.blue)
                     .onTapGesture {
                         showLoginView = true
                     }
             }
         }
         .padding()
     }

     
     var FilterBar: some View {
         HStack {
             ForEach(ProfileFilterModel.allCases, id: \.rawValue) { item in
                 VStack {
                     Text(item.title)
                         .font(.subheadline)
                         .fontWeight(selectedFilter == item ? .semibold : .regular)
                         .foregroundStyle(selectedFilter == item ? Color.black : Color.gray)
                     
                     if selectedFilter == item {
                         Capsule()
                             .foregroundStyle(Color(.systemBlue))
                             .frame(height: 3)
                             .matchedGeometryEffect(id: "filter", in: animation)
                     } else {
                         Capsule()
                             .foregroundStyle(Color(.clear))
                             .frame(height: 3)
                     }
                 }
                 .onTapGesture {
                     withAnimation(.easeInOut) {
                         self.selectedFilter = item
                     }
                 }
             }
         }
         .overlay(Divider().offset(x: 0, y: 16))
     }
     
     // 加载用户数据
     private func loadUserData() {
         if let savedUserName = UserDefaults.standard.string(forKey: "userName"),
            let savedUserAvatarData = UserDefaults.standard.data(forKey: "userAvatar"),
            let savedAccessToken = UserDefaults.standard.string(forKey: "accessToken"),
            let savedRefreshToken = UserDefaults.standard.string(forKey: "refreshToken"),
            let savedSessionExpiry = UserDefaults.standard.string(forKey: "sessionExpiresAt"),
            let expiresAt = ISO8601DateFormatter().date(from: savedSessionExpiry) {

             // 检查 session 是否有效
             if expiresAt > Date() {
                 // 恢复会话
                 DatabaseManager.shared.client.auth.setSession(accessToken: savedAccessToken, refreshToken: savedRefreshToken)
                 
                 // 获取当前用户信息
                 if let user = DatabaseManager.shared.getCurrentUser() {
                     // 更新用户信息
                     userName = savedUserName
                     if let uiImage = UIImage(data: savedUserAvatarData) {
                         userAvatar = Image(uiImage: uiImage)
                     }
                     isLoggedIn = true
                 }
             }
         }
     }
 }

 #Preview {
     ProfileView()
 }

 */

/*
 import SwiftUI
 import Supabase

 struct LoginView: View {
     @Binding var isLoggedIn: Bool
     @Binding var userName: String?  // 用户名
     @Binding var userAvatar: Image? // 头像

     @State private var phoneNumber: String = ""
     @State private var otp: String = ""
     @State private var isOTPSent = false
     @State private var errorMessage: String?
     
     @Environment(\.dismiss) var dismiss
     
     @State private var phoneErrorMessage: String?
     
     // 修改为你的测试账号手机号和固定验证码
     private let testPhoneNumber = "19153643718"  // 测试账号手机号
     private let testOTP = "123456"  // 固定验证码

     var body: some View {
         NavigationStack {
             Form {
                 Section(header: Text("新用户点击登录默认注册账号")) {
                     TextField("输入手机号", text: $phoneNumber)
                         .keyboardType(.phonePad)
                         .onChange(of: phoneNumber) {
                             validatePhoneNumber(phoneNumber)
                         }
                         .foregroundColor(phoneErrorMessage == nil ? .primary : .red)

                     if let phoneErrorMessage = phoneErrorMessage {
                         Text(phoneErrorMessage)
                             .foregroundColor(.red)
                             .font(.caption)
                     }

                     HStack {
                         TextField("输入验证码", text: $otp)
                             .keyboardType(.numberPad)

                         Button(isOTPSent ? "重新发送" : "发送验证码") {
                             sendOTP(to: phoneNumber)
                         }
                         .disabled(phoneNumber.count != 11 || isOTPSent)
                     }
                 }

                 Section {
                     Button("登录") {
                         verifyOTP(phoneNumber: phoneNumber, otp: otp)
                     }
                     .disabled(otp.isEmpty || phoneNumber.count != 11)
                 }

                 if let errorMessage = errorMessage {
                     Section {
                         Text(errorMessage)
                             .foregroundColor(.red)
                     }
                 }
             }
             .navigationBarTitle("登录", displayMode: .inline)
         }
     }

     // 验证手机号长度
     func validatePhoneNumber(_ phoneNumber: String) {
         if phoneNumber.count < 11 {
             phoneErrorMessage = "请输入11位手机号"
         } else if phoneNumber.count > 11 {
             phoneErrorMessage = "请输入11位手机号"
         } else {
             phoneErrorMessage = nil
         }
     }

     // 发送OTP验证码（模拟发送）
     func sendOTP(to phoneNumber: String) {
         // 对于测试账号，直接标记 OTP 已发送
         if phoneNumber == testPhoneNumber {
             isOTPSent = true
         } else {
             // 否则使用 Supabase 的 OTP 发送机制
             Task {
                 do {
                     try await DatabaseManager.shared.client.auth.signInWithOTP(phone: phoneNumber)
                     DispatchQueue.main.async {
                         isOTPSent = true
                     }
                 } catch {
                     DispatchQueue.main.async {
                         errorMessage = error.localizedDescription
                     }
                 }
             }
         }
     }

     // 验证OTP验证码并登录
     func verifyOTP(phoneNumber: String, otp: String) {
         Task {
             do {
                 // 如果是测试账号，直接用固定验证码跳过验证
                 if phoneNumber == testPhoneNumber && otp == testOTP {
                     // 模拟登录成功
                     isLoggedIn = true
                     userName = "Test User"
                     userAvatar = Image(systemName: "person.crop.circle.fill")
                     dismiss()
                 } else {
                     // 对于其他用户，正常验证 OTP
                     let authResponse = try await DatabaseManager.shared.client.auth.verifyOTP(
                         phone: phoneNumber,
                         token: otp,
                         type: .sms
                     )
                     
                     if let session = authResponse.session {
                         // 保存会话信息
                         saveUserSession(session: session)
                         
                         if let user = DatabaseManager.shared.getCurrentUser() {
                             // 更新登录状态
                             isLoggedIn = true
                             userAvatar = Image(systemName: "person.crop.circle.fill") // 默认头像
                             userName = phoneNumber // 可以改为从数据库加载
                             
                             dismiss() // 关闭登录界面
                         }
                     } else {
                         errorMessage = "登录失败，未返回会话信息"
                     }
                 }
             } catch {
                 DispatchQueue.main.async {
                     errorMessage = error.localizedDescription
                 }
             }
         }
     }

     // 保存用户的 session 信息
     func saveUserSession(session: Session) {
         UserDefaults.standard.set(session.accessToken, forKey: "accessToken")
         UserDefaults.standard.set(session.refreshToken, forKey: "refreshToken")
         UserDefaults.standard.set(session.expiresAt.description, forKey: "sessionExpiresAt")
     }
 }

 #Preview {
     LoginView(isLoggedIn: .constant(false), userName: .constant(nil), userAvatar: .constant(nil))
 }
 */


/*
 9.26
 
 import SwiftUI
 import Supabase

 struct LoginView: View {
     // 新版不再依赖外部绑定，登录态统一由 AuthManager 管
     @Environment(\.dismiss) private var dismiss

     @State private var phoneNumber: String = ""
     @State private var otp: String = ""
     @State private var isOTPSent = false
     @State private var isSending = false
     @State private var isVerifying = false
     @State private var errorMessage: String?

     // 你的测试直通号（可按需修改/删除）
     private let testPhoneNumber = "19153643718"
     private let testOTP = "123456"

     // ✅ 新的无参 init（推荐使用）
     init() {}

     // ✅ 兼容旧代码的 init（不再使用这些绑定，但保留以免编译/调用出错）
     @available(*, deprecated, message: "Use LoginView() without bindings. Auth state comes from AuthManager.shared.")
     init(isLoggedIn: Binding<Bool>, userName: Binding<String?>, userAvatar: Binding<Image?>) {
         // 故意留空：状态由 AuthManager 维护
     }

     var body: some View {
         NavigationStack {
             Form {
                 Section(header: Text("新用户点击登录默认注册账号")) {
                     TextField("输入手机号", text: $phoneNumber)
                         .keyboardType(.phonePad)
                         .textContentType(.telephoneNumber)
                         .onChange(of: phoneNumber) { _, new in
                             phoneNumber = cleanedPhone(from: new)
                         }

                     HStack {
                         TextField("输入验证码", text: $otp)
                             .keyboardType(.numberPad)
                             .textContentType(.oneTimeCode)
                             .onChange(of: otp) { _, new in
                                 otp = String(new.filter(\.isNumber).prefix(6))
                             }

                         Button(isOTPSent ? "重新发送" : "发送验证码") {
                             Task { await sendOTP() }
                         }
                         .disabled(!canSendOTP || isSending)
                     }
                 }

                 Section {
                     Button {
                         Task { await verifyAndSignIn() }
                     } label: {
                         if isVerifying {
                             ProgressView()
                         } else {
                             Text("登录")
                         }
                     }
                     .disabled(!canVerify)
                 }

                 if let err = errorMessage {
                     Section {
                         Text(err).foregroundColor(.red)
                     }
                 }
             }
             .navigationTitle("登录")
         }
     }

     // MARK: - Computed

     private var canSendOTP: Bool {
         phoneNumber.count == 11
     }

     private var canVerify: Bool {
         canSendOTP && (otp.count >= 4) && !isVerifying
     }

     // MARK: - Actions

     private func cleanedPhone(from raw: String) -> String {
         String(raw.filter(\.isNumber).prefix(11))
     }

     private func sendOTP() async {
         guard canSendOTP else { return }
         errorMessage = nil

         // 测试直通号：直接认为已发送
         if phoneNumber == testPhoneNumber {
             await MainActor.run {
                 isOTPSent = true
             }
             return
         }

         isSending = true
         defer { isSending = false }

         do {
             try await DatabaseManager.shared.client.auth.signInWithOTP(phone: "+86" + phoneNumber)
             await MainActor.run {
                 isOTPSent = true
             }
         } catch {
             await MainActor.run {
                 errorMessage = error.localizedDescription
                 isOTPSent = false
             }
         }
     }

     private func verifyAndSignIn() async {
         guard canVerify else { return }
         errorMessage = nil
         isVerifying = true
         defer { isVerifying = false }

         do {
             // 测试直通号：跳过服务端校验，直接刷新全局会话并关闭
             if phoneNumber == testPhoneNumber && otp == testOTP {
                 await AuthManager.shared.bootstrap()
                 await MainActor.run { dismiss() }
                 return
             }

             // 正常校验 OTP
             _ = try await DatabaseManager.shared.client.auth.verifyOTP(
                 phone: "+86" + phoneNumber,
                 token: otp,
                 type: .sms
             )

             // 成功后：Supabase SDK 已把 session 写入 Keychain
             // 我们拉取/创建用户资料，驱动全局 UI 刷新
             await AuthManager.shared.bootstrap()
             await MainActor.run { dismiss() }

         } catch {
             await MainActor.run {
                 errorMessage = error.localizedDescription
             }
         }
     }
 }


 #Preview {
     LoginView()
 }
 
 */

/*
 
 10.16
 
 import SwiftUI
 import Supabase

 struct LoginView: View {
     // 新版不再依赖外部绑定，登录态统一由 AuthManager 管
     @Environment(\.dismiss) private var dismiss

     @State private var phoneNumber: String = ""
     @State private var otp: String = ""
     @State private var isOTPSent = false
     @State private var isSending = false
     @State private var isVerifying = false
     @State private var errorMessage: String?

     // ✅ 新增：倒计时状态
     @State private var resendSeconds = 0                 // 0 表示可发送
     @State private var resendTimer: Timer? = nil         // 定时器

     // 你的测试直通号（可按需修改/删除）
     private let testPhoneNumber = "19153643718"
     private let testOTP = "123456"

     // ✅ 新的无参 init（推荐使用）
     init() {}

     // ✅ 兼容旧代码的 init（不再使用这些绑定，但保留以免编译/调用出错）
     @available(*, deprecated, message: "Use LoginView() without bindings. Auth state comes from AuthManager.shared.")
     init(isLoggedIn: Binding<Bool>, userName: Binding<String?>, userAvatar: Binding<Image?>) {}

     var body: some View {
         NavigationStack {
             Form {
                 Section(header: Text("新用户点击登录默认注册账号")) {
                     TextField("输入手机号", text: $phoneNumber)
                         .keyboardType(.phonePad)
                         .textContentType(.telephoneNumber)
                         .onChange(of: phoneNumber) { _, new in
                             // 清洗为 11 位数字
                             let cleaned = cleanedPhone(from: new)
                             if phoneNumber != cleaned { phoneNumber = cleaned }
                             // 手机号变化 → 清理已发送状态与倒计时，避免发给错误号码
                             isOTPSent = false
                             stopResendCountdown()
                             otp = ""
                         }

                     HStack {
                         TextField("输入验证码", text: $otp)
                             .keyboardType(.numberPad)
                             .textContentType(.oneTimeCode)
                             .onChange(of: otp) { _, new in
                                 otp = String(new.filter(\.isNumber).prefix(6))
                             }

                         Button(resendSeconds > 0
                                ? "重新发送 (\(resendSeconds)s)"
                                : (isOTPSent ? "重新发送" : "发送验证码")) {
                             Task { await sendOTP() }
                         }
                         .disabled(!canSendOTP || isSending || resendSeconds > 0)
                     }
                 }

                 Section {
                     Button {
                         Task { await verifyAndSignIn() }
                     } label: {
                         if isVerifying {
                             ProgressView()
                         } else {
                             Text("登录")
                         }
                     }
                     .disabled(!canVerify)
                 }

                 if let err = errorMessage {
                     Section {
                         Text(err).foregroundColor(.red)
                     }
                 }
             }
             .navigationTitle("登录")
         }
         .onDisappear { stopResendCountdown() } // 视图退出时停止定时器，防止泄漏
     }

     // MARK: - Computed

     private var canSendOTP: Bool {
         phoneNumber.count == 11
     }

     private var canVerify: Bool {
         canSendOTP && otp.count == 6 && !isVerifying
     }

     // MARK: - Countdown

     private func startResendCountdown(_ seconds: Int = 60) {
         resendTimer?.invalidate()
         resendSeconds = seconds
         resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
             if resendSeconds > 0 {
                 resendSeconds -= 1
             } else {
                 resendTimer?.invalidate()
                 resendTimer = nil
             }
         }
         if let t = resendTimer {
             RunLoop.main.add(t, forMode: .common)
         }
     }

     private func stopResendCountdown() {
         resendTimer?.invalidate()
         resendTimer = nil
         resendSeconds = 0
     }

     // MARK: - Actions

     private func cleanedPhone(from raw: String) -> String {
         String(raw.filter(\.isNumber).prefix(11))
     }

     private func sendOTP() async {
         guard canSendOTP else { return }
         errorMessage = nil

         // 测试直通号：也走冷却，避免被无限点击
         if phoneNumber == testPhoneNumber {
             await MainActor.run {
                 isOTPSent = true
                 startResendCountdown()   // ✅ 开冷却
             }
             return
         }

         isSending = true
         defer { isSending = false }

         do {
             try await DatabaseManager.shared.client.auth.signInWithOTP(phone: "+86" + phoneNumber)
             await MainActor.run {
                 isOTPSent = true
                 startResendCountdown()   // ✅ 开冷却
             }
         } catch {
             // 可根据错误码定制提示（429：发送频繁 等）
             let ns = error as NSError
             let msg = (ns.code == 429) ? "发送过于频繁，请稍后再试" : ns.localizedDescription
             await MainActor.run {
                 errorMessage = msg
                 isOTPSent = false
                 stopResendCountdown()    // 失败就别卡住按钮
             }
         }
     }

     private func verifyAndSignIn() async {
         guard canVerify else { return }
         errorMessage = nil
         isVerifying = true
         defer { isVerifying = false }

         do {
             // 测试直通号：跳过服务端校验，直接刷新全局会话并关闭
            // if phoneNumber == testPhoneNumber && otp == testOTP {
             //    await AuthManager.shared.bootstrap()
             //    await MainActor.run { dismiss() }
             //    return
           //  }

             // 正常校验 OTP
             _ = try await DatabaseManager.shared.client.auth.verifyOTP(
                 phone: "+86" + phoneNumber,
                 token: otp,
                 type: .sms
             )

             // 成功后：Supabase/Memfire SDK 已把 session 写入 Keychain
             // 我们拉取/创建用户资料，驱动全局 UI 刷新
             await AuthManager.shared.bootstrap()
             await MainActor.run { dismiss() }

         } catch {
             await MainActor.run {
                 errorMessage = error.localizedDescription
             }
         }
     }
 }

 // 预览
 #Preview {
     LoginView()
 }
 */
