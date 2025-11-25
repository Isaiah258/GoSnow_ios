//
//  CarpoolViews.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/11/5.
//

import SwiftUI
import Supabase

struct CarpoolRow: Decodable, Identifiable {
    let id: UUID
    let resort_id: Int
    let depart_at: Date
    let origin_text: String?
    let note: String?
}

struct CarpoolView: View {
    @State private var resorts: [Resorts_data] = []
    @State private var selectedResortId: Int? = nil
    @State private var selectedDate = Date()

    @State private var items: [CarpoolRow] = []
    @State private var isLoading = false
    @State private var fetchError: Error?
    @State private var page = 0
    private let pageSize = 10
    @State private var hasMore = true

    @State private var showResortPicker = false
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()

                VStack(spacing: 10) {
                    // 顶部筛选：雪场 + 日期（无全局搜索）
                    HStack(spacing: 10) {
                        Button { openResortPicker() } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "car.fill")
                                    Text(selectedResortName ?? "所有雪场").lineLimit(1)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(
                                    Capsule().strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                        Spacer()

                        DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .onChange(of: selectedDate) { _, _ in
                                Task { await resetAndFetch() }
                            }
                    }
                    .padding(.horizontal)

                    // 列表
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            if isLoading && items.isEmpty {
                                VStack { ProgressView().padding(.vertical, 24) }
                                    .frame(maxWidth: .infinity)
                            } else if let err = fetchError, items.isEmpty {
                                Text("加载失败：\(err.localizedDescription)")
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 24)
                                    .frame(maxWidth: .infinity)
                            } else if items.isEmpty {
                                Text("暂无顺风车信息")
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 24)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ForEach(items) { item in
                                    CarpoolCard(
                                        item: item,
                                        resortName: resortName(for: item.resort_id)
                                    )
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                }

                                if hasMore {
                                    HStack { Spacer(); ProgressView(); Spacer() }
                                        .padding(.vertical, 16)
                                        .task { await loadNextPage() }
                                }
                            }

                            Spacer(minLength: 8)
                        }
                    }
                    .scrollIndicators(.hidden)
                    .refreshable { await resetAndFetch() }
                }
            }
            .navigationTitle("顺风车")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink { MyCarpoolView() } label: {
                        Image(systemName: "note.text") // “我的”样式图标
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }

            .sheet(isPresented: $showResortPicker) {
                ResortPickerSheet(
                    resorts: resorts,
                    selectedResortId: $selectedResortId
                ) {
                    Task { await resetAndFetch() }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddCarpoolView(onPublished: {
                    showAddSheet = false
                    Task { await resetAndFetch() }
                })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .task {
                await loadResortsIfNeeded()
                await resetAndFetch()
            }
        }
    }

    // MARK: - Helpers
    private func openResortPicker() {
        Task {
            if resorts.isEmpty {
                do {
                    resorts = try await CarpoolAPI.fetchAllResorts()  // ✅ 复用 API
                } catch {
                    fetchError = error
                    return
                }
            }
            showResortPicker = true
        }
    }
    
    
    private var selectedResortName: String? {
        guard let id = selectedResortId else { return nil }
        return resorts.first(where: { $0.id == id })?.name_resort
    }

    private func resortName(for id: Int) -> String? {
        resorts.first(where: { $0.id == id })?.name_resort   // ✅ 不用再 Int(...) 转换
    }


    private func loadResortsIfNeeded() async {
        guard resorts.isEmpty else { return }
        do {
            resorts = try await CarpoolAPI.fetchAllResorts()          // ✅ 复用 API
        } catch {
            print("❌ 获取雪场失败：\(error)")
        }
    }

    private func resetAndFetch() async {
        page = 0
        hasMore = true
        items.removeAll()
        await loadNextPage()
    }

    private func loadNextPage() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            var q = DatabaseManager.shared.client
                .from("carpool_posts")
                .select("id,resort_id,depart_at,origin_text,note,is_hidden,canceled_at") // 👈 多取两列以便前端判断

            // 只看未取消/未隐藏
            q = q.eq("is_hidden", value: false)
                 .is("canceled_at", value: nil)

            // 雪场筛选
            if let rid = selectedResortId {
                q = q.eq("resort_id", value: rid)
            }

           

            // 分页
            let from = page * pageSize
            let to = from + pageSize - 1

            let pageItems: [CarpoolRow] = try await q
                .order("depart_at", ascending: true)
                .range(from: from, to: to)
                .execute()
                .value

            items.append(contentsOf: pageItems)
            hasMore = pageItems.count == pageSize
            if hasMore { page += 1 }
        } catch {
            fetchError = error
            hasMore = false
        }
    }

}

// 卡片
private struct CarpoolCard: View {
    let item: CarpoolRow
    let resortName: String?

    @State private var copied = false
    private let labelWidth: CGFloat = 96 // 左列固定宽度，保证“出发地：/目的地雪场：”起始对齐

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // 顶部：日期 + 时间
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(dateAndTime(item.depart_at))        // 例如 11/08 10:18
                    .font(.headline).fontWeight(.semibold)
                Spacer()
            }

            // 行2：出发地（左对齐，和下行“目的地雪场”对齐）
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("出发地：")
                    .foregroundStyle(.secondary)
                    .frame(width: labelWidth, alignment: .leading) // ✅ 左列左对齐且等宽
                Text(item.origin_text?.isEmpty == false ? item.origin_text! : "未填写")
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // 行3：目的地雪场（左对齐，与上行对齐）
            if let r = resortName {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("目的地雪场：")
                        .foregroundStyle(.secondary)
                        .frame(width: labelWidth, alignment: .leading) // ✅ 同宽左对齐
                    Text(r)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            // 行4：备注 + 复制微信（若能识别）
            if let t = item.note, !t.isEmpty {
                Text(t).font(.subheadline)

                if let wx = t.extractedWeChatID {
                    Button {
                        UIPasteboard.general.string = wx
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
                    } label: {
                        Label(copied ? "已复制微信" : "复制微信：\(wx)",
                              systemImage: copied ? "checkmark.circle" : "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            }

            // 底部分割线
            Divider().padding(.top, 10)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    private func dateAndTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "MM/dd HH:mm"
        return f.string(from: d)
    }
}






private extension String {
    var extractedWeChatID: String? {
        let patterns = [
            #"(?i)(微信|wechat|wx)\s*[:：]\s*([a-zA-Z0-9_-]{3,})"#,
            #"(?i)\bwx(?:id)?\b\s*[:：]?\s*([a-zA-Z0-9_-]{3,})"#
        ]
        for p in patterns {
            if let r = self.range(of: p, options: .regularExpression) {
                let sub = String(self[r])
                if let idr = sub.range(of: #"([a-zA-Z0-9_-]{3,})$"#, options: .regularExpression) {
                    return String(sub[idr])
                }
            }
        }
        return nil
    }
}
