//
//  日后修改.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/7/19.
//

// 1
/*
 // 以后做完评论回复功能再来修改
 ForEach(resortPosts) { post in
 PostCellView(post: post, onReply: { _ in })
 }
 */



// 2
// ai经常出错的地方
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
 }
 */

/*
 let rowHeight = max((gridAvailHeight - spacing * CGFloat(rows - 1)) / CGFloat(rows), 12)
 */

/*
 用户名唯一性检测
 */
