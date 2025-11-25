//
//  PostTimelineViewModel.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/5/14.
//

import Foundation

import Supabase 

@MainActor
class PostTimelineViewModel: ObservableObject {
    // MARK: - Published 状态
    
    /// 帖子列表
    @Published var posts: [Post] = []
    
    /// 当前页码
    private var currentPage = 0
    
    /// 每页条数
    private let pageSize = 10
    
    /// 是否正在加载（刷新或分页）
    @Published var isLoading = false
    
    /// 是否还有更多帖可加载
    @Published var hasMorePosts = true
    
    /// 当前登录用户 ID（UUID 字符串）
    @Published var userId: UUID? = nil

    
    // MARK: - 构造器
    
    init() {
        loadUserId()
    }
    
    // MARK: - 对外 API
    
    /// 刷新：清空所有数据，并重新加载第一页
    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        currentPage = 0
        hasMorePosts = true
        posts.removeAll()
        
        await loadNextPage()
    }
    
    /// 加载下一页
    func loadNextPage() async {
        guard !isLoading, hasMorePosts else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let start = currentPage * pageSize
            let end = start + pageSize - 1
            
            // 一次性拉取带用户信息的帖子，或后续优化为 JOIN
            let fetched: [Post] = try await DatabaseManager.shared.client
                .from("Post")
                .select("*, Users(id, user_name, avatar_url)")
                .range(from: start, to: end)
                .execute()
                .value
            
            // 合并去重
            let newOnes = fetched.filter { p in !posts.contains(where: { $0.id == p.id }) }
            posts.append(contentsOf: newOnes)
            
            // 更新分页状态
            if fetched.count < pageSize {
                hasMorePosts = false
            } else {
                currentPage += 1
            }
        } catch {
            // 这里可触发错误提示
            print("加载帖子失败：", error)
        }
    }
    
    // MARK: - 私有方法
    
    /// 从本地或 Supabase Auth 拿到当前用户 ID
    private func loadUserId() {
        
        if DatabaseManager.shared.getCurrentUser() != nil {
            userId = DatabaseManager.shared.getCurrentUser()?.id   // id 本身就是 UUID

            
        }
    }
}

