//
//  FeedVm.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/19.
//

import Foundation
import Supabase
import SwiftUI

@MainActor
final class FeedVM: ObservableObject {
    @Published var items: [ResortPost] = []
    @Published var isLoadingInitial = false
    @Published var initialError: String? = nil
    @Published var isPaginating = false
    @Published var reachedEnd = false
    @Published var lastErrorMessage: String? = nil

    private var nextCursor: Date? = nil
    private var currentResortId: Int? = nil
    private var currentUserId: UUID? = nil

    // 仅本 VM 使用：ISO8601 毫秒
    private let iso8601ms: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    // MARK: Lifecycle

    func loadInitialIfNeeded() async {
        guard items.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        initialError = nil
        reachedEnd = false
        nextCursor = nil
        isLoadingInitial = true
        defer { isLoadingInitial = false }

        do {
            if let u = try? await DatabaseManager.shared.client.auth.user() {
                currentUserId = u.id
            } else {
                currentUserId = nil
            }

            let fresh = try await fetchPage(before: nil, limit: 20)
            items = fresh
            nextCursor = fresh.last?.createdAt
            reachedEnd = fresh.isEmpty
        } catch {
            initialError = (error as NSError).localizedDescription
        }
    }

    func loadMoreIfNeeded() async {
        guard !isPaginating, !reachedEnd else { return }
        isPaginating = true
        defer { isPaginating = false }

        do {
            let more = try await fetchPage(before: nextCursor, limit: 20)
            if more.isEmpty { reachedEnd = true }
            items.append(contentsOf: more)
            nextCursor = more.last?.createdAt
        } catch {
            lastErrorMessage = (error as NSError).localizedDescription
        }
    }

    func setResortFilter(_ resortId: Int?) async {
        currentResortId = resortId
        await refresh()
    }

    // MARK: Actions

    func delete(_ post: ResortPost) async {
        guard let idx = items.firstIndex(where: { $0.id == post.id }) else { return }
        let backup = items[idx]
        items.remove(at: idx)
        do {
            try await DatabaseManager.shared.client
                .from("resorts_post")
                .delete()
                .eq("id", value: post.id)
                .execute()
        } catch {
            items.insert(backup, at: idx)
            lastErrorMessage = (error as NSError).localizedDescription
        }
    }

    func report(_ post: ResortPost) async {
        do {
            struct InsertRow: Encodable { let post_id: UUID }
            try await DatabaseManager.shared.client
                .from("resorts_post_reports")
                .insert(InsertRow(post_id: post.id))
                .execute()
            lastErrorMessage = "已收到你的举报，我们会尽快处理。"
        } catch {
            let msg = (error as NSError).localizedDescription
            if msg.localizedCaseInsensitiveContains("duplicate") {
                lastErrorMessage = "你已举报过这条内容，我们会尽快处理。"
            } else {
                lastErrorMessage = msg
            }
        }
    }

    /// 点赞/取消点赞（带乐观更新）
    func toggleLike(postId: UUID, to liked: Bool) async {
        guard let index = items.firstIndex(where: { $0.id == postId }) else { return }
        var draft = items[index]
        // 乐观
        draft.likedByMe = liked
        draft.likeCount += liked ? 1 : -1
        items[index] = draft

        let c = DatabaseManager.shared.client
        do {
            guard let u = try? await c.auth.user() else { throw NSError(domain: "auth", code: -1) }
            if liked {
                struct InsertLike: Encodable { let post_id: UUID; let author_id: UUID }
                _ = try await c.from("resorts_post_likes")
                    .insert(InsertLike(post_id: postId, author_id: u.id))
                    .execute()
            } else {
                _ = try await c.from("resorts_post_likes")
                    .delete()
                    .eq("post_id", value: postId)
                    .eq("author_id", value: u.id)
                    .execute()
            }
        } catch {
            // 回滚
            var rollback = items[index]
            rollback.likedByMe = !liked
            rollback.likeCount += liked ? -1 : 1
            items[index] = rollback
            lastErrorMessage = (error as NSError).localizedDescription
        }
    }

    /// 发表评论（带乐观计数）
    func addComment(postId: UUID, body: String) async {
        guard let index = items.firstIndex(where: { $0.id == postId }) else { return }
        var draft = items[index]
        draft.commentCount += 1
        items[index] = draft

        let c = DatabaseManager.shared.client
        do {
            guard let u = try? await c.auth.user() else { throw NSError(domain: "auth", code: -1) }
            struct InsertComment: Encodable { let post_id: UUID; let user_id: UUID; let body: String } // ✅
            _ = try await c.from("resorts_post_comments")
                .insert(InsertComment(post_id: postId, user_id: u.id, body: body)) // ✅
                .execute()

        } catch {
            // 回滚
            var rollback = items[index]
            rollback.commentCount -= 1
            items[index] = rollback
            lastErrorMessage = (error as NSError).localizedDescription
        }
    }

    // MARK: Fetch

    private func fetchPage(before: Date?, limit: Int) async throws -> [ResortPost] {
        struct Row: Decodable {
            let id: UUID
            let created_at: Date
            let title: String?
            let body: String?
            let rating: Int?
            let resort_id: Int?
            let resort_name: String?
            // 同时兼容两种列名
            let user_id: UUID?
            let author_id: UUID?
            let author_name: String?
            let author_avatar_url: String?
            let media_urls: [String]?
            let like_count: Int?
            let comment_count: Int?
            let liked_by_me: Bool?
        }

        let c = DatabaseManager.shared.client
        var q = c.from("resorts_post_feed").select()
        if let rid = currentResortId { q = q.eq("resort_id", value: rid) }
        if let ts = before {
            let iso = iso8601ms.string(from: ts)
            q = q.lt("created_at", value: iso)
        }

        let rows: [Row] = try await q
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        // ⬇️ 只替换你原来的这一段 map
        let posts: [ResortPost] = rows.compactMap { r in
            // 兼容：优先 user_id，缺了就用 author_id
            let ownerId = r.user_id ?? r.author_id
            guard let ownerId else { return nil }   // 没作者就丢弃，避免崩溃

            let canDelete = (ownerId == currentUserId)

            return ResortPost(
                id: r.id,
                author: .init(
                    name: r.author_name ?? "匿名",
                    avatarURL: URL(string: r.author_avatar_url ?? "")
                ),
                resort: .init(id: r.resort_id ?? 0, name: r.resort_name ?? "未知雪场"),
                title: r.title,
                text: r.body,
                images: (r.media_urls ?? []).compactMap { URL(string: $0) },
                createdAt: r.created_at,
                rating: r.rating ?? 0,
                userId: ownerId,
                likeCount: r.like_count ?? 0,
                commentCount: r.comment_count ?? 0,
                likedByMe: r.liked_by_me ?? false,
                authorId: ownerId,
                canDelete: canDelete
            )
        }
        return posts
    }

}





/*
 
 
 import SwiftUI
 import Supabase

 @MainActor
 final class FeedVM: ObservableObject {
     @Published var items: [ResortPost] = []
     @Published var isLoadingInitial = false
     @Published var initialError: String? = nil
     @Published var isPaginating = false
     @Published var reachedEnd = false
     @Published var lastErrorMessage: String? = nil

     private var nextCursor: Date? = nil
     private var currentResortId: Int? = nil
     private var currentUserId: UUID? = nil

     func loadInitialIfNeeded() async {
         guard items.isEmpty else { return }
         await refresh()
     }

     func refresh() async {
         initialError = nil
         reachedEnd = false
         nextCursor = nil
         isLoadingInitial = true
         defer { isLoadingInitial = false }
         do {
             // 记录当前用户 id，用于 canDelete 判定
             if let u = try? await DatabaseManager.shared.client.auth.user() {
                 currentUserId = u.id
             } else {
                 currentUserId = nil
             }

             let fresh = try await fetchPage(before: nil, limit: 20)
             items = fresh
             nextCursor = fresh.last?.createdAt
             reachedEnd = fresh.isEmpty
         } catch {
             initialError = (error as NSError).localizedDescription
         }
     }

     func loadMoreIfNeeded() async {
         guard !isPaginating, !reachedEnd else { return }
         isPaginating = true
         defer { isPaginating = false }
         do {
             let more = try await fetchPage(before: nextCursor, limit: 20)
             if more.isEmpty { reachedEnd = true }
             items.append(contentsOf: more)
             nextCursor = more.last?.createdAt
         } catch {
             lastErrorMessage = (error as NSError).localizedDescription
         }
     }

     // 切换/清空雪场过滤
     func setResortFilter(_ resortId: Int?) async {
         currentResortId = resortId
         await refresh()
     }

     // 删除帖子（仅在 UI 判断 canDelete == true 时提供按钮）
     func delete(_ post: ResortPost) async {
         guard let idx = items.firstIndex(where: { $0.id == post.id }) else { return }
         let backup = items[idx]
         items.remove(at: idx)
         do {
             try await DatabaseManager.shared.client
                 .from("resorts_post")
                 .delete()
                 .eq("id", value: post.id)
                 .execute()
         } catch {
             items.insert(backup, at: idx)
             lastErrorMessage = (error as NSError).localizedDescription
         }
     }

     // 举报
     func report(_ post: ResortPost) async {
         do {
             struct InsertRow: Encodable { let post_id: UUID }
             try await DatabaseManager.shared.client
                 .from("resorts_post_reports")
                 .insert(InsertRow(post_id: post.id))
                 .execute()
             lastErrorMessage = "已收到你的举报，我们会尽快处理。"
         } catch {
             let msg = (error as NSError).localizedDescription
             if msg.localizedCaseInsensitiveContains("duplicate") {
                 lastErrorMessage = "你已举报过这条内容，我们会尽快处理。"
             } else {
                 lastErrorMessage = msg
             }
         }
     }

     // === 数据抓取 ===

     private let iso8601ms: ISO8601DateFormatter = {
         let f = ISO8601DateFormatter()
         f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
         f.timeZone = TimeZone(secondsFromGMT: 0)
         return f
     }()

     private func fetchPage(before: Date?, limit: Int) async throws -> [ResortPost] {
         struct Row: Decodable {
             let id: UUID
             let created_at: Date
             let title: String?
             let body: String?
             let rating: Int?
             let resort_id: Int?
             let resort_name: String?
             let author_id: UUID?
             let author_name: String?
             let author_avatar_url: String?
             let media_urls: [String]?
         }

         let c = DatabaseManager.shared.client
         var q = c.from("resorts_post_feed").select() // 视图需包含 author_id

         if let rid = currentResortId {
             q = q.eq("resort_id", value: rid)
         }
         if let ts = before {
             let iso = iso8601ms.string(from: ts)
             q = q.lt("created_at", value: iso)
         }

         let rows: [Row] = try await q
             .order("created_at", ascending: false)
             .limit(limit)
             .execute()
             .value

         return rows.map { r in
             let canDelete = (r.author_id != nil && r.author_id == currentUserId)
             return ResortPost(
                 id: r.id,
                 author: .init(
                     name: r.author_name ?? "匿名",
                     avatarURL: URL(string: r.author_avatar_url ?? "")
                 ),
                 resort: .init(id: r.resort_id ?? 0, name: r.resort_name ?? "未知雪场"),
                 title: r.title,
                 text: r.body,
                 images: (r.media_urls ?? []).compactMap { URL(string: $0) },
                 createdAt: r.created_at,
                 rating: r.rating ?? 0,
                 canDelete: canDelete
             )
         }
     }
 }

 // 你已有的模型
 struct ResortPost: Identifiable, Hashable {
     let id: UUID
         var author: Author
         var resort: ResortRef
         var title: String?
         var text: String?
         var images: [URL]
         var createdAt: Date
         var likeCount: Int
         var commentCount: Int
         var likedByMe: Bool
         var canDelete: Bool = false
         var comments: [Comment]

     var timeText: String {
         let f = RelativeDateTimeFormatter()
         f.unitsStyle = .short
         return f.localizedString(for: createdAt, relativeTo: Date())
     }
     var mediaURLs: [URL] { images }
 }

 struct Author: Hashable {
     var name: String
     var avatarURL: URL?
 }

 struct Comment: Identifiable {
     let id: UUID
     let author: Author
     let text: String
     let createdAt: Date
 }

 struct Like: Identifiable {
     let id: UUID
     let userId: UUID
     let postId: UUID
     let createdAt: Date
 }

 
 
 */

