//
//  FeedView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/7/9.
//
import SwiftUI

// MARK: - Tabs & Routing
enum PostTab: Int, CaseIterable {
    case all, resort
    var title: String { self == .all ? "雪圈" : "雪场" }
}

enum PostNavigation: Hashable {
    case notification
    case compose(UUID)   // 传 userId
}

// MARK: - PostView
struct PostView: View {
    @ObservedObject var viewModel: PostTimelineViewModel
    @ObservedObject var notificationVM: NotificationViewModel
    @Binding var navPath: NavigationPath

    @State private var selectedTab: PostTab = .all

    var body: some View {
        VStack(spacing: 0) {
            tabsBar
            pages
        }
        .navigationTitle("雪圈")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarTrailing }
        .overlay(alignment: .bottomTrailing) { composeFAB }
        .task { ensureUserIdIfNeeded() }
        .onReceive(NotificationCenter.default.publisher(for: .postDidCreate)) { _ in
            // 回到“全部”
            withAnimation { selectedTab = .all }
        }
    }


    // MARK: - Subviews
    private var tabsBar: some View {
        HStack {
            ForEach(PostTab.allCases, id: \.self) { tab in
                TabHeader(
                    title: tab.title,
                    isSelected: selectedTab == tab
                )
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { withAnimation { selectedTab = tab } }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }

    private var pages: some View {
        TabView(selection: $selectedTab) {
            AllPostsView()
                .tag(PostTab.all)
            ResortPostsView()
                .tag(PostTab.resort)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var toolbarTrailing: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                navPath.append(PostNavigation.notification)
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .foregroundStyle(.primary)
                    if notificationVM.hasUnreadNotifications {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 6, y: -6)
                    }
                }
            }
        }
    }

    private var composeFAB: some View {
        Button {
            if let uid = viewModel.userId ?? DatabaseManager.shared.getCurrentUser()?.id {
                viewModel.userId = uid
                navPath.append(PostNavigation.compose(uid))
            } else {
                // 未登录：这里你可改成弹登录
                print("⚠️ 未登录，无法发布帖子")
            }
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(.white)
                .font(.title)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color("myBlue", bundle: .main)))
                .shadow(radius: 3)
        }
        .padding()
        .accessibilityLabel("发布雪圈")
    }

    // MARK: - Helpers
    private func ensureUserIdIfNeeded() {
        if viewModel.userId == nil {
            viewModel.userId = DatabaseManager.shared.getCurrentUser()?.id
        }
    }
}

// MARK: - Small component
private struct TabHeader: View {
    let title: String
    let isSelected: Bool
    var body: some View {
        VStack {
            Text(title)
                .fontWeight(isSelected ? .bold : .regular)
            Capsule()
                .fill(isSelected ? Color("myBlue", bundle: .main) : .clear)
                .frame(height: 3)
                .padding(.top, 2)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - AddPostScreen（改动点：不再调用 dismiss，交由父级导航处理返回）
struct AddPostScreen: View {
    let userId: UUID
    var onComplete: () -> Void

    var body: some View {
        // 直接嵌入，不再需要中间 Binding
        AddPostView(userId: userId) {
            onComplete()   // 只把事件往上传递；父级在 navigationDestination 里 pop & 刷新
        }
    }
}



// =======================================================
// MARK: - DEBUG 预览用占位（在你的工程里可删除）
// =======================================================

/*
#if DEBUG



/// 发表界面（占位版）
struct AddPostScreen: View {
    @Environment(\.dismiss) private var dismiss
    let userId: UUID
    var onComplete: () -> Void = {}

    var body: some View {
        VStack(spacing: 16) {
            Text("Compose for \(userId.uuidString.prefix(6))…")
                .font(.headline)
            Text("（这里替换为你的 AddPostView）")
                .foregroundStyle(.secondary)
            Button("完成并返回") {
                onComplete()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("发布雪圈")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 通知页（占位版）
struct NotificationsScreen: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("通知中心（占位）")
                .font(.headline)
            Text("在你的工程里替换为真实 NotificationView")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("通知")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 预览：包含 NavigationStack + 路由
struct PostView_Previews: PreviewProvider {
    struct Host: View {
        @State private var path = NavigationPath()
        var body: some View {
            NavigationStack(path: $path) {
                PostView(
                    viewModel: PostTimelineViewModel(),
                    notificationVM: NotificationViewModel(),
                    navPath: $path
                )
                .navigationDestination(for: PostNavigation.self) { route in
                    switch route {
                    case .notification:
                        NotificationsScreen()
                    case .compose(let uid):
                        AddPostScreen(userId: uid) {
                            // 发表完成后的回退逻辑（这里直接返回上一层）
                        }
                    }
                }
            }
        }
    }

    static var previews: some View {
        Host()
            .preferredColorScheme(.light)
    }
}
#endif
*/


/*
 
 import SwiftUI

 enum PostTab: Int, CaseIterable { case all, resort
     var title: String { self == .all ? "雪圈" : "雪场" }
 }
 enum PostNavigation: Hashable {
     case notification
     case compose(UUID)   // 传 userId
 }


 struct PostView: View {
     @ObservedObject var viewModel: PostTimelineViewModel   // ← 接收父级传入
         @ObservedObject var notificationVM: NotificationViewModel
         @Binding var navPath: NavigationPath

         @State private var selectedTab: PostTab = .all
         @GestureState private var dragOffset: CGFloat = 0

     var body: some View {
         VStack(spacing: 0) {
             // 顶部标签栏
             HStack {
                 ForEach(PostTab.allCases, id: \.self) { tab in
                     VStack {
                         Text(tab.title)
                             .fontWeight(selectedTab == tab ? .bold : .regular)
                             .foregroundColor(selectedTab == tab ? .primary : .gray)
                         Capsule()
                             .fill(selectedTab == tab ? Color.MyBlue : .clear)
                             .frame(height: 3)
                             .padding(.top, 2)
                     }
                     .frame(maxWidth: .infinity)
                     .onTapGesture { withAnimation { selectedTab = tab } }
                 }
             }
             .padding(.horizontal)
             .padding(.top, 8)
             .background(Color(.systemBackground))

             TabView(selection: $selectedTab) {
                 AllPostsView().tag(PostTab.all)
                 ResortPostsView().tag(PostTab.resort)
             }
             .tabViewStyle(.page(indexDisplayMode: .never))
         }
         .navigationTitle("雪圈")
         .navigationBarTitleDisplayMode(.inline)
         .toolbar {
             ToolbarItem(placement: .navigationBarTrailing) {
                 Button {
                     navPath.append(PostNavigation.notification)
                 } label: {
                     ZStack(alignment: .topTrailing) {
                         Image(systemName: "bell").foregroundStyle(.black)
                         if notificationVM.hasUnreadNotifications {
                             Circle().fill(Color.red).frame(width: 8, height: 8).offset(x: 6, y: -6)
                         }
                     }
                 }
             }
         }
         // 右下角发布按钮 → push 到 compose
                 .overlay(alignment: .bottomTrailing) {
                     Button {
                         if let uid = viewModel.userId ?? DatabaseManager.shared.getCurrentUser()?.id {
                             viewModel.userId = uid
                             navPath.append(PostNavigation.compose(uid))
                         } else {
                             // TODO: 未登录处理（弹登录页或提示）
                             print("⚠️ 未登录，无法发布帖子")
                         }
                     } label: {
                         Image(systemName: "plus")
                             .foregroundColor(.white)
                             .font(.title)
                             .frame(width: 56, height: 56)
                             .background(Circle().fill(Color.MyBlue))
                             .shadow(radius: 3)
                     }
                     .padding()
                 }
                 // （可选）进入页面兜底拉一次 userId，避免为空
                 .task {
                     if viewModel.userId == nil {
                         viewModel.userId = DatabaseManager.shared.getCurrentUser()?.id
                     }
                 }
     }
 }


 #Preview {
     PostView(
         viewModel: PostTimelineViewModel(),                   // ← 新增
         notificationVM: NotificationViewModel(),
         navPath: .constant(NavigationPath())
     )
 }



 struct AddPostScreen: View {
     @Environment(\.dismiss) private var dismiss
     @State private var present = true

     let userId: UUID
     var onComplete: () -> Void

     var body: some View {
         // 直接复用你原来的 AddPostView（它需要 Binding<Bool> 关闭）
         AddPostView(isPresented: $present, userId: userId) {
             onComplete()
             dismiss()   // 发布完成后返回
         }
         .onChange(of: present) { _, new in
             if !new { dismiss() } // 用户点“取消”时返回
         }
     }
 }

 extension Color {
     static let MyBlue = Color("myBlue")
 }

 
 */


/*
import SwiftUI

struct PostView: View {
    @State private var posts: [Post] = []
    @State private var newPostContent: String = ""
    @State private var userId: String? = nil
    @State private var isPresentingAddPostSheet = false
    @State private var currentPage: Int = 0
    @State private var isLoading = false
    @State private var hasMorePosts = true // 是否还有更多帖子可加载

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    if posts.isEmpty && !isLoading {
                        // 当没有帖子时显示提示
                        Text("还没有任何帖子，快来发布第一条吧！")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(posts) { post in
                            PostCellView(post: post)
                        }
                    }

                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if hasMorePosts {
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                if geo.frame(in: .global).maxY < UIScreen.main.bounds.height {
                                    fetchPosts()
                                }
                            }
                        }
                        .frame(height: 50)
                    }
                }
            }
            .navigationTitle("雪圈")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if userId == nil {
                            print("用户未登录")
                        } else {
                            isPresentingAddPostSheet = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                fetchPosts()
                if let user = DatabaseManager.shared.getCurrentUser() {
                    userId = user.id.uuidString
                }
            }
            .sheet(isPresented: $isPresentingAddPostSheet) {
                if let userId = userId {
                    AddPostView(isPresented: $isPresentingAddPostSheet, userId: userId)
                }
            }
            .padding()
        }
    }

    func fetchPosts() {
        guard !isLoading, hasMorePosts else { return } // 防止重复加载
        isLoading = true

        Task {
            do {
                let fetchedPosts: [Post] = try await DatabaseManager.shared.client
                    .from("Post")
                    .select()
                    .range(from: currentPage * 10, to: (currentPage + 1) * 10 - 1)
                    .execute()
                    .value

                posts.append(contentsOf: fetchedPosts)

                // 更新是否有更多帖子
                if fetchedPosts.isEmpty {
                    hasMorePosts = false
                } else {
                    currentPage += 1
                }
            } catch {
                print("发生错误: \(error)")
            }
            isLoading = false
        }
    }
}
#Preview {
    PostView()
}

*/


