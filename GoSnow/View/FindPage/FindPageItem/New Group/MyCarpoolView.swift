//
//  MyCarpoolView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/11/7.
//

import SwiftUI
import Supabase

struct MyCarpoolView: View {
    @State private var items: [CarpoolPost] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        List {
            Section {
                if isLoading && items.isEmpty {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else if let e = error {
                    Text("加载失败：\(e)").foregroundStyle(.red)
                } else if items.isEmpty {
                    Text("你还没有发布顺风车").foregroundStyle(.secondary)
                } else {
                    ForEach(items) { p in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(dateText(p.depart_at)).font(.headline)
                                Spacer()
                                if p.is_hidden { Text("已取消").font(.caption).foregroundStyle(.secondary) }
                            }
                            Text("雪场ID：\(p.resort_id)").foregroundStyle(.secondary)
                            if let o = p.origin_text, !o.isEmpty { Text("出发地：\(o)") }
                            if let n = p.note, !n.isEmpty { Text(n).lineLimit(2) }
                        }
                        .swipeActions(edge: .trailing) {
                            if p.is_hidden {
                                Button {
                                    Task { try? await CarpoolAPI.restorePost(id: p.id); await reload() }
                                } label: {
                                    Label("恢复", systemImage: "arrow.uturn.backward.circle")
                                }
                            } else {
                                Button(role: .destructive) {
                                    Task { try? await CarpoolAPI.cancelPost(id: p.id); await reload() }
                                } label: {
                                    Label("取消", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            } footer: {
                Text("左滑可\(Text("删除").bold())")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("我的顺风车")
        .refreshable { await reload() }
        .task { await reload() }
    }

    private func reload() async {
        isLoading = true; defer { isLoading = false }
        do { items = try await CarpoolAPI.fetchMyPosts() }
        catch { self.error = (error as NSError).localizedDescription }
    }

    private func dateText(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "M/d HH:mm"; f.locale = Locale(identifier: "zh_CN")
        return f.string(from: d)
    }
}
