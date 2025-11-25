//
//  ResortsView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/6/18.
//

import SwiftUI
import Supabase

// MARK: - 入口页面：雪场列表（支持搜索 + 分页）
struct ResortsView: View {
    @StateObject private var vm = ResortsVM()
    @State private var query: String = ""
    @FocusState private var searchFocused: Bool
    @State private var path = NavigationPath()   // 确保从本页 push，返回回到本页
    // 1) 焦点绑定（已有可跳过）
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 10) {
                // 搜索框（无页内大标题）
                SearchField(text: $query,
                            placeholder: "搜索雪场",
                            isFocused: $searchFocused) {
                    Task { await vm.refresh(keyword: query) }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                // 你的 View 里，和 SearchField 同一层级（能共享到同一个环境）

                contentList
                // 2) 你的根视图（ScrollView 或 List 外层）增加这些修饰符
                .scrollDismissesKeyboard(.interactively)                    // 下拉/滑动收起
                .contentShape(Rectangle())                                   // 让空白区域能响应点击
                .onTapGesture { if searchFocused { searchFocused = false } } // 点空白收起
                .simultaneousGesture(                                        // 滑动任意位置也收起（不拦截子视图手势）
                    DragGesture().onChanged { _ in
                        if searchFocused { searchFocused = false }
                    }
                )

            }
            .navigationTitle("雪场")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemBackground))
            .onChange(of: query) { _, newValue in vm.handleQueryChange(newValue) }
            .task { await vm.loadInitialIfNeeded() }
            // （已移除 refreshable）
            // 详情页导航（从本页 push，返回即回到本页）
            .navigationDestination(for: Int.self) { rid in
                ChartsOfSnowView(resortId: rid)
            }
        }
    }

    @ViewBuilder
    private var contentList: some View {
        if vm.isLoadingInitial {
            List(0..<6, id: \.self) { _ in ResortRowSkeleton() }
            .listStyle(.plain)
        } else if let err = vm.initialError {
            VStack(spacing: 10) {
                Text("加载失败").font(.headline)
                Text(err).font(.subheadline).foregroundStyle(.secondary)
                Button {
                    Task { await vm.refresh(keyword: vm.keyword) }
                } label: { Text("重试").bold() }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 40)
        } else if vm.items.isEmpty {
            VStack(spacing: 8) {
                Text("暂无雪场数据").font(.headline)
                Text("试试修改搜索关键词").font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.top, 40)
        } else {
            List {
                ForEach(vm.items) { r in
                    Button {
                        // 从本页 push 到详情
                        path.append(r.id)
                    } label: {
                        ResortRowView(row: r) // 仅文字，无图片
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if r.id == vm.items.last?.id {
                            Task { await vm.loadMoreIfNeeded() }
                        }
                    }
                }

                if vm.isPaginating {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else if vm.reachedEnd && !vm.items.isEmpty {
                    HStack {
                        Spacer()
                        Text("没有更多了").font(.footnote).foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - 行视图（仅文字，无图片）
private struct ResortRowView: View {
    let row: ResortRow
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(row.name)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
            // 可选：一些基础信息（没有就不显示）
            HStack(spacing: 12) {
                if let lift = row.liftCount, lift > 0 {
                    label("缆车", "\(lift)")
                }
                if let trail = row.trailCount, trail > 0 {
                    label("雪道", "\(trail)")
                }
                if let len = row.trailLengthKm, len > 0 {
                    label("总长", String(format: "%.1f km", len))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func label(_ t: String, _ v: String) -> some View {
        HStack(spacing: 4) {
            Text(t)
            Text(v)
        }
    }
}

private struct ResortRowSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle().fill(Color(.tertiarySystemFill)).frame(width: 160, height: 14).cornerRadius(3)
            Rectangle().fill(Color(.tertiarySystemFill)).frame(width: 220, height: 10).cornerRadius(3)
        }
        .padding(.vertical, 10)
        .redacted(reason: .placeholder)
    }
}

// MARK: - VM + 分页
final class ResortsVM: ObservableObject {
    @Published var items: [ResortRow] = []
    @Published var isLoadingInitial = false
    @Published var isPaginating = false
    @Published var reachedEnd = false
    @Published var initialError: String?

    let pageSize = 20
    private(set) var page = 0
    private var loading = false
    private var debounceTask: Task<Void, Never>? = nil

    @Published var keyword: String = ""

    func handleQueryChange(_ text: String) {
        debounceTask?.cancel()
        let key = text.trimmingCharacters(in: .whitespacesAndNewlines)
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            await refresh(keyword: key)
        }
    }

    @MainActor
    func loadInitialIfNeeded() async {
        guard items.isEmpty && !loading else { return }
        await refresh(keyword: keyword)
    }

    @MainActor
    func refresh(keyword: String) async {
        guard !loading else { return }
        loading = true
        isLoadingInitial = true
        initialError = nil
        reachedEnd = false
        page = 0
        self.keyword = keyword
        do {
            let first = try await fetchPage(page: 0, keyword: keyword)
            items = first
            reachedEnd = first.count < pageSize
        } catch {
            initialError = (error as NSError).localizedDescription
            items = []
        }
        isLoadingInitial = false
        loading = false
    }

    @MainActor
    func loadMoreIfNeeded() async {
        guard !loading, !reachedEnd, !isLoadingInitial else { return }
        loading = true
        isPaginating = true
        defer { isPaginating = false; loading = false }
        do {
            page += 1
            let more = try await fetchPage(page: page, keyword: keyword)
            items.append(contentsOf: more)
            if more.count < pageSize { reachedEnd = true }
        } catch {
            // 轻描淡写处理分页错误，不打断已加载的内容
        }
    }

    // 关键：先过滤（.ilike），再排序分页（.order → .range）
    private func fetchPage(page: Int, keyword: String) async throws -> [ResortRow] {
        let c = DatabaseManager.shared.client
        let from = page * pageSize
        let to   = from + pageSize - 1

        struct Row: Decodable {
            let id: Int
            let name_resort: String
            let map_url: String?
            let trail_count: Int?
            let trail_length: Double?
            let lift_count: Int?
            let carpet_count: Int?
            let park: String?
            let night: String?
        }

        var fb: PostgrestFilterBuilder = c
            .from("Resorts_data")
            .select("id,name_resort,map_url,trail_count,trail_length,lift_count,carpet_count,park,night")

        if !keyword.isEmpty {
            fb = fb.ilike("name_resort", pattern: "%\(keyword)%")
        }

        let rows: [Row] = try await fb
            .order("id", ascending: true)
            .range(from: from, to: to)
            .execute()
            .value

        return rows.map {
            ResortRow(
                id: $0.id,
                name: $0.name_resort,
                trailCount: $0.trail_count,
                trailLengthKm: $0.trail_length,
                liftCount: $0.lift_count
            )
        }
    }
}

// MARK: - 模型（列表行）
struct ResortRow: Identifiable, Hashable {
    let id: Int
    let name: String
    let trailCount: Int?
    let trailLengthKm: Double?
    let liftCount: Int?
}

// MARK: - 复用的搜索框（无图片、简洁）
private struct SearchField: View {
    @Binding var text: String
    var placeholder: String = "搜索"
    var isFocused: FocusState<Bool>.Binding
    var onSubmit: () -> Void = {}

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .focused(isFocused)
                .onSubmit { onSubmit() }
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1 / UIScreen.main.scale)
        )
    }
}












/*
 
 import SwiftUI
 import Supabase


 struct ResortsView: View {
     @State private var searchTerm = ""
     @State var resorts_data: [Resorts_data] = []
     
     
     var body: some View {
         NavigationStack {
             ScrollView {
                 VStack {
                     
                     if searchTerm.isEmpty {
                         
                         VStack {
                             HStack {
                                 Text("热门雪场")
                                     .font(.subheadline)
                                     .fontWeight(.bold)
                                     .padding(.leading, 20)
                                     .padding(.top)
                                 Spacer()
                             }
                             
                             ScrollView {
                                 ScrollView(.horizontal, showsIndicators: false){
                                     HStack{
                                         ForEach(resorts) { resorts in
                                             ResortsRowView(resorts: resorts)
                                         }
                                     }
                                 }
                             }
                         }
                     } else {
                         
                         List {
                             ForEach(filteredResorts, id: \.id) { resorts_data in
                                 Text(resorts_data.name_resort)
                             }
                         }
                         .listStyle(.plain)
                     }
                     
                     
                 }
                 .navigationTitle("雪场")
             }
             
         }
         
         .searchable(text: $searchTerm, prompt: "搜索雪场")
         .task {
             do {
             let manager = DatabaseManager.shared
                 resorts_data = try await manager.client.from("Resorts_data").select().execute().value
             } catch {
                 dump(error)
             }
         }
     }
     
     var filteredResorts: [Resorts_data] {
         if searchTerm.isEmpty {
             return resorts_data
         } else {
             return resorts_data.filter {
                 $0.name_resort.localizedCaseInsensitiveContains(searchTerm)
             }
         }
     }
 }
 
 */


/*
 10.7
 import SwiftUI
 import Supabase


 struct ResortsView: View {
     @State private var searchTerm = ""
     @State private var resorts_data: [Resorts_data] = []
     
     var filteredResorts: [Resorts_data] {
         if searchTerm.isEmpty {
             return resorts_data // Return all resorts if there's no search term
         } else {
             return resorts_data.filter { $0.name_resort.contains(searchTerm) } // Filter based on search term
         }
     }
     
     var body: some View {
         NavigationStack {
             List(filteredResorts) { resort in
                 NavigationLink(destination: ChartsOfSnowView(resortId: resort.id)) {
                     HStack {
                         Text(resort.name_resort)
                         Spacer()
                     }
                     .padding(.vertical, 8)
                 }
             }
             .navigationTitle("雪场")
             .searchable(text: $searchTerm, placement: .navigationBarDrawer(displayMode: .always),prompt: "搜索雪场")
             .onAppear(perform: fetchResorts)
         }
     }
     
     func fetchResorts() {
         // Try to load data from UserDefaults first
         if let cachedData = UserDefaults.standard.data(forKey: "cachedResorts") {
             do {
                 // Decode the cached data
                 let decodedData = try JSONDecoder().decode([Resorts_data].self, from: cachedData)
                 resorts_data = decodedData
             } catch {
                 print("Error decoding cached data: \(error)")
             }
         } else {
             // Fetch data from the server if no cached data is available
             Task {
                 do {
                     let manager = DatabaseManager.shared
                     // 确保从服务器获取的数据的结构正确
                     let fetchedData: [Resorts_data] = try await manager.client.from("Resorts_data").select().execute().value
                     
                     // Cache the fetched data
                     if let encodedData = try? JSONEncoder().encode(fetchedData) {
                         UserDefaults.standard.set(encodedData, forKey: "cachedResorts")
                         print("成功缓存数据：\(fetchedData)") // 打印缓存的数据
                     } else {
                         print("Failed to encode fetched data.")
                     }
                     
                     resorts_data = fetchedData
                     
                 } catch {
                     dump(error)
                 }
             }
         }
     }
 }





 #Preview {
     ResortsView()
 }
 */
