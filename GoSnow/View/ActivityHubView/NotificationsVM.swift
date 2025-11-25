//
//  NotificationsVM.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/26.
//

import Foundation
import SwiftUI
import Supabase

struct NotificationItem: Identifiable, Hashable {
    let id: Int64
    let createdAt: Date
    let type: String
    let postId: UUID?
    let commentId: UUID?
    let actorId: UUID?
    let actorName: String
    let actorAvatarURL: URL?
    var readAt: Date?
}

@MainActor
final class NotificationsVM: ObservableObject {
    @Published var items: [NotificationItem] = []
    @Published var isLoading = false
    @Published var error: String?

    private var currentUserId: UUID?
    
    private let allowedTypes: Set<String> = [
      "like_post", "like_comment", "comment_post", "reply_comment"
    ]

    func load() async {
            guard !isLoading else { return }
            isLoading = true
            defer { isLoading = false }

            do {
                let c = DatabaseManager.shared.client
                _ = try? await c.auth.user()  // 触发 RLS 的身份；无需手动 eq 过滤

                struct Row: Decodable {
                    let id: Int64                // ← UUID ❌ 改成 Int64 ✅
                    let created_at: Date
                    let type: String
                    let post_id: UUID?
                    let comment_id: UUID?
                    let actor_user_id: UUID?
                    let actor_name: String?
                    let actor_avatar_url: String?
                    let read_at: Date?
                }

                // 明确列名，避免将来视图加列引起不必要的解码失败
                let rows: [Row] = try await c
                    .from("resorts_notifications_feed")
                    .select("id,created_at,type,post_id,comment_id,actor_user_id,actor_name,actor_avatar_url,read_at")
                    .order("created_at", ascending: false)
                    .limit(80)
                    .execute()
                    .value

                items = rows.map { r in
                    NotificationItem(
                        id: r.id,
                        createdAt: r.created_at,
                        type: r.type,
                        postId: r.post_id,
                        commentId: r.comment_id,
                        actorId: r.actor_user_id,
                        actorName: r.actor_name ?? "雪友",
                        actorAvatarURL: URL(string: r.actor_avatar_url ?? ""),
                        readAt: r.read_at
                    )
                }.filter { allowedTypes.contains($0.type) }   // 只保留 4 类

            } catch {
                self.error = (error as NSError).localizedDescription
            }
        
        
        }
    func markAllRead() async {
            let c = DatabaseManager.shared.client
            do {
                _ = try await c.rpc("resorts_notifications_mark_all_read").execute()
                // 本地状态同步
                items = items.map { var m = $0; if m.readAt == nil { m.readAt = Date() }; return m }
            } catch {
                self.error = (error as NSError).localizedDescription
            }
        }

    var unreadCount: Int { items.filter { $0.readAt == nil }.count }
}

/// 导航使用：铃铛按钮
struct NotificationsBellButton: View {
    @ObservedObject var vm: NotificationsVM
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .semibold))
                if vm.unreadCount > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 6, y: -6)
                }
            }
        }
        .accessibilityLabel(vm.unreadCount > 0 ? "有新通知" : "通知")
    }
}

/// 通知中心列表
struct NotificationsCenterView: View {
    @StateObject private var vm = NotificationsVM()
    var onTapPost: (UUID) -> Void

    var body: some View {
        List(vm.items) { n in
            HStack(spacing: 12) {
                AsyncImage(url: n.actorAvatarURL) { phase in
                    switch phase {
                    case .success(let img): img.resizable()
                    default: Circle().fill(Color(.tertiarySystemFill))
                    }
                }
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(notifText(n))
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text(RelativeDateTimeFormatter().localizedString(for: n.createdAt, relativeTo: Date()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if n.readAt == nil {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                Task {
                    // 先标记已读（安全地更新列表状态）
                    await vm.markRead(id: n.id)

                    // 再导航（确保存在帖子 id）
                    if let pid = n.postId {
                        onTapPost(pid)
                    } else {
                        vm.error = "这条通知没有关联帖子或帖子已被删除。"
                    }
                }
            }


            

        }
        .listStyle(.plain)
        .navigationTitle("通知")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("全部已读") { Task { await vm.markAllRead() } }
            }
        }
        .task { await vm.load() }
        .alert("出错了", isPresented: Binding(
            get: { vm.error != nil },
            set: { _ in vm.error = nil }
        )) { Button("好的", role: .cancel) {} } message: { Text(vm.error ?? "") }
        
    }
    

    private func notifText(_ n: NotificationItem) -> String {
        switch n.type {
        case "like_post":     return "\(n.actorName) 赞了你的帖子"
        case "like_comment":  return "\(n.actorName) 赞了你的评论"
        case "comment_post":  return "\(n.actorName) 评论了你的帖子"
        case "reply_comment": return "\(n.actorName) 回复了你的评论"
        default:              return "" // 理论到不了这里
        }
    }
    

}



extension NotificationsVM {
    struct PostIdRow: Decodable { let post_id: UUID }

    /// 有些通知只有 commentId，没有 postId；这里兜底解析
    func resolvePostIdIfNeeded(for n: NotificationItem) async -> UUID? {
        if let pid = n.postId { return pid }
        guard let cid = n.commentId else { return nil }
        do {
            let rows: [PostIdRow] = try await DatabaseManager.shared.client
                .from("resorts_post_comments")
                .select("post_id")
                .eq("id", value: cid)
                .limit(1)
                .execute().value
            return rows.first?.post_id
        } catch {
            self.error = (error as NSError).localizedDescription
            return nil
        }
    }

   
}

extension NotificationsVM {
    func markRead(id: Int64) async {
        do {
            let now = Date()
            _ = try await DatabaseManager.shared.client
                .from("resorts_notifications")
                .update(["read_at": now])
                .eq("id", value: Int(id))   // ✅ 转成 Int（或用 String(id) 也行）
                .execute()

            if let i = items.firstIndex(where: { $0.id == id }) {
                items[i].readAt = now
            }
        } catch {
            self.error = (error as NSError).localizedDescription
        }
    }
}

