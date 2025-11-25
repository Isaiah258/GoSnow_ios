//
//  ResortPostsView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/7/19.
//
import SwiftUI
import Supabase

struct ResortPostsView: View {
    @State private var resorts: [Resorts_data] = []
    @State private var searchText: String = ""
    @State private var selectedResort: Resorts_data? = nil
    @AppStorage("selectedResortId") private var selectedResortId: Int?
    @State private var resortPosts: [Post] = []
    @State private var isLoading = false
    @State private var selectedPost: Post? = nil

    // ✅ 新增：用于弹出 PhotoViewer
    @State private var viewerUrls: [String] = []
    @State private var viewerIndex: Int = 0
    @State private var isPhotoViewerPresented: Bool = false

    var filteredResorts: [Resorts_data] {
        if searchText.isEmpty {
            return []
        } else {
            return resorts.filter {
                $0.name_resort.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 雪场搜索选择区域
            ZStack(alignment: .leading) {
                if searchText.isEmpty {
                    HStack {
                        Text("搜索雪场查看帖子")
                            .foregroundColor(.blue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                    }
                }
                TextField("", text: $searchText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }

            if !filteredResorts.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(filteredResorts, id: \.id) { resort in
                            Button {
                                selectedResort = resort
                                selectedResortId = resort.id
                                searchText = ""
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                fetchPosts(for: resort.id)
                            } label: {
                                Text(resort.name_resort)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(RoundedRectangle(cornerRadius: 25).stroke(Color.blue, lineWidth: 1))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .frame(maxHeight: 140)
            } else if let selected = selectedResort {
                Text("已选择雪场：\(selected.name_resort)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }

            Divider()

            if isLoading {
                ProgressView("加载中…")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if resortPosts.isEmpty {
                Text("该雪场还没有帖子")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {

                        // ✅ 改动点：把 onTapImageAt 透传出来，打开 PhotoViewer
                        ForEach(resortPosts) { post in
                            PostCellView(
                                post: post,
                                onOpen: { tapped in selectedPost = tapped },
                                onReply: { tapped in selectedPost = tapped },
                                onTapImageAt: { urls, index in
                                    viewerUrls = urls
                                    viewerIndex = index
                                    isPhotoViewerPresented = true
                                }
                            )
                        }

                    }
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("雪场")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchResorts()
            if let cachedId = selectedResortId {
                selectedResort = resorts.first { $0.id == cachedId }
                if let id = selectedResort?.id {
                    fetchPosts(for: id)
                }
            }
        }
        .navigationDestination(item: $selectedPost) { post in
            PostDetailView(post: post)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture { UIApplication.shared.endEditing() }
        .simultaneousGesture(DragGesture().onChanged { _ in
            UIApplication.shared.endEditing()
        })

        // ✅ 新增：弹出重命名后的 PhotoViewer（单张）
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

    private func fetchResorts() {
        Task {
            do {
                resorts = try await DatabaseManager.shared.client
                    .from("Resorts_data")
                    .select()
                    .execute()
                    .value
            } catch {
                print("获取雪场失败：\(error)")
            }
        }
    }

    private func fetchPosts(for resortId: Int) {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                resortPosts = try await DatabaseManager.shared.client
                    .from("Post")
                    .select("id, user_id, content, image_urls, post_resort_id, created_at")
                    .eq("post_resort_id", value: resortId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value

            } catch {
                print("获取帖子失败：\(error)")
            }
        }
    }
}

#Preview {
    ResortPostsView()
}

