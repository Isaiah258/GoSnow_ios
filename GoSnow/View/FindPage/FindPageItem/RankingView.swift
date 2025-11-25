//
//  RankingView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/7/6.
//


import SwiftUI

struct RankingView: View {
    @State private var selectedSegment = 0 // 默认选择 "好友" 排行榜
    
    var body: some View {
        NavigationStack { // 包裹在 NavigationView 中
            VStack { // 垂直排列
                Picker("Leaderboard", selection: $selectedSegment) { // 分段控制器
                    Text("好友").tag(0)
                    Text("总排行榜").tag(1)
                }
                .pickerStyle(.segmented) // 分段样式
                .padding()
                
                ScrollView { // 可滚动区域
                    LazyVStack(spacing: 15) { // 延迟加载垂直列表
                        ForEach(0..<10) { index in // 示例数据，显示 10 个条目
                            RankingRow(rank: index + 1, name: "用户 \(index + 1)", score: Int.random(in: 100...1000))
                        }
                    }
                    .padding(.horizontal) // 左右内边距
                }
            }
            .navigationTitle("排行榜") // 导航栏标题
        }
    }
}

struct RankingRow: View {
    let rank: Int
    let name: String
    let score: Int

    var body: some View {
        HStack {
            Text("\(rank).") // 排名
                .font(.headline)
                .frame(width: 30, alignment: .leading) // 固定宽度，左对齐
            
            Image(systemName: "person.circle.fill") // 头像占位符
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading) { // 用户名和分数
                Text(name)
                    .font(.headline)
                Text("\(score) Km") // 分数
            }
            Spacer() // 填充剩余空间
        }
        .padding(.vertical, 8) // 上下内边距
    }
}


#Preview {
    RankingView()
}
