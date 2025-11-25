//
//  FindCoachView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/7/6.
//

import SwiftUI

struct FindCoachView: View {
    @State private var selectedResortId: Int? = nil // 选中的雪场 ID
    @State private var coachType = "单板" // 选中的教雪类型
    @State private var isSheetPresented = false // 控制 sheet 的状态
    @State private var resortsData: [Resorts_data] = [] // 雪场数据
    @State private var searchText: String = "" // 搜索文本
    let wechatID = "雪兔滑行" // 微信账号

    var body: some View {
        NavigationStack {
            VStack {
                // 筛选区域
                HStack {
                    Text("筛选:")
                        .foregroundStyle(Color.black)
                    
                    // 雪场选择器
                    Picker("雪场", selection: $selectedResortId) {
                        ForEach(resortsData, id: \.id) { resort in
                            Text(resort.name_resort).tag(resort.id as Int?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .overlay(
                        NavigationLink(destination: ResortListView(resortsData: resortsData, selectedResortId: $selectedResortId, searchText: $searchText)) {
                            EmptyView()
                        }
                        .opacity(0)
                    )
                    
                    Text("类型:")
                        .foregroundStyle(Color.black)
                    // 教雪类型选择器
                    Picker("教雪类型", selection: $coachType) {
                        Text("单板").tag("单板")
                        Text("双板").tag("双板")
                    }
                }
                .padding(.horizontal,60)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

                // 成为教练按钮
                HStack {
                    HStack {
                        Image(systemName: "plus.app")
                        Text("成为教练")
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 136)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .onTapGesture {
                        isSheetPresented = true // 显示微信提示 sheet
                    }
                }
                .sheet(isPresented: $isSheetPresented) {
                    VStack {
                        Spacer()
                        HStack {
                            Text("添加微信服务号: \(wechatID)")
                                .font(.title)
                                .padding()

                            Button(action: {
                                UIPasteboard.general.string = wechatID // 复制微信账号
                            }) {
                                Text("复制名称")
                            }
                            .padding(.trailing)
                        }
                        Spacer()
                        Button("关闭") {
                            isSheetPresented = false
                        }
                        .padding()
                    }
                }

                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("找教练")
            .onAppear(perform: fetchResorts) // 页面加载时获取雪场数据
        }
    }

    // 获取雪场数据
    func fetchResorts() {
        if let cachedData = UserDefaults.standard.data(forKey: "cachedResorts") {
            do {
                // 从缓存中加载数据
                let decodedData = try JSONDecoder().decode([Resorts_data].self, from: cachedData)
                resortsData = decodedData
            } catch {
                print("Error decoding cached data: \(error)")
            }
        } else {
            Task {
                do {
                    // 从 Supabase 获取数据
                    let manager = DatabaseManager.shared
                    let fetchedData: [Resorts_data] = try await manager.client
                        .from("Resorts_data")
                        .select()
                        .execute()
                        .value

                    // 缓存数据到 UserDefaults
                    if let encodedData = try? JSONEncoder().encode(fetchedData) {
                        UserDefaults.standard.set(encodedData, forKey: "cachedResorts")
                    }

                    // 更新界面显示
                    resortsData = fetchedData

                } catch {
                    print("Error fetching resorts data: \(error)")
                }
            }
        }
    }
}

// 雪场列表视图
struct ResortListView: View {
    var resortsData: [Resorts_data]
    @Binding var selectedResortId: Int?
    @Binding var searchText: String

    var body: some View {
        List {
            ForEach(filteredResorts, id: \.id) { resort in
                HStack {
                    Text(resort.name_resort)
                    Spacer()
                    if selectedResortId == resort.id {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedResortId = resort.id
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("选择雪场")
    }

    // 过滤后的雪场数据
    var filteredResorts: [Resorts_data] {
        if searchText.isEmpty {
            return resortsData
        } else {
            return resortsData.filter { $0.name_resort.localizedCaseInsensitiveContains(searchText) }
        }
    }
}


#Preview {
    FindCoachView()
}













/*
import SwiftUI

struct FindCoachView: View {
    @State private var favoriteAnimal = "模拟雪场1"
    @State private var coachtype = "单板"
    @State private var isSheetPresented = false // 控制 sheet 的状态
    let wechatID = "Gosnow_coach" // 微信账号
    var body: some View {
        
        NavigationStack {
            VStack {
                HStack{
                    Text("筛选:")
                        .foregroundStyle(Color.black)
                    Picker("教学雪场", selection: $favoriteAnimal) {
                          Text("模拟雪场1").tag("模拟雪场1")
                          Text("模拟雪场2").tag("模拟雪场2")
                          Text("模拟雪场3").tag("模拟雪场3")
                    }
                    
                    Picker("教雪类型", selection: $coachtype) {
                          Text("单板").tag("单板")
                          Text("双板").tag("双板")
                    }
                }
                .padding(.horizontal, 60)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(10)
                
                HStack {
                            HStack {
                                Image(systemName: "plus.app")
                                Text("成为教练")
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 136)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .onTapGesture {
                                isSheetPresented = true // 点击时显示 sheet
                            }
                        }
                .sheet(isPresented: $isSheetPresented) {
                            
                            VStack {
                                Spacer()
                                HStack {
                                    Text("请添加微信: \(wechatID)")
                                        .font(.title)
                                        .padding()

                                    Button(action: {
                                        // 复制微信账号到剪贴板
                                        UIPasteboard.general.string = wechatID
                                    }) {
                                        Text("复制账号")
                                    }
                                    .padding(.trailing)
                                }
                                Spacer()
                                Button("关闭") {
                                    isSheetPresented = false
                                }
                                .padding()
                            }
                        }
                        .navigationTitle("找教练")
                    
                    
                }
                //.shadow(radius: 5)
                
                Spacer()

                
            }
            .navigationTitle("找教练")
                
        }
    }


#Preview {
    FindCoachView()
}
*/
