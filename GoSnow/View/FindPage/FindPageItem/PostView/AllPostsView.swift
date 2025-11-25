//
//  AllPostsView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/7/19.
//

import SwiftUI
import Kingfisher

struct AllPostsView: View {
    
    @StateObject private var viewModel = AllPostsViewModel()
    @State private var selectedPost: Post? = nil
    // 👇 新增：预取器 & 预取函数
    @State private var prefetcher: ImagePrefetcher? = nil

    // 👇 新增：图片查看器所需状态
    @State private var viewerUrls: [String] = []
    @State private var viewerIndex: Int = 0
    @State private var isPhotoViewerPresented: Bool = false
    
    private func prefetchImages(for posts: [Post]) {
        // 头像 + 帖子内图
        let urls: [URL] =
            posts.compactMap { URL(string: $0.avatar_url ?? "") } +
            posts.flatMap { $0.image_urls?.compactMap { URL(string: $0) } ?? [] }

        prefetcher?.stop()
        prefetcher = ImagePrefetcher(urls: urls)
        prefetcher?.start()
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.posts) { post in
                    PostCellView(
                        post: post,
                        onOpen: { tapped in selectedPost = tapped },   // 点空白进入详情
                        onReply: { tapped in selectedPost = tapped },   // 点评论进入
                        // 👇 新增：把点击图片回调透出来，设置查看器状态并弹出
                        onTapImageAt: { urls, index in
                            viewerUrls = urls
                            viewerIndex = index
                            isPhotoViewerPresented = true
                        }
                    )
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture { UIApplication.shared.endEditing() }
        .simultaneousGesture(DragGesture().onChanged { _ in
            UIApplication.shared.endEditing()
        })
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadPosts()
        }
        .navigationDestination(item: $selectedPost) { post in
            PostDetailView(post: post)
        }
        .onChange(of: viewModel.posts) { _, newValue in
            prefetchImages(for: newValue)
        }
        .onDisappear { prefetcher?.stop() }
        .onReceive(NotificationCenter.default.publisher(for: .postDidCreate)) { _ in
            Task { await viewModel.refresh() }
        }
        // 👇 就把你给的 fullScreenCover 放在这里（最外层视图的 modifier 链）
        .fullScreenCover(isPresented: $isPhotoViewerPresented) {
            ZStack {
                if !viewerUrls.isEmpty {
                    // 简易版分页：每页一个 PhotoViewer（独立缩放、上下滑关闭）
                    TabView(selection: $viewerIndex) {
                        ForEach(Array(viewerUrls.enumerated()), id: \.offset) { idx, url in
                            PhotoViewer(imageUrl: url, isPresented: $isPhotoViewerPresented)
                                .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea()
                        .onAppear { isPhotoViewerPresented = false }
                }
            }
        }

    }
}


@MainActor
class AllPostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false

    private let database = DatabaseManager.shared

    @MainActor
    func loadPosts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            posts = try await database.client
                .from("Post")
                .select("id, user_id, content, image_urls, post_resort_id, created_at")
                .order("created_at", ascending: false)
                .execute()
                .value
            print("✅ loaded posts:", posts.count)
        } catch {
            print("❌ 加载帖子出错:", error)
        }
    }

    func refresh() async {
        await loadPosts()
    }
}


#Preview {
    AllPostsView()
}



