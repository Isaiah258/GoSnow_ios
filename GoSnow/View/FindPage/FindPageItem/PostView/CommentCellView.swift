//
//  CommentCellView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/7/28.
//
import SwiftUI
import Kingfisher

struct CommentCellView: View {
    let comment: PostCommentItem
    let children: [PostCommentItem]
    let onReply: (PostCommentItem) -> Void
    @ObservedObject var commentVM: PostCommentViewModel

    @State private var showAllReplies = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // 父评论
            HStack(alignment: .top, spacing: 10) {
                AvatarKF(urlString: comment.user?.avatar_url, size: 36)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(comment.user?.user_name ?? "用户\(comment.user_id.uuidString.prefix(6))")
                            .font(.subheadline).fontWeight(.semibold)
                        Text(comment.created_at?.formatted(.relative(presentation: .named)) ?? "")
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    Text(comment.content)
                        .foregroundStyle(.primary)

                    HStack(spacing: 14) {
                        Button {
                            Task { await commentVM.toggleLike(comment: comment) }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: liked(for: comment) ? "hand.thumbsup.fill" : "hand.thumbsup")
                                Text("\(commentVM.commentLikeCounts[comment.id ?? -1] ?? 0)")
                            }
                            .foregroundColor(liked(for: comment) ? .blue : .gray)
                        }

                        Button("回复") { onReply(comment) }
                            .foregroundColor(.blue)

                        Button("删除") {
                            Task { await commentVM.deleteComment(comment) }
                        }
                        .foregroundColor(.red)
                    }
                    .font(.caption)
                    .padding(.top, 2)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onReply(comment) }

            // 子评论（最多 2 条，更多时给“展开更多评论”）
            if !children.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(showAllReplies ? children : Array(children.prefix(2)), id: \.id) { child in
                        HStack(alignment: .top, spacing: 8) {
                            AvatarKF(urlString: child.user?.avatar_url, size: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(child.user?.user_name ?? "用户\(child.user_id.uuidString.prefix(6))")
                                        .font(.caption).fontWeight(.semibold)
                                    Text(child.created_at?.formatted(.relative(presentation: .named)) ?? "")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }

                                Text(child.content)
                                    .font(.subheadline)

                                HStack(spacing: 12) {
                                    Button {
                                        Task { await commentVM.toggleLike(comment: child) }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: liked(for: child) ? "hand.thumbsup.fill" : "hand.thumbsup")
                                            Text("\(commentVM.commentLikeCounts[child.id ?? -1] ?? 0)")
                                        }
                                        .foregroundColor(liked(for: child) ? .blue : .gray)
                                    }

                                    Button("回复") { onReply(child) }
                                        .foregroundColor(.blue)

                                    Button("删除") {
                                        Task { await commentVM.deleteComment(child) } // ← 修正：删除子评本身
                                    }
                                    .foregroundColor(.red)
                                }
                                .font(.caption)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { onReply(child) }
                    }

                    if children.count > 2 && !showAllReplies {
                        Button("展开更多评论") { showAllReplies = true }
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.leading, 44) // 与父头像对齐缩进
            }
        }
        .padding(.vertical, 8)
    }

    private func liked(for item: PostCommentItem) -> Bool {
        guard let id = item.id else { return false }
        return commentVM.likedCommentIds.contains(id)
    }
}

// 小头像（Kingfisher）
private struct AvatarKF: View {
    let urlString: String?
    var size: CGFloat = 36

    var body: some View {
        Group {
            if let s = urlString, let url = URL(string: s) {
                KFImage(url)
                    .cacheOriginalImage()
                    .setProcessor(RoundCornerImageProcessor(cornerRadius: size/2))
                    .placeholder {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable().scaledToFill()
                            .foregroundStyle(.gray.opacity(0.4))
                    }
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable().scaledToFill()
                    .foregroundStyle(.gray.opacity(0.4))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}



