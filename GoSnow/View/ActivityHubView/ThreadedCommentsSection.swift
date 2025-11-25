//
//  ThreadedCommentsSection.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/28.
//

import SwiftUI

struct ThreadedCommentsSection: View {
    @StateObject private var vm: TwoLevelCommentsVM
    @State private var replyText: String = ""
    @FocusState private var replyFocused: Bool

    // 哪些根评论已展开全部回复（默认只显示第一条）
    @State private var expandedRoots: Set<UUID> = []

    // 删除 / 举报 的目标
    @State private var deleteTarget: TwoLevelCommentsVM.Comment? = nil
    @State private var reportTarget: TwoLevelCommentsVM.Comment? = nil

    init(postId: UUID) {
        _vm = StateObject(wrappedValue: TwoLevelCommentsVM(postId: postId))
    }

    private func dismissReply() {
        replyFocused = false
        if replyText.isEmpty { vm.replyTarget = nil }
        // 兜底，把第一响应者收起
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // 顶部：标题 + 排序切换（小字）
                    HStack {
                        Text("评论").font(.title3.bold())
                        Spacer()
                        Button {
                            vm.sort = (vm.sort == .hot ? .newest : .hot)
                            Task { await vm.reload() }
                        } label: {
                            Text(vm.sort == .hot ? "按热度排序 ⇅" : "按时间排序 ⇅")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    if vm.isLoading {
                        ProgressView().padding(.top, 6)
                    } else if vm.roots.isEmpty {
                        Text("暂无评论")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                    } else {
                        ForEach(vm.roots) { root in
                            VStack(alignment: .leading, spacing: 10) {
                                // 根评论
                                CommentRow(
                                    c: root,
                                    isChild: false,
                                    canDelete: (vm.currentUserId == root.authorId),
                                    onReply: {
                                        vm.replyTarget = root             // 两层压扁：回复都归根
                                        replyFocused = true               // 直接聚焦 -> 弹出键盘
                                    },
                                    onLike: { Task { await vm.toggleLike(for: root) } },
                                    onDelete: {
                                        deleteTarget = root
                                    },
                                    onReport: {
                                        reportTarget = root
                                    }
                                )

                                // 二级回复区（默认只展示第一条，支持展开/收起）
                                if let allReplies = vm.children[root.id], !allReplies.isEmpty {
                                    let showAll = expandedRoots.contains(root.id)
                                    let toShow = showAll ? allReplies : [allReplies[0]]

                                    VStack(alignment: .leading, spacing: 10) {
                                        ForEach(toShow) { r in
                                            CommentRow(
                                                c: r,
                                                isChild: true,
                                                canDelete: (vm.currentUserId == r.authorId),
                                                onReply: {
                                                    // 两层压扁：对回复再回复，仍回复到根
                                                    vm.replyTarget = r
                                                    replyFocused = true
                                                },
                                                onLike: {
                                                    Task { await vm.toggleLike(for: r) }
                                                },
                                                onDelete: {
                                                    deleteTarget = r
                                                },
                                                onReport: {
                                                    reportTarget = r
                                                }
                                            )
                                        }

                                        // 展开/收起按钮
                                        if allReplies.count > 1 {
                                            Button {
                                                if showAll {
                                                    expandedRoots.remove(root.id)
                                                } else {
                                                    expandedRoots.insert(root.id)
                                                }
                                            } label: {
                                                Text(showAll
                                                     ? "收起回复"
                                                     : "展开 \(allReplies.count - 1) 条回复")
                                                .font(.footnote.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            }
                                            .buttonStyle(.plain)
                                            .padding(.top, 2)
                                        }
                                    }
                                    .padding(.leading, 44) // 缩进以示层级
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .id(root.id)

                            Divider().padding(.leading, 20)
                        }

                        // 锚点：供发送后滚动到底使用
                        Color.clear.frame(height: 1).id("list-bottom")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {                      // 点空白收起键盘/退出回复模式
                    replyFocused = false
                    if replyText.isEmpty { vm.replyTarget = nil }
                }
            }
            .scrollDismissesKeyboard(.interactively)  // 滚动可收起键盘
            .task { await vm.reload() }
            .onChange(of: vm.sort) { _, _ in expandedRoots.removeAll() }
            .safeAreaInset(edge: .bottom) {
                // 仅在“正在回复”时显示底部输入条（会自动顶在键盘上方）
                if let target = vm.replyTarget {
                    ReplyComposerBar(
                        replyingTo: target.authorName,
                        text: $replyText,
                        isFocused: $replyFocused,
                        onCancel: {
                            vm.replyTarget = nil
                            replyText = ""
                            replyFocused = false
                        },
                        onSend: {
                            let t = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            let toSend = t
                            replyText = ""
                            Task {
                                await vm.send(text: toSend)           // VM 内部有乐观插入
                                withAnimation {
                                    proxy.scrollTo("list-bottom", anchor: .bottom)
                                }
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.9), value: vm.replyTarget != nil)
                    .background(.ultraThinMaterial)
                    .overlay(Divider(), alignment: .top)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .simultaneousGesture(
                DragGesture(minimumDistance: 4).onChanged { _ in dismissReply() }
            )
            .contentShape(Rectangle())
            .onTapGesture { dismissReply() }

            // 删除确认
            .confirmationDialog(
                "确认删除这条评论？",
                isPresented: Binding(
                    get: { deleteTarget != nil },
                    set: { if !$0 { deleteTarget = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let target = deleteTarget {
                    Button("删除", role: .destructive) {
                        Task {
                            await vm.delete(comment: target)
                            deleteTarget = nil
                        }
                    }
                }
                Button("取消", role: .cancel) {
                    deleteTarget = nil
                }
            }

            // 举报确认
            .confirmationDialog(
                "举报评论",
                isPresented: Binding(
                    get: { reportTarget != nil },
                    set: { if !$0 { reportTarget = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let target = reportTarget {
                    Button("确认举报", role: .destructive) {
                        Task {
                            await vm.report(comment: target)
                            reportTarget = nil
                        }
                    }
                }
                Button("取消", role: .cancel) {
                    reportTarget = nil
                }
            }

            // 错误弹窗
            .alert("出错了", isPresented: Binding(
                get: { vm.lastError != nil },
                set: { _ in vm.lastError = nil }
            )) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(vm.lastError ?? "")
            }
        }
    }
}

// 小红书式单条评论
private struct CommentRow: View {
    let c: TwoLevelCommentsVM.Comment
    var isChild: Bool
    var canDelete: Bool
    var onReply: () -> Void
    var onLike: () -> Void
    var onDelete: () -> Void
    var onReport: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 头像
            AsyncImage(url: c.authorAvatarURL) { phase in
                switch phase {
                case .success(let img): img.resizable()
                default: Circle().fill(Color(.tertiarySystemFill))
                }
            }
            .frame(width: isChild ? 28 : 32, height: isChild ? 28 : 32)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                // 昵称 + 右上角菜单
                HStack(alignment: .firstTextBaseline) {
                    Text(c.authorName)
                        .font(isChild ? .callout.weight(.semibold) : .subheadline.weight(.semibold))

                    Spacer()

                    Menu {
                        // 所有人都有举报
                        Button("举报", role: .destructive) {
                            onReport()
                        }
                        // 自己的评论才有删除
                        if canDelete {
                            Button("删除", role: .destructive) {
                                onDelete()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .contentShape(Rectangle())
                    }
                }

                // 正文
                Text(c.body)
                    .font(isChild ? .callout : .subheadline)

                // 底部工具条：左侧时间+回复，右侧点赞（红心 + 数字更近）
                HStack {
                    HStack(spacing: 14) {
                        Text(RelativeDateTimeFormatter().localizedString(for: c.createdAt, relativeTo: .init()))
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Button(action: onReply) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left")
                                Text("回复")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Button(action: onLike) {
                        HStack(spacing: 6) {
                            Image(systemName: c.isLikedByMe ? "heart.fill" : "heart")
                                .foregroundStyle(c.isLikedByMe ? .red : .secondary)
                                .font(.system(size: 14, weight: .semibold))
                                .symbolEffect(.bounce, value: c.isLikedByMe)  // iOS 17 动效
                            Text("\(c.likeCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            }
        }
    }
}

// 底部固定输入条（贴着键盘，上方有分割线）
private struct ReplyComposerBar: View {
    let replyingTo: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var onCancel: () -> Void
    var onSend: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            // 顶部“正在回复 xxx”
            HStack(spacing: 8) {
                Text("回复 \(replyingTo)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("取消") { onCancel() }
                    .font(.caption)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // 文本框 + 发送
            HStack(spacing: 10) {
                TextField("写点什么…", text: $text, axis: .vertical)
                    .focused($isFocused)
                    .lineLimit(1...4)
                    .textInputAutocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                    )

                Button("发送") { onSend() }
                    .font(.body.weight(.semibold))
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(edges: .bottom)   // 自动顶在键盘上方
        .task { isFocused = true }         // 弹出即聚焦
    }
}






