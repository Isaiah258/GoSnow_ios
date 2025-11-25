//
//  NotificationViewModel.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/6.
//

import Foundation
import Supabase

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [PostNotifications] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasUnreadNotifications: Bool = false

    func loadNotifications() async {
        guard let currentUser = DatabaseManager.shared.getCurrentUser() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // 🍰 ① 一次性把触发者(from_user)、评论/帖子简要内容都联上来
            // 如果你的外键不是唯一关系，建议写成 Users!PostNotification_from_user_id_fkey(...)
            let list: [PostNotifications] = try await DatabaseManager.shared.client
                .from("PostNotifications")
                .select("""
                    id, user_id, from_user_id, post_id, comment_id, type, created_at, is_read,
                    from_user:Users(id, user_name, avatar_url),
                    comment:PostComments(id, content),
                    post:Post(id, content)
                """)
                .eq("user_id", value: currentUser.id)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            // 🍰 ② 把联表的 from_user 合并到 UI 字段上（actor_*）
            self.notifications = list.map { n in
                var m = n
                m.actor_name = n.from_user?.user_name
                m.actor_avatar_url = n.from_user?.avatar_url
                return m
            }

        } catch {
            errorMessage = "加载通知失败"
            print("❌ 加载通知失败：\(error)")
        }
    }

    func markAllNotificationsAsRead() async {
        guard let currentUser = DatabaseManager.shared.getCurrentUser() else { return }
        do {
            _ = try await DatabaseManager.shared.client
                .from("PostNotifications")
                .update(["is_read": true])
                .eq("user_id", value: currentUser.id)
                .eq("is_read", value: false)
                .execute()
            hasUnreadNotifications = false
        } catch {
            print("❌ 标记通知为已读失败：\(error)")
        }
    }

    func checkUnreadNotifications() async {
        guard let currentUser = DatabaseManager.shared.getCurrentUser() else { return }
        do {
            let res = try await DatabaseManager.shared.client
                .from("PostNotifications")
                .select("id", count: .exact)
                .eq("user_id", value: currentUser.id)
                .eq("is_read", value: false)
                .limit(1)
                .execute()
            hasUnreadNotifications = (res.count ?? 0) > 0
        } catch {
            print("❌ 检查未读失败：\(error)")
        }
    }
}

