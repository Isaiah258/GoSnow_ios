//
//  LostAndFoundView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/7/11.
//

import SwiftUI
import Supabase

struct LostAndFoundView: View {
    @State private var resorts: [Resorts_data] = []
    @State private var selectedResortId: Int? = nil
    @State private var selectedDate = Date()
    @State private var searchText = ""

    @State private var items: [LostAndFoundItems] = []
    @State private var isLoading = false
    @State private var fetchError: Error?
    @State private var page = 0
    private let pageSize = 10
    @State private var hasMore = true

    @State private var showResortPicker = false

    // ✅ 新增：控制 AddItemView 的弹窗
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()

                VStack(spacing: 10) {
                    // 顶部筛选
                    HStack(spacing: 10) {
                        Button {
                            showResortPicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "mountain.2.fill")
                                Text(selectedResortName ?? "所有雪场")
                                    .lineLimit(1)
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
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
                                Text("没有找到相关物品")
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 24)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ForEach(items) { item in
                                    LostAndFoundCard(
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
                    .refreshable {
                        await resetAndFetch()
                    }
                    .searchable(text: $searchText, prompt: "按描述搜索")
                    .onChange(of: searchText) { _, _ in
                        Task { await resetAndFetch() }
                    }
                }
            }
            .navigationTitle("失物招领")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // ✅ 点加号 -> 打开发布页
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
            // ✅ 弹出 AddItemView，发布成功 -> 关闭并刷新
            .sheet(isPresented: $showAddSheet) {
                AddItemView(onPublished: {
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

    private var selectedResortName: String? {
        guard let id = selectedResortId else { return nil }
        return resorts.first(where: { $0.id == id })?.name_resort
    }

    private func resortName(for id: Int) -> String? {
        resorts.first(where: { $0.id == id })?.name_resort
    }

    private func loadResortsIfNeeded() async {
        guard resorts.isEmpty else { return }
        do {
            resorts = try await DatabaseManager.shared.client
                .from("Resorts_data")
                .select()
                .order("name_resort", ascending: true)
                .execute()
                .value
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
                .from("LostAndFoundItems")
                .select()

            if let rid = selectedResortId {
                q = q.eq("resort_id", value: rid)
            }

            let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !keyword.isEmpty {
                q = q.ilike("item_description", pattern: "%\(keyword)%")
            }

            // 日期范围（当天）
            let cal = Calendar.current
            let startOfDay = cal.startOfDay(for: selectedDate)
            let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay)!
            let iso = ISO8601DateFormatter()
            q = q.gte("created_at", value: iso.string(from: startOfDay))
                 .lt("created_at", value: iso.string(from: endOfDay))

            let from = page * pageSize
            let to = from + pageSize - 1

            let pageItems: [LostAndFoundItems] = try await q
                .order("created_at", ascending: false)
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

#Preview {
    LostAndFoundView()
}










/*
 import SwiftUI
 import Supabase

 struct LostAndFoundView: View {
     @State var allItems: [LostAndFoundItems] = []
     @State private var searchText = ""
     @State private var selectedResortId: Int? = nil {
         didSet {
             fetchFilteredLostAndFoundItems() // 雪场变化时重新获取数据
         }
     }
     @State private var isAddingItem = false
     @State var resorts_data: [Resorts_data] = []
     @State private var displayedItems: [LostAndFoundItems] = []
     @State private var selectedDate = Date()
         
     @State private var isLoading = false
     @State private var fetchError: Error? // 用于存储错误信息
     let pageSize = 10

     var body: some View {
         NavigationStack {
             VStack {
                 Picker("选择雪场", selection: $selectedResortId) {
                     Text("所有雪场").tag(nil as Int?)
                     ForEach(resorts_data, id: \.id) { resort in
                         Text(resort.name_resort).tag(resort.id as Int?)
                     }
                 }
                 .pickerStyle(.navigationLink)
                 .padding(.horizontal)
                 .foregroundStyle(Color.black)

                 DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                     .padding(.horizontal)
                     .onChange(of: selectedDate) {  // 使用 onChange 监听日期变化
                         fetchFilteredLostAndFoundItems()
                     }

                 List {
                     if isLoading {
                         ProgressView() // 加载中显示进度条
                     } else if let error = fetchError {
                         Text("加载失败：\(error.localizedDescription)") // 显示错误信息
                             .foregroundColor(.red)
                     } else if displayedItems.isEmpty {
                         Text("没有找到相关物品")
                             .foregroundColor(.gray)
                     } else {
                         ForEach(displayedItems) { item in
                             LostAndFoundCard(item: item)
                                 .padding(.vertical, 5)
                                 .background(Color.white)
                                 .cornerRadius(10)
                                 .shadow(radius: 3)
                         }

                         if displayedItems.count < allItems.count { // 加载更多逻辑（需要根据实际情况调整）
                             HStack {
                                 Spacer()
                                 ProgressView()
                                 Spacer()
                             }
                             .onAppear {
                                 loadMoreItems()
                             }
                         }
                     }
                 }
                 .listStyle(.plain)
             }
             .navigationTitle("失物招领")
             .toolbar {
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button(action: {
                         isAddingItem = true
                     }) {
                         Image(systemName: "plus")
                     }
                 }
             }
             .onAppear {
                 fetchResorts()
                 fetchFilteredLostAndFoundItems() // 初始加载也调用 fetchFilteredLostAndFoundItems
             }
             .sheet(isPresented: $isAddingItem) {
                 AddItemView()
             }
         }
     }

     func loadMoreItems() {
         guard !isLoading else { return }

         isLoading = true
         DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // 模拟网络延迟
             let startIndex = displayedItems.count
             let endIndex = min(startIndex + pageSize, allItems.count)

             if startIndex < endIndex {
                 displayedItems.append(contentsOf: allItems[startIndex..<endIndex])
             }
             isLoading = false
         }
     }

     func fetchResorts() {
         Task {
             do {
                 let manager = DatabaseManager.shared
                 resorts_data = try await manager.client.from("Resorts_data").select().execute().value
             } catch {
                 print("Error fetching resorts data: \(error)")
                 fetchError = error // 记录错误
             }
         }
     }

     func fetchFilteredLostAndFoundItems() {
         isLoading = true
         fetchError = nil // 清除之前的错误

         Task {
             do {
                 let manager = DatabaseManager.shared
                 var query = manager.client.from("LostAndFoundItems").select()

                 if let resortId = selectedResortId {
                     query = query.eq("resort_id", value: resortId)
                 }
                 if !searchText.isEmpty {
                     query = query.ilike("item_description", pattern: "%\(searchText)%")
                 }

                 // 日期筛选使用更精确的范围查询
                 let startOfDay = Calendar.current.startOfDay(for: selectedDate)
                 let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
                 let dateFormatter = ISO8601DateFormatter()

                 query = query.gte("created_at", value: dateFormatter.string(from: startOfDay))
                 query = query.lt("created_at", value: dateFormatter.string(from: endOfDay))


                 let items: [LostAndFoundItems] = try await query.execute().value
                 allItems = items // 更新 allItems
                 displayedItems = Array(items.prefix(pageSize))

             } catch {
                 print("Error fetching filtered items: \(error)")
                 fetchError = error // 记录错误
                 displayedItems = []
             }
             isLoading = false
         }
     }
 }


 #Preview {
     LostAndFoundView()
 }
 
 
 
 
 */







