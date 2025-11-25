//
//  PostCommentViewModel.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/7/28.
//

import Foundation
import Supabase

@MainActor
class PostCommentViewModel: ObservableObject {
    // 展示用：父评列表 + 子评字典
    @Published var comments: [PostCommentItem] = []
    @Published var childComments: [Int: [PostCommentItem]] = [:]

    // 回复状态 & 输入框
    @Published var replyingToComment: PostCommentItem? = nil
    @Published var inputText: String = ""

    // 加载 & 分页 & 错误
    @Published var isLoading: Bool = false
    @Published var showError: String? = nil
    @Published var currentPage: Int = 0
    @Published var hasMorePages: Bool = true
    private var isLoadingMore: Bool = false
    let pageSize: Int = 20

    // 点赞状态
    @Published var likedCommentIds: Set<Int> = []
    @Published var commentLikeCounts: [Int: Int] = [:]

    // 关联信息
    let postId: Int
    private let postOwnerId: UUID

    init(postId: Int, postOwnerId: UUID) {
        self.postId = postId
        self.postOwnerId = postOwnerId
    }

    // MARK: - 加载（先父评分页、再批量拉子评）
    func loadInitialComments() async {
        currentPage = 0
        hasMorePages = true
        comments = []
        childComments = [:]
        await loadMoreComments()
    }

    func loadMoreComments() async {
        guard hasMorePages, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let pageOffset = currentPage * pageSize
            let client = DatabaseManager.shared.client

            // 父评论（parent_comment_id IS NULL）+ 联表用户
            let roots: [PostCommentItem] = try await client
                .from("PostComments")
                .select("""
                        id, post_id, user_id, content, created_at, parent_comment_id,
                        user:Users(id, user_name, avatar_url)
                        """)
                .eq("post_id", value: postId)
                .is("parent_comment_id", value: nil)
                .order("created_at", ascending: true)
                .range(from: pageOffset, to: pageOffset + pageSize - 1)
                .execute()
                .value

            comments += roots
            currentPage += 1
            hasMorePages = (roots.count == pageSize)

            // 批量拉这些父评的子评（只一层）
            let parentIds = roots.compactMap { $0.id }
            if !parentIds.isEmpty {
                let children: [PostCommentItem] = try await client
                    .from("PostComments")
                    .select("""
                            id, post_id, user_id, content, created_at, parent_comment_id,
                            user:Users(id, user_name, avatar_url)
                            """)
                    .eq("post_id", value: postId)
                    .in("parent_comment_id", values: parentIds)
                    .order("created_at", ascending: true)
                    .execute()
                    .value

                for child in children {
                    if let pid = child.parent_comment_id {
                        childComments[pid, default: []].append(child)
                    }
                }
            }
        } catch {
            showError = "加载评论失败"
            print("❌ 分页加载评论失败：\(error)")
        }

        await loadUserLikedCommentIds()
        await loadCommentLikeCounts()
    }

    // MARK: - 点赞（父评/子评通用）
    func toggleLike(comment: PostCommentItem) async {
        guard let user = DatabaseManager.shared.getCurrentUser(),
              let commentId = comment.id else { return }

        let isLiked = likedCommentIds.contains(commentId)

        do {
            if isLiked {
                _ = try await DatabaseManager.shared.client
                    .from("PostCommentLikes")
                    .delete()
                    .eq("user_id", value: user.id)
                    .eq("comment_id", value: commentId)
                    .execute()
            } else {
                let like = PostCommentLikes(comment_id: commentId, user_id: user.id)
                _ = try await DatabaseManager.shared.client
                    .from("PostCommentLikes")
                    .insert(like)
                    .execute()

                // 通知对方
                if comment.user_id != user.id {
                    let payload = NotificationInsertPayload(
                        user_id: comment.user_id,
                        from_user_id: user.id,
                        comment_id: commentId,
                        post_id: postId,
                        type: "like_comment"
                    )
                    _ = try await DatabaseManager.shared.client
                        .from("PostNotifications")
                        .insert(payload)
                        .execute()
                }
            }

            await loadUserLikedCommentIds()
            await loadCommentLikeCounts()

        } catch {
            print("❌ 点赞操作失败：\(error)")
        }
    }

    func loadUserLikedCommentIds() async {
        guard let user = DatabaseManager.shared.getCurrentUser() else { return }
        do {
            let liked: [PostCommentLikes] = try await DatabaseManager.shared.client
                .from("PostCommentLikes")
                .select("comment_id")
                .eq("user_id", value: user.id)
                .execute()
                .value
            self.likedCommentIds = Set(liked.map { $0.comment_id })
        } catch {
            print("❌ 获取点赞记录失败：\(error)")
        }
    }

    func loadCommentLikeCounts() async {
        do {
            let counts: [CommentLikeCount] = try await DatabaseManager.shared.client
                .from("CommentLikeCountView")
                .select()
                .execute()
                .value
            self.commentLikeCounts = Dictionary(uniqueKeysWithValues: counts.map { ($0.comment_id, $0.count) })
        } catch {
            print("❌ 加载点赞数失败：\(error)")
        }
    }

    // MARK: - 发布评论（依然用你原来的写库模型 PostComments）
    func sendComment() async {
        guard let current = DatabaseManager.shared.getCurrentUser(),
              !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        do {
            let payload = PostComments(
                id: nil,
                post_id: postId,
                user_id: current.id,
                content: inputText,
                created_at: nil,
                parent_comment_id: replyingToComment?.id  // 父评或子评都行
            )

            let response: PostComments = try await DatabaseManager.shared.client
                .from("PostComments")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

            if let newCommentId = response.id {
                let targetUserId = replyingToComment?.user_id ?? postOwnerId
                if targetUserId != current.id {
                    let notifyPayload = NotificationInsertPayload(
                        user_id: targetUserId,
                        from_user_id: current.id,
                        comment_id: newCommentId,
                        post_id: postId,
                        type: replyingToComment == nil ? "comment_post" : "reply_comment"
                    )
                    _ = try await DatabaseManager.shared.client
                        .from("PostNotifications")
                        .insert(notifyPayload)
                        .execute()
                }
            }

            inputText = ""
            replyingToComment = nil
            await loadInitialComments()

        } catch {
            showError = "发布失败"
            print("评论发布失败：\(error)")
        }
    }

    // MARK: - 删除评论
    func deleteComment(_ comment: PostCommentItem) async {
        guard let id = comment.id else { return }
        do {
            _ = try await DatabaseManager.shared.client
                .from("PostComments")
                .delete()
                .eq("id", value: id)
                .execute()
            await loadInitialComments()
        } catch {
            print("删除评论失败：\(error)")
        }
    }

    // MARK: - 自动分页（滚到底再拉下一页父评）
    func loadMoreCommentsIfNeeded(currentItem: PostCommentItem) async {
        guard let last = comments.last else { return }
        guard currentItem.id == last.id else { return }
        guard !isLoadingMore && hasMorePages else { return }

        isLoadingMore = true
        await loadMoreComments()
        isLoadingMore = false
    }
}


/*
 func loadComments() async {
     isLoading = true
     defer { isLoading = false }

     do {
         let allComments: [PostComments] = try await DatabaseManager.shared.client
             .from("PostComments")
             .select()
             .eq("post_id", value: postId)
             .order("created_at", ascending: true)
             .execute()
             .value
         
         print("🎯 获取评论成功，数量：\(allComments.count)")

         self.comments = allComments.filter { $0.parent_comment_id == nil }

         var grouped: [Int: [PostComments]] = [:]
         for comment in allComments {
             if let parent = comment.parent_comment_id {
                 grouped[parent, default: []].append(comment)
             }
         }
         self.childComments = grouped

     } catch {
         showError = "加载评论失败"
         print("❌ 评论加载错误：\(error)")
     }
     await loadUserLikedCommentIds()
     await loadCommentLikeCounts()

 }
 */
