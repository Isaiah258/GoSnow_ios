//
//  Sheet1View.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/18.
//

import SwiftUI
import Supabase

struct Sheet1View: View {
    @State private var SnowOfToday: String = "机压雪"
    let manager: DatabaseManager = DatabaseManager.shared  // 使用 your DatabaseManager
    var resortId: Int  // 接收来自 ChartsOfSnowView 的雪场 ID

    var body: some View {
        VStack {
            HStack {
                Text("今日雪质情况")
                
                Picker("请选择", selection: $SnowOfToday) {
                    Text("机压雪").tag("机压雪")
                    Text("烂雪").tag("烂雪")
                    Text("多冰").tag("多冰")
                    Text("湿雪").tag("湿雪")
                    Text("粉雪").tag("粉雪")
                }
                .pickerStyle(.menu)
            }
            .padding()

            Button(action: {
                uploadSnowCondition()
            }) {
                Text("上传雪况")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200) // 使按钮宽度自适应父视图
                    .background(Color.blue) // 设置按钮背景颜色
                    .cornerRadius(10) // 设置圆角
                    .shadow(radius: 5) // 添加阴影
            }
            .padding()
        }
    }

    // 上传雪况的方法
    func uploadSnowCondition() {
        Task {
            do {
                // 创建一个 DailySnowConditions 实例
                let dailySnowCondition = DailySnowConditions(
                    id: 0,  // Supabase 将自动生成 ID
                    resort_id: resortId,  // 使用传递的雪场 ID
                    date: Date(), // 使用当前日期
                    condition: SnowOfToday,
                    created_at: nil  // `created_at` 可以留为 nil，Supabase 会处理
                )

                // 插入雪况到 DailySnowConditions 表
                let response = try await manager.client.from("DailySnowConditions").upsert(dailySnowCondition).execute()
                print("雪况上传成功: \(response)")
            } catch {
                print("上传失败: \(error.localizedDescription)")
            }
        }
    }
}







#Preview {
    Sheet1View(resortId: 2)
}
