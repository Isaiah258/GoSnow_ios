import SwiftUI

struct PostDetailView: View {
    let post: Post

    @StateObject private var commentVM: PostCommentViewModel
    @State private var commentText: String = ""
    @StateObject private var keyboard = KeyboardResponder() // 你项目里已有

    init(post: Post) {
        self.post = post
        _commentVM = StateObject(
            wrappedValue: PostCommentViewModel(
                postId: post.id ?? -1,
                postOwnerId: post.user_id
            )
        )
    }
    
 

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    // 主贴（沿用你现有的 Cell，不改 UI）
                    PostCellView(post: post, onReply: { _ in })

                    // 评论标题
                    HStack {
                        Text("评论").font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)

                    // 评论列表（父评 + 子评）
                    if commentVM.comments.isEmpty && !commentVM.isLoading {
                        HStack {
                            Spacer()
                            Text("还没有评论哦")
                                .foregroundColor(.gray)
                                .padding(.vertical, 16)
                            Spacer()
                        }
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(commentVM.comments) { parent in
                                CommentCellView(
                                    comment: parent,
                                    children: commentVM.childComments[parent.id ?? -1] ?? [],
                                    onReply: { tapped in
                                        commentVM.replyingToComment = tapped
                                    },
                                    commentVM: commentVM
                                )
                                .onAppear {
                                    Task { await commentVM.loadMoreCommentsIfNeeded(currentItem: parent) }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
                .padding(.top)
            }

            // 正在“回复谁”的提示条
            if let replying = commentVM.replyingToComment {
                HStack {
                    Text("回复：\(replying.user?.user_name ?? "用户\(replying.user_id.uuidString.prefix(6))")")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    Spacer()
                    Button("取消") { commentVM.replyingToComment = nil }
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
            }

            // 输入框 + 发送
            HStack(spacing: 12) {
                TextField("写评论...", text: $commentVM.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button {
                    Task { await commentVM.sendComment() }
                } label: {
                    Text("发送")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(commentVM.inputText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.4) : Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .disabled(commentVM.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .navigationTitle("帖子详情")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { Task { await commentVM.loadInitialComments() } }
        .padding(.bottom, keyboard.currentHeight)
        .animation(.easeOut(duration: 0.25), value: keyboard.currentHeight)
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture { UIApplication.shared.endEditing() }
        .simultaneousGesture(DragGesture().onChanged { _ in
            UIApplication.shared.endEditing()
        })
    }
}



#Preview {
    let mockUser = Users(
        id: UUID(),
        user_name: "预览用户",
        avatar_url: "avatar_ice"
    )

    let mockPost = Post(
        id: 1,
        user_id: UUID(),
        content: "这是一条测试帖子的内容，非常适合预览详情页。",
        like_count: 3,
        comment_count: 5,
        post_resort_id: 101,
        created_at: Date(),
        Users: mockUser,
        user_name: "预览用户",
        avatar_url: "avatar_ice",
        image_urls: [
            "https://via.placeholder.com/300x200",
            "https://via.placeholder.com/300x200"
        ]
    )

    return NavigationStack {
        PostDetailView(post: mockPost)
    }
}






