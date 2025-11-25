//
//  AuthManager.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/12.
//

import Foundation
import Supabase

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var session: Session?
    @Published private(set) var userProfile: Users?

    private var authChangesTask: Task<Void, Never>?
    private var client: SupabaseClient { DatabaseManager.shared.client }

    /// App 启动时调用：恢复会话 + 监听变更
    func bootstrap() async {
        // 1) 从 SDK 恢复已有会话（Supabase 会把会话放在 Keychain）
        do {
            self.session = try await client.auth.session
        } catch {
            print("Auth restore failed: \(error)")
        }

        // 2) 监听会话变化（登录/登出/刷新），2.5.1 用 async sequence
        if authChangesTask == nil {
            authChangesTask = Task { [weak self] in
                guard let self else { return }
                for await (_, session) in self.client.auth.authStateChanges {
                    // 事件包括：.signedIn / .signedOut / .userUpdated / .passwordRecovery / .tokenRefreshed 等
                    await MainActor.run {
                        self.session = session
                    }
                    await self.refreshProfileIfNeeded()
                    // 调试：
                    // print("Auth event:", event)
                }
            }
        }

        // 3) 恢复后拉一次资料
        await refreshProfileIfNeeded()
    }

    private func refreshProfileIfNeeded() async {
        guard let userId = session?.user.id else {
            userProfile = nil
            return
        }
        do {
            let rows: [Users] = try await client
                .from("Users")
                .select()
                //.eq("id", value: userId.uuidString)
                .eq("id", value: userId)              // 传 UUID
                .limit(1)
                .execute()
                .value

            if let first = rows.first {
                userProfile = first
            } else {
                // ✅ 不存在则创建默认资料（昵称用手机号尾号占位）
                let nick = "雪友" + (session?.user.phone?.suffix(4) ?? "用户")
                let placeholder = Users(id: userId, user_name: String(nick), avatar_url: "default_avatar")
                _ = try await client.from("Users").insert(placeholder).execute()

                userProfile = placeholder
            }
        } catch {
            print("load/create profile failed:", error)
        }
    }


    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            print("signOut failed:", error)
        }
        session = nil
        userProfile = nil
    }
}

