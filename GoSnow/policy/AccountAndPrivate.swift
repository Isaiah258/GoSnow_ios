//
//  AccountAndPrivate.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/27.
//

import SwiftUI
import Supabase

struct AccountAndPrivate: View {
    private let settingsURLString: String = UIApplication.openSettingsURLString
    @State private var showAlert = false
    @Binding var isLoggedIn: Bool // 通过绑定传递登录状态
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                // 账户部分
                Section(header: Text("账户")) {
                    HStack {
                        Button(action: openSettings) {
                            Text("权限管理")
                                .foregroundColor(.black)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    
                    // 注销账户部分
                    HStack {
                        Text("注销账户")
                            .alert(isPresented: $showAlert) {
                                Alert(
                                    title: Text("确认注销"),
                                    message: Text("您确定要注销您的账户吗？"),
                                    primaryButton: .destructive(Text("注销")) {
                                        // 执行注销逻辑
                                        deleteAccount()
                                    },
                                    secondaryButton: .cancel(Text("取消")) {
                                        print("注销操作已取消")
                                    }
                                )
                            }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .onTapGesture {
                        self.showAlert = true
                    }
                }
                
                // 隐私部分
                
            }
            .navigationTitle("账户与隐私")
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }

    // 打开系统设置
    private func openSettings() {
        if let url = URL(string: settingsURLString) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }

    // 注销账户的逻辑
    private func deleteAccount() {
        Task {
            do {
                // 获取当前用户
                guard let user = DatabaseManager.shared.getCurrentUser() else {
                    errorMessage = "未找到当前用户"
                    return
                }

                // 从 Supabase 认证中删除用户
                try await DatabaseManager.shared.client.auth.admin.deleteUser(id: user.id.uuidString)

                // 从 Users 表中删除用户的 profile
                try await DatabaseManager.shared.client
                    .from("Users")
                    .delete()
                    .eq("id", value: user.id.uuidString)
                    .execute()

                // 注销成功后处理后续操作，比如设置 `isLoggedIn = false`
                DispatchQueue.main.async {
                    isLoggedIn = false
                    UserDefaults.standard.removeObject(forKey: "accessToken") // 移除本地存储的登录信息
                    UserDefaults.standard.removeObject(forKey: "refreshToken")
                    print("账户已成功注销")
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "注销账户失败: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    AccountAndPrivate(isLoggedIn: .constant(true))
}

