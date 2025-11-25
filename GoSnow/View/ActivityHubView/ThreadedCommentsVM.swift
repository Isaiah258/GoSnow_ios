//
//  ThreadedCommentsVM.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/27.
//
import Foundation
import Supabase

struct CommentItem: Identifiable, Hashable {
    let id: UUID
    let postId: UUID
    let parentId: UUID?
    let createdAt: Date
    let body: String
    let authorId: UUID?
    let authorName: String
    let authorAvatarURL: URL?
    var likeCount: Int
    var childCount: Int
    var canDelete: Bool
}

@MainActor
final class ThreadedCommentsVM: ObservableObject {
    enum Sort: Hashable { case newest, hot }

    // 数据
    @Published var roots: [CommentItem] = []
    @Published var children: [UUID: [CommentItem]] = [:]   // parentId -> replies

    // 点赞状态（仅本地 UI 用）
    @Published var likedByMe: Set<UUID> = []

    // 其它状态
    @Published var isLoading = false
    @Published var error: String?
    @Published var sort: Sort = .newest

    private let postId: UUID
    private var currentUserId: UUID?

    init(postId: UUID) {
        self.postId = postId
    }

    private let iso8601ms: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    // MARK: - 加载
    func loadInitial() async {
        isLoading = true
        defer { isLoading = false }
        do {
            if let u = try? await DatabaseManager.shared.client.auth.user() {
                currentUserId = u.id
            } else {
                currentUserId = nil
            }
            try await fetchAll()
        } catch {
            self.error = (error as NSError).localizedDescription
        }
    }

    func reloadKeepingSort() async {
        await loadInitial()
    }

    func setSort(_ new: Sort) async {
        guard sort != new else { return }
        sort = new
        // 只改排序，不必重新拉取数据库
        regroupAndSort()
    }

    // MARK: - 发表评论 / 回复
    func add(text: String, parentId: UUID?) async {
        guard let u = try? await DatabaseManager.shared.client.auth.user() else {
            self.error = "请先登录"
            return
        }
        do {
            struct InsertRow: Encodable {
                let post_id: UUID
                let user_id: UUID
                let parent_comment_id: UUID?
                let body: String
            }
            _ = try await DatabaseManager.shared.client
                .from("resorts_post_comments")
                .insert(InsertRow(post_id: postId, user_id: u.id, parent_comment_id: parentId, body: text))
                .execute()

            // 重新加载（简单稳妥）
            try await fetchAll()
        } catch {
            self.error = (error as NSError).localizedDescription
        }
    }

    // MARK: - 点赞 / 取消点赞
    func toggleLike(_ c: CommentItem) async {
        guard let u = try? await DatabaseManager.shared.client.auth.user() else {
            self.error = "请先登录"
            return
        }
        let isLiked = likedByMe.contains(c.id)

        // 乐观更新
        likedByMe.toggleMembership(of: c.id)
        if let idx = roots.firstIndex(where: { $0.id == c.id }) {
            roots[idx].likeCount += isLiked ? -1 : 1
        } else if let pid = c.parentId, var arr = children[pid], let i = arr.firstIndex(where: { $0.id == c.id }) {
            arr[i].likeCount += isLiked ? -1 : 1
            children[pid] = arr
        }

        do {
            if isLiked {
                _ = try await DatabaseManager.shared.client
                    .from("resorts_comment_likes")
                    .delete()
                    .eq("comment_id", value: c.id)
                    .eq("user_id", value: u.id)
                    .execute()
            } else {
                struct InsertLike: Encodable { let comment_id: UUID; let user_id: UUID }
                _ = try await DatabaseManager.shared.client
                    .from("resorts_comment_likes")
                    .insert(InsertLike(comment_id: c.id, user_id: u.id))
                    .execute()
            }
        } catch {
            // 回滚
            likedByMe.toggleMembership(of: c.id)
            if let idx = roots.firstIndex(where: { $0.id == c.id }) {
                roots[idx].likeCount += isLiked ? 1 : -1
            } else if let pid = c.parentId, var arr = children[pid], let i = arr.firstIndex(where: { $0.id == c.id }) {
                arr[i].likeCount += isLiked ? 1 : -1
                children[pid] = arr
            }
            self.error = (error as NSError).localizedDescription
        }
    }

    // MARK: - 私有：抓取与整理
    private func fetchAll() async throws {
        struct Row: Decodable {
            let id: UUID
            let post_id: UUID
            let parent_comment_id: UUID?
            let created_at: Date
            let body: String
            let author_id: UUID?
            let author_name: String?
            let author_avatar_url: String?
            let like_count: Int?
            let child_count: Int?
        }

        let c = DatabaseManager.shared.client
        // 一把抓所有（本帖）评论
        let rows: [Row] = try await c
            .from("resorts_post_comments_feed")
            .select()
            .eq("post_id", value: postId)
            .order("created_at", ascending: true)   // 先按时间拿回
            .limit(500)
            .execute()
            .value

        let me = currentUserId
        let mapped: [CommentItem] = rows.map {
            CommentItem(
                id: $0.id,
                postId: $0.post_id,
                parentId: $0.parent_comment_id,
                createdAt: $0.created_at,
                body: $0.body,
                authorId: $0.author_id,
                authorName: $0.author_name ?? "匿名",
                authorAvatarURL: URL(string: $0.author_avatar_url ?? ""),
                likeCount: $0.like_count ?? 0,
                childCount: $0.child_count ?? 0,
                canDelete: ($0.author_id != nil && $0.author_id == me)
            )
        }

        // 组装树
        var roots: [CommentItem] = []
        var children: [UUID: [CommentItem]] = [:]
        for m in mapped {
            if let pid = m.parentId {
                children[pid, default: []].append(m)
            } else {
                roots.append(m)
            }
        }

        // 排序
        self.children = children.mapValues { $0.sorted { $0.createdAt < $1.createdAt } }
        self.roots = roots // 先赋值再按 sort 调整
        regroupAndSort()

        // 拉我点过赞的评论（仅本帖这些 ID）
        let ids = mapped.map { $0.id }
        await loadMyLiked(commentIds: ids)
    }

    private func loadMyLiked(commentIds: [UUID]) async {
        guard let u = try? await DatabaseManager.shared.client.auth.user() else {
            likedByMe = []
            return
        }
        guard !commentIds.isEmpty else { likedByMe = []; return }

        do {
            struct LRow: Decodable { let comment_id: UUID }
            let liked: [LRow] = try await DatabaseManager.shared.client
                .from("resorts_comment_likes")
                .select("comment_id")
                .eq("user_id", value: u.id)
                .in("comment_id", values: commentIds)
                .limit(1000)
                .execute()
                .value
            likedByMe = Set(liked.map { $0.comment_id })
        } catch {
            likedByMe = []
        }
    }

    private func regroupAndSort() {
        switch sort {
        case .newest:
            roots.sort { $0.createdAt < $1.createdAt }
        case .hot:
            roots.sort {
                if $0.likeCount == $1.likeCount {
                    return $0.createdAt < $1.createdAt
                }
                return $0.likeCount > $1.likeCount
            }
        }
    }
}

private extension Set where Element: Hashable {
    mutating func toggleMembership(of e: Element) {
        if contains(e) { remove(e) } else { insert(e) }
    }
}
