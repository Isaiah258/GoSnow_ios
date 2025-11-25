//
//  NotificationRowView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/6.
//

import SwiftUI

struct NotificationRowView: View {
    let notification: PostNotifications

    var body: some View {
        HStack(spacing: 12) {
            KFUserAvatar(urlString: notification.actor_avatar_url, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.actor_name ?? "用户")
                    .font(.subheadline).bold()

                Text(message(for: notification.type))
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(notification.created_at.formatted()) // 也可以用 .formatted(.relative(...))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(previewText(for: notification))
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(3)
                .truncationMode(.tail)
                .frame(width: 90, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }

    private func message(for type: String) -> String {
        switch type {
        case "like_comment":  return "赞了你的评论"
        case "comment_post":  return "评论了你的帖子"
        case "reply_comment": return "回复了你的评论"
        default:              return "有新的互动"
        }
    }

    private func previewText(for n: PostNotifications) -> String {
        switch n.type {
        case "like_comment", "reply_comment":
            return n.comment?.content ?? "评论内容缺失"
        case "comment_post":
            return n.post?.content ?? "帖子内容缺失"
        default:
            return ""
        }
    }
}
















