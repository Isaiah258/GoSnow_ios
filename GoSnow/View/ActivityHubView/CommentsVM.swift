//
//  CommentsVM.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/26.
//

import Foundation
import SwiftUI
import Supabase

struct PostComment: Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let body: String
    let userId: UUID?
    let authorName: String
    let authorAvatarURL: URL?
    var canDelete: Bool
}

@MainActor
final class CommentsVM: ObservableObject {
    @Published var items: [PostComment] = []
    @Published var isLoading = false
    @Published var isPaginating = false
    @Published var reachedEnd = false
    @Published var error: String?

    private var nextCursor: Date? = nil
    private let postId: UUID
    private var currentUserId: UUID?
    

    init(postId: UUID) {
        self.postId = postId
    }

    private let iso8601ms: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    func loadInitial() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            if let u = try? await DatabaseManager.shared.client.auth.user() {
                currentUserId = u.id
            } else { currentUserId = nil }

            let fresh = try await fetchPage(before: nil, limit: 30)
            items = fresh
            nextCursor = fresh.last?.createdAt
            reachedEnd = fresh.isEmpty
        } catch {
            self.error = (error as NSError).localizedDescription
        }
    }

    func loadMore() async {
        guard !isPaginating, !reachedEnd else { return }
        isPaginating = true
        defer { isPaginating = false }

        do {
            let more = try await fetchPage(before: nextCursor, limit: 30)
            if more.isEmpty { reachedEnd = true }
            items.append(contentsOf: more)
            nextCursor = more.last?.createdAt
        } catch {
            self.error = (error as NSError).localizedDescription
        }
    }

    func add(body: String) async {
        let c = DatabaseManager.shared.client
        do {
            guard let u = try? await c.auth.user() else { throw NSError(domain: "auth", code: -1) }
            // ⛳️ 改这里：author_id -> user_id
            struct Insert: Encodable { let post_id: UUID; let user_id: UUID; let body: String } // ✅
            try await c.from("resorts_post_comments")
                .insert(Insert(post_id: postId, user_id: u.id, body: body)) // ✅
                .execute()

            await loadInitial()
        } catch {
            self.error = (error as NSError).localizedDescription
        }
    }


    func delete(_ comment: PostComment) async {
        guard comment.canDelete else { return }
        let c = DatabaseManager.shared.client
        do {
            _ = try await c.from("resorts_post_comments")
                .delete()
                .eq("id", value: comment.id)
                .execute()
            items.removeAll { $0.id == comment.id }
        } catch {
            self.error = (error as NSError).localizedDescription
        }
    }

    private func fetchPage(before: Date?, limit: Int) async throws -> [PostComment] {
        struct Row: Decodable {
                let id: UUID
                let created_at: Date
                let body: String
                // ⛳️ 改这里：author_id -> user_id
                let user_id: UUID?
                let author_name: String?
                let author_avatar_url: String?
            }

        let c = DatabaseManager.shared.client
        var q = c.from("resorts_post_comments_feed")
            .select()
            .eq("post_id", value: postId)

        if let ts = before {
            let iso = iso8601ms.string(from: ts)
            q = q.lt("created_at", value: iso)
        }

        let rows: [Row] = try await q
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return rows.map { r in
                PostComment(
                    id: r.id,
                    createdAt: r.created_at,
                    body: r.body,
                    userId: r.user_id,                          // ⛳️
                    authorName: r.author_name ?? "匿名",
                    authorAvatarURL: URL(string: r.author_avatar_url ?? ""),
                    canDelete: (r.user_id != nil && r.user_id == currentUserId) // ⛳️
                )
            }
    }
}

/// 小红书风的评论列表（可内联发送）
struct CommentsListView: View {
    @StateObject private var vm: CommentsVM
    @State private var input = ""
    @State private var sending = false

    init(postId: UUID) {
        _vm = StateObject(wrappedValue: CommentsVM(postId: postId))
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(vm.items) { c in
                    CommentRow(c: c, onDelete: {
                        Task { await vm.delete(c) }
                    })
                    .listRowSeparator(.hidden)
                }

                if vm.isPaginating {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .listRowSeparator(.hidden)
                } else if !vm.reachedEnd {
                    Color.clear
                        .frame(height: 1)
                        .onAppear { Task { await vm.loadMore() } }
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)

            // 输入区
            HStack(spacing: 8) {
                TextField("写评论…", text: $input, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                Button {
                    guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    let text = input
                    input = ""
                    sending = true
                    Task {
                        await vm.add(body: text)
                        sending = false
                    }
                } label: {
                    if sending { ProgressView().scaleEffect(0.8) }
                    else { Text("发送").bold() }
                }
                .disabled(sending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
        .navigationTitle("评论")
        .task { await vm.loadInitial() }
        .alert("出错了", isPresented: Binding(
            get: { vm.error != nil },
            set: { _ in vm.error = nil }
        )) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(vm.error ?? "")
        }
    }
}

private struct CommentRow: View {
    let c: PostComment
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: c.authorAvatarURL) { phase in
                switch phase {
                case .success(let img): img.resizable()
                default: Circle().fill(Color(.tertiarySystemFill))
                }
            }
            .scaledToFill()
            .frame(width: 34, height: 34)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(c.authorName).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(RelativeDateTimeFormatter().localizedString(for: c.createdAt, relativeTo: Date()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(c.body).font(.body)
            }
        }
        .padding(.vertical, 8)
        .swipeActions {
            if let onDelete {
                Button("删除", role: .destructive) { onDelete() }
            }
        }
    }
}
