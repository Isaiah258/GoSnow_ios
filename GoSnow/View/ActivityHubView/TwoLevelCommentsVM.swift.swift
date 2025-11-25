//
//  TwoLevelCommentsVM.swift.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/28.
//

import Foundation
import Supabase

@MainActor
final class TwoLevelCommentsVM: ObservableObject {
    struct Comment: Identifiable, Equatable {
        let id: UUID
        let postId: UUID
        let createdAt: Date
        var body: String
        let authorId: UUID
        let authorName: String
        let authorAvatarURL: URL?
        let parentCommentId: UUID?   // nil = 根评论
        var likeCount: Int
        var isLikedByMe: Bool
        var replyCount: Int
    }

    enum Sort { case hot, newest }

    // 输入
    let postId: UUID
    init(postId: UUID) { self.postId = postId }

    // 状态
    @Published var sort: Sort = .hot
    @Published var roots: [Comment] = []
    @Published var children: [UUID: [Comment]] = [:]   // rootId -> replies
    @Published var isLoading = false
    @Published var lastError: String?

    // 目标：正在回复谁（用于“回复 @昵称：...”）
    @Published var replyTarget: Comment? = nil

    // 当前登录用户（用于 canDelete）
    @Published var currentUserId: UUID? = nil

    // MARK: - 加载
    func reload() async {
        isLoading = true; defer { isLoading = false }
        lastError = nil
        do {
            let c = DatabaseManager.shared.client

            // ✅ 先拿当前用户 id
            if let u = try? await c.auth.user() {
                self.currentUserId = u.id
            } else {
                self.currentUserId = nil
            }

            struct Row: Decodable {
                let id: UUID
                let post_id: UUID
                let created_at: Date
                let body: String
                let author_id: UUID
                let author_name: String?
                let author_avatar_url: String?
                let parent_comment_id: UUID?
                let like_count: Int?
                let liked_by_me: Bool?
                let reply_count: Int?
            }

            var q = c.from("resorts_post_comments_feed")
                .select()
                .eq("post_id", value: postId)

            switch sort {
            case .hot:
                q = q
                    .order("like_count", ascending: false)
                    .order("created_at", ascending: false) as! PostgrestFilterBuilder
            case .newest:
                q = q
                    .order("created_at", ascending: false) as! PostgrestFilterBuilder
            }

            let rows: [Row] = try await q.execute().value
            let mapped: [Comment] = rows.map { r in
                .init(
                    id: r.id,
                    postId: r.post_id,
                    createdAt: r.created_at,
                    body: r.body,
                    authorId: r.author_id,
                    authorName: r.author_name ?? "雪友",
                    authorAvatarURL: URL(string: r.author_avatar_url ?? ""),
                    parentCommentId: r.parent_comment_id,
                    likeCount: r.like_count ?? 0,
                    isLikedByMe: (r.liked_by_me ?? false),
                    replyCount: r.reply_count ?? 0
                )
            }

            let rts = mapped.filter { $0.parentCommentId == nil }
            let replies = mapped.filter { $0.parentCommentId != nil }
            let grouped = Dictionary(grouping: replies, by: { $0.parentCommentId! })

            self.roots = rts
            self.children = grouped
        } catch {
            lastError = (error as NSError).localizedDescription
        }
    }

    // MARK: - 发送评论 / 回复（两层，显示“回复 昵称：...”）
    func send(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let c = DatabaseManager.shared.client
            guard let u = try? await c.auth.user() else { return }

            var bodyToSend = trimmed
            var parentId: UUID? = nil

            if let target = replyTarget {
                // 两层：任何回复都归到根评论
                let rootId = target.parentCommentId ?? target.id
                parentId = rootId
                bodyToSend = "回复 \(target.authorName)：\(trimmed)"
            }

            struct Insert: Encodable {
                let post_id: UUID
                let user_id: UUID
                let body: String
                let parent_comment_id: UUID?
            }

            let payload = Insert(
                post_id: postId,
                user_id: u.id,
                body: bodyToSend,
                parent_comment_id: parentId
            )

            struct Returned: Decodable { let id: UUID; let created_at: Date }
            let inserted: Returned = try await c
                .from("resorts_post_comments")
                .insert(payload)
                .select("id, created_at")
                .single()
                .execute()
                .value

            // 乐观插入
            let new = Comment(
                id: inserted.id,
                postId: postId,
                createdAt: inserted.created_at,
                body: bodyToSend,
                authorId: u.id,
                authorName: "我",
                authorAvatarURL: nil,
                parentCommentId: parentId,
                likeCount: 0,
                isLikedByMe: false,
                replyCount: 0
            )
            if let pid = parentId {
                var arr = children[pid] ?? []
                arr.insert(new, at: 0)     // 新回复置顶
                children[pid] = arr
                if let i = roots.firstIndex(where: { $0.id == pid }) {
                    roots[i].replyCount += 1
                }
            } else {
                roots.insert(new, at: 0)
            }
            replyTarget = nil
        } catch {
            lastError = (error as NSError).localizedDescription
            print("send reply failed:", lastError ?? "")
        }
    }

    // MARK: - 删除评论
    func delete(comment: Comment) async {
        do {
            let c = DatabaseManager.shared.client
            guard let u = try? await c.auth.user() else {
                lastError = "请先登录"
                return
            }
            // 简单保护一下：只能删自己的
            guard comment.authorId == u.id else {
                lastError = "你只能删除自己的评论"
                return
            }

            // 删表里的记录（假设后端有外键 / 视图会自动跟着变）
            _ = try await c
                .from("resorts_post_comments")
                .delete()
                .eq("id", value: comment.id)
                .execute()

            // 同步本地状态
            if comment.parentCommentId == nil {
                // 根评论：删除自己和它下挂的 children
                roots.removeAll { $0.id == comment.id }
                children[comment.id] = nil
            } else {
                // 子评论：从 children 数组里移除，并把根的 replyCount - 1
                if let pid = comment.parentCommentId {
                    if var arr = children[pid] {
                        arr.removeAll { $0.id == comment.id }
                        children[pid] = arr
                    }
                    if let i = roots.firstIndex(where: { $0.id == pid }) {
                        roots[i].replyCount = max(0, roots[i].replyCount - 1)
                    }
                }
            }
        } catch {
            lastError = (error as NSError).localizedDescription
        }
    }

    // MARK: - 举报评论（写入 resorts_comment_reports）
    func report(comment: Comment, reason: String? = nil) async {
        do {
            let c = DatabaseManager.shared.client
            guard let u = try? await c.auth.user() else {
                lastError = "请先登录后再举报"
                return
            }

            struct InsertReport: Encodable {
                let comment_id: UUID
                let post_id: UUID
                let reporter_user_id: UUID
                let reason: String?
            }

            let payload = InsertReport(
                comment_id: comment.id,
                post_id: comment.postId,
                reporter_user_id: u.id,
                reason: reason
            )

            _ = try await c
                .from("resorts_comment_reports")
                .insert(payload)
                .execute()
            // 成功就不动 UI，只是静默成功或你想的话可以搞个 toast
        } catch {
            lastError = (error as NSError).localizedDescription
        }
    }

    // MARK: - 点赞/取消点赞（评论）
    func toggleLike(for comment: Comment) async {
        let isLike = !comment.isLikedByMe
        mutate(commentId: comment.id) {
            $0.isLikedByMe = isLike
            $0.likeCount += (isLike ? 1 : -1)
        }

        do {
            let c = DatabaseManager.shared.client
            guard let u = try? await c.auth.user() else { return }
            struct Insert: Encodable { let comment_id: UUID; let user_id: UUID }
            if isLike {
                _ = try await c.from("resorts_comment_likes")
                    .insert(Insert(comment_id: comment.id, user_id: u.id))
                    .execute()
            } else {
                _ = try await c.from("resorts_comment_likes")
                    .delete()
                    .eq("comment_id", value: comment.id)
                    .eq("user_id", value: u.id)
                    .execute()
            }
        } catch {
            // 回滚
            mutate(commentId: comment.id) {
                $0.isLikedByMe = !isLike
                $0.likeCount += (isLike ? -1 : 1)
            }
            lastError = (error as NSError).localizedDescription
        }
    }

    // MARK: - 小工具：在 roots 或 children 里 mutate 指定评论
    private func mutate(commentId: UUID, mutate: (inout Comment) -> Void) {
        if let i = roots.firstIndex(where: { $0.id == commentId }) {
            var c = roots[i]; mutate(&c); roots[i] = c; return
        }
        for (k, var arr) in children {
            if let j = arr.firstIndex(where: { $0.id == commentId }) {
                var c = arr[j]; mutate(&c); arr[j] = c; children[k] = arr; return
            }
        }
    }
}

// 用于拿到 insert 返回的 id/时间（现在没用到，可以保留）
private struct CommentIdRow: Decodable {
    let id: UUID
    let created_at: Date
}
