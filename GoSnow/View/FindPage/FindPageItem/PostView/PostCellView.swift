//
//  PostCellView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/7/9.
//


import SwiftUI


struct PostCellView: View {
    let onOpen: (Post) -> Void
    let post: Post
    var onTapImageAt: (([String], Int) -> Void)? = nil
    
    @State private var isOwner: Bool = false
    @State private var isLiked: Bool = false
    @State private var likeCount: Int
    @State private var isExpanded: Bool = false
    @State private var isShowingDetail = false
    
    // 新增：回复相关状态
    @State private var isReplying: Bool = false
    @State private var replyText: String = ""
    
    // 原有举报/删除状态
    @State private var showReportSuccess = false
    @State private var isReporting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    //@EnvironmentObject var userData: UserData  // 登录用户数据

    // 新增：当用户点击评论时调用
    let onReply: (Post) -> Void
    
    init(
        post: Post,
        onOpen: @escaping (Post) -> Void = { _ in },
        onReply: @escaping (Post) -> Void,
        onTapImageAt: (([String], Int) -> Void)? = nil    // ← 新增
    ) {
        self.post = post
        self.onOpen = onOpen
        self.onReply = onReply
        self.onTapImageAt = onTapImageAt                  // ← 赋值
        _likeCount = State(initialValue: post.like_count ?? 0)
    }

    let indent: CGFloat = 16 + 40 + 12
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: -- 头像 + 用户名 + 更多菜单
            HStack(alignment: .top, spacing: 12) {
                // 头像（优先用嵌套 Users 的头像，其次用旧字段）
                SafeUserAvatar(
                    source: post.Users?.avatar_url ?? post.avatar_url,
                    placeholderSystemName: "person.crop.circle.fill"
                )
                .frame(width: 36, height: 36)   // ← 缩小到 36
                .clipShape(Circle())

                // 用户名 + 时间 + 菜单
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(post.Users?.user_name ?? post.user_name ?? "匿名用户")  // ← 先读 Users 再回退
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Menu {
                            Button(action: reportPost) {
                                Label("举报", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                            }
                            if isOwner {
                                Button(action: deletePost) {
                                    Label("删除", systemImage: "trash.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.gray)
                        }
                    }

                    Text(post.created_at?.formatted(.relative(presentation: .numeric)) ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // MARK: -- 帖子正文（缩进与用户名对齐）
            Text(post.content)
                .lineLimit(isExpanded ? nil : 5)
                .padding(.vertical, 8)
                .padding(.leading, indent)
                .padding(.trailing, 16)

            if !isExpanded && post.content.count > 100 {
                Button("展开") { isExpanded.toggle() }
                    .font(.subheadline).foregroundColor(.blue)
                    .padding(.horizontal)
            }
            if isExpanded {
                Button("收起") { isExpanded.toggle() }
                    .font(.subheadline).foregroundColor(.blue)
                    .padding(.horizontal)
            }

            // MARK: -- 图片展示
            if let urls = post.image_urls, !urls.isEmpty {
                TwitterGridImages(urls: urls) { tapped in
                    onTapImageAt?(urls, tapped)  // ✅ 抛给父级
                }
            }

            // MARK: -- 点赞 & 回复 按钮
            HStack {
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                // 点赞
                Button(action: toggleLike) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .primary)
                            .frame(width: 18, height: 18)          // ← 固定
                        if likeCount > 0 {                         // ← 0 不显示
                            Text("\(likeCount)")
                                .font(.footnote)
                                .monospacedDigit()
                                .contentTransition(.numericText(value: Double(likeCount)))     // iOS 17+
                                .animation(.easeInOut(duration: 0.2), value: likeCount)
                        }
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(isLiked ? .red : .primary)
                Spacer()
                // 回复按钮
                let commentCount = post.comment_count ?? 0
                Button(action: {
                    onReply(post)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        if commentCount > 0 { Text("\(commentCount)") }
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
                Spacer()
            }
            .font(.subheadline)
            .padding(.vertical, 8)
            .padding(.horizontal)
            
            .alert(isPresented: $showAlert) {
                Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
            }

            // MARK: -- 内联回复输入框
            if isReplying {
                HStack(spacing: 8) {
                    TextField("写回复…", text: $replyText)
                        .textFieldStyle(.roundedBorder)

                    Button("发送") {
                        sendReply()
                    }
                    .disabled(replyText.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Divider()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
        .onAppear {
            // 只做“纯内存”作者判断
            if let current = DatabaseManager.shared.getCurrentUser() {
                isOwner = (current.id == post.user_id)
            } else {
                isOwner = false
            }

            // 读取点赞状态 & 计数（来自 PostLikes）
            Task { await loadLikeStateAndCount() }
        }
        .contentShape(Rectangle())
        .onTapGesture { onOpen(post) }
    }

    // MARK: -- 点赞逻辑（使用 PostLikes）
    private func toggleLike() {
        guard let postId = post.id else { return }
        guard let current = DatabaseManager.shared.getCurrentUser() else {
            alertMessage = "请先登录再点赞"; showAlert = true; return
        }

        // 乐观更新
        let oldLiked = isLiked
        let oldCount = likeCount
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1

        Task {
            do {
                let client = DatabaseManager.shared.client
                if isLiked {
                    // 点赞 -> 插入一行
                    let payload = PostLikes(id: nil, post_id: postId, user_id: current.id)
                    _ = try await client
                        .from("PostLikes")
                        .insert(payload)
                        .execute()
                } else {
                    // 取消点赞 -> 删除这行
                    _ = try await client
                        .from("PostLikes")
                        .delete()
                        .eq("post_id", value: postId)
                        .eq("user_id", value: current.id)
                        .execute()
                }

                // 回读准确计数（可选但推荐）
                let resp = try await client
                    .from("PostLikes")
                    .select("id", head: true, count: .exact)   // 只要 count
                    .eq("post_id", value: postId)
                    .execute()
                likeCount = resp.count ?? max(0, likeCount)

            } catch {
                // 回滚 UI
                isLiked = oldLiked
                likeCount = oldCount
                print("更新点赞失败：", error)
            }
        }
    }

    // 进入 Cell 时从 PostLikes 回读“我是否点赞”和“当前总数”
    private func loadLikeStateAndCount() async {
        guard let postId = post.id else { return }
        let client = DatabaseManager.shared.client

        // 计数
        do {
            let resp = try await client
                .from("PostLikes")
                .select("id", head: true, count: .exact)
                .eq("post_id", value: postId)
                .execute()
            likeCount = resp.count ?? 0
        } catch {
            print("读取点赞计数失败：", error)
        }

        // 是否点赞
        if let current = DatabaseManager.shared.getCurrentUser() {
            do {
                let mine: [PostLikes] = try await client
                    .from("PostLikes")
                    .select("post_id, user_id")
                    .eq("post_id", value: postId)
                    .eq("user_id", value: current.id)
                    .limit(1)
                    .execute()
                    .value
                isLiked = !mine.isEmpty
            } catch {
                print("读取我的点赞状态失败：", error)
            }
        } else {
            isLiked = false
        }
    }

    // MARK: -- 发送回复
    private func sendReply() {
        guard let current = DatabaseManager.shared.getCurrentUser(),
              let postId = post.id else {
            alertMessage = "无法发送回复"
            showAlert = true
            return
        }

        isReplying = false
        let text = replyText
        replyText = ""

        Task {
            do {
                let newReply = NewReply(
                    post_id: postId,
                    user_id: current.id.uuidString,
                    content: text
                )
                let response = try await DatabaseManager.shared.client
                    .from("Reply")
                    .insert(newReply)   // 直接传入 Codable 对象
                    .execute()
                if response.status == 201 {
                    // 成功逻辑
                } else {
                    throw NSError(domain: "Supabase",
                                  code: response.status,
                                  userInfo: nil)
                }
            } catch {
                alertMessage = "回复失败"
                showAlert = true
                print("回复失败：", error)
            }
        }
    }

    // 举报
    private func reportPost() {
        guard !isReporting else { return }
        isReporting = true

        guard let currentUser = DatabaseManager.shared.getCurrentUser() else {
            isReporting = false
            showAlert = true
            alertMessage = "未登录，无法举报"
            return
        }
        guard let postId = post.id else {
            isReporting = false
            showAlert = true
            alertMessage = "帖子 ID 无效"
            return
        }

        Task {
            defer { isReporting = false }
            do {
                let payload = ReportInsert(post_id: postId, reporter_id: currentUser.id)
                _ = try await DatabaseManager.shared.client
                    .from("Report")
                    .insert(payload)               // 👈 不再传 id
                    .execute()

                showAlert = true
                alertMessage = "举报成功！"
            } catch {
                let msg = error.localizedDescription.lowercased()
                if msg.contains("duplicate key") || msg.contains("23505") {
                    showAlert = true
                    alertMessage = "您已经举报过这条内容"
                } else {
                    showAlert = true
                    alertMessage = "举报失败，请稍后再试。\n\(error.localizedDescription)"
                }
            }
        }
    }

    // 删除帖子功能
    private func deletePost() {
        guard let currentUser = DatabaseManager.shared.getCurrentUser() else {
            print("未登录用户无法删除帖子")
            showAlert = true
            alertMessage = "未登录，无法删除帖子"
            return
        }

        guard post.user_id == currentUser.id else {
            print("只能删除自己的帖子")
            showAlert = true
            alertMessage = "无法删除其他用户的帖子"
            return
        }

        guard let postId = post.id else {
            print("帖子 ID 无效，无法删除")
            showAlert = true
            alertMessage = "帖子 ID 无效"
            return
        }

        Task {
            do {
                let response = try await DatabaseManager.shared.client
                    .from("Post")
                    .delete()
                    .eq("id", value: postId)
                    .execute()

                if response.status == 200 {
                    showAlert = true
                    alertMessage = "帖子已删除"
                    print("帖子已删除")
                } else {
                    // 处理失败情况，打印状态码和错误信息
                    showAlert = true
                    alertMessage = "删除失败，请稍后再试"
                    print("删除失败，响应状态: \(response.status)")
                }
            } catch {
                showAlert = true
                alertMessage = "删除失败，请稍后再试"
                print("删除失败: \(error)")
            }
        }
    }
    
    
     private struct SafeUserAvatar: View {
            let source: String?
            let placeholderSystemName: String
            var body: some View {
                if let urlStr = source, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        case .failure: Image(systemName: placeholderSystemName).resizable().scaledToFill()
                        case .empty: ProgressView()
                        @unknown default: Image(systemName: placeholderSystemName).resizable().scaledToFill()
                        }
                    }
                } else {
                    Image(systemName: placeholderSystemName).resizable().scaledToFill()
                }
            }
        }

    
    
}

private struct ReportInsert: Encodable {
    let post_id: Int
    let reporter_id: UUID
}











/*
 
 import SwiftUI

 struct PostCellView: View {
     let post: Post
     @State private var isLiked: Bool = false
     @State private var likeCount: Int
     @State private var isExpanded: Bool = false
     @State private var showReportSuccess = false
     @State private var isReporting = false
     @EnvironmentObject var userData: UserData  // 使用环境对象传递用户数据

     init(post: Post) {
         self.post = post
         _likeCount = State(initialValue: post.like_count)
     }

     var body: some View {
         VStack {
             HStack(alignment: .top, spacing: 12) {
                 // 使用 userData.userAvatar 来加载头像
                 // 显示头像
                 if let avatarUrl = post.avatar_url, let image = UIImage(named: avatarUrl) {
                                 Image(uiImage: image)
                                     .resizable()
                                     .scaledToFit()
                                     .frame(width: 40, height: 40)
                                     .clipShape(Circle())
                             } else {
                                 Image(systemName: "person.crop.circle.fill")
                                     .resizable()
                                     .scaledToFit()
                                     .frame(width: 40, height: 40)
                                     .clipShape(Circle())
                             }


                 VStack(alignment: .leading, spacing: 4) {
                     // 使用 post.Users?.user_name 来加载昵称
                     HStack {
                         Text(post.user_name ?? "MOMO")
                             .fontWeight(.semibold)
                         
                         Spacer()

                         Menu {
                             Button(action: reportPost) {
                                 Label("举报", systemImage: "exclamationmark.triangle.fill")
                                     .foregroundColor(.red)
                             }
                         } label: {
                             Image(systemName: "ellipsis")
                                 .foregroundStyle(Color(.systemGray2))
                         }
                     }
                     

                     Text(post.created_at?.formatted(.relative(presentation: .numeric)) ?? "错误")
                         .font(.caption)
                         .foregroundColor(.gray)

                     Text(post.content)
                         .lineLimit(isExpanded ? nil : 5)
                         .padding(.bottom, 5)
                         .padding(.top, 2)

                     if !isExpanded && post.content.count > 100 {
                         Button(action: { isExpanded.toggle() }) {
                             Text("展开")
                                 .font(.subheadline)
                                 .foregroundColor(.blue)
                         }
                         .padding(.top, 4)
                     }

                     if isExpanded {
                         Button(action: { isExpanded.toggle() }) {
                             Text("收起")
                                 .font(.subheadline)
                                 .foregroundColor(.blue)
                         }
                         .padding(.top, 4)
                     }

                     HStack {
                         Spacer()
                         Button(action: toggleLike) {
                             HStack {
                                 Image(systemName: isLiked ? "heart.fill" : "heart")
                                     .foregroundColor(isLiked ? .red : .black)
                                 Text("\(likeCount)")
                                     .foregroundColor(.black)
                             }
                         }
                     }
                     .padding(.trailing, 20)
                     .padding(.vertical, 8)
                     .font(.subheadline)

                     if showReportSuccess {
                         Text("举报成功！")
                             .foregroundColor(.green)
                             .font(.subheadline)
                             .padding(.top, 4)
                     }
                 }
             }
             .padding(.leading)
             .padding(.trailing)
         }
         Divider()
     }

     private func toggleLike() {
         isLiked.toggle()
         likeCount += isLiked ? 1 : -1
         updateLikeCountInDatabase(postId: post.id ?? 0, likeCount: likeCount)
     }

     private func updateLikeCountInDatabase(postId: Int, likeCount: Int) {
         Task {
             do {
                 let _ = try await DatabaseManager.shared.client
                     .from("Post")
                     .update(["like_count": likeCount])
                     .eq("id", value: postId)
                     .execute()
             } catch {
                 print("Failed to update like count: \(error)")
             }
         }
     }

     private func reportPost() {
         guard !isReporting else { return }
         isReporting = true

         guard let currentUser = DatabaseManager.shared.getCurrentUser() else {
             print("未登录用户无法举报")
             isReporting = false
             return
         }

         guard let postId = post.id else {
             print("帖子 ID 无效，无法举报")
             isReporting = false
             return
         }

         let report = Report(id: 0, post_id: postId, reporter_id: currentUser.id)

         Task {
             do {
                 let response = try await DatabaseManager.shared.client
                     .from("Report")
                     .insert(report)
                     .execute()

                 if response.status == 201 {
                     showReportSuccess = true
                     DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                         showReportSuccess = false
                     }
                     print("举报成功")
                 }
             }
             isReporting = false
         }
     }
 }

 struct PostCellView_Previews: PreviewProvider {
     static var previews: some View {
         let testUser = Users(id: UUID(), user_name: "TestUser", avatar_url: "avatar_test")
         let testPost = Post(id: 1, user_id: UUID(), content: "这是一个示例帖子。", like_count: 0, comment_count: 0, created_at: Date(), Users: testUser, user_name: "TestUser", avatar_url: "avatar_test")
         let userData = UserData()

         return PostCellView(post: testPost)
             .environmentObject(userData) // Ensure userData is passed down
     }
 }
 
 
 */
