//
//  Sheet2View.swift
//  GoSnow
//
//  Created by federico Liu on 2024/10/2.
//

import SwiftUI
import Supabase

struct Sheet2View: View {
    @State private var waitTime: String = "无需等待" // 默认选择
    let manager: DatabaseManager = DatabaseManager.shared // 使用你的 DatabaseManager
    var resortId: Int // 接收来自上层视图的雪场 ID
    @State private var showSuccessAlert = false // 提交成功提示

    var body: some View {
        VStack {
            HStack {
                Text("缆车等待时间")
                
                Picker("请选择", selection: $waitTime) {
                    Text("无需等待").tag("无需等待")
                    Text("短暂等待").tag("短暂等待")
                    Text("较长等待").tag("较长等待")
                }
                .pickerStyle(.menu)
            }
            .padding()

            Button(action: {
                uploadLiftWaitTime()
            }) {
                Text("提交等待时间")
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
        .alert(isPresented: $showSuccessAlert) {
            Alert(
                title: Text("提交成功"),
                message: Text("您的等待时间已成功提交。"),
                dismissButton: .default(Text("确定"))
            )
        }
    }

    // 上传等待时间的方法
    func uploadLiftWaitTime() {
        Task {
            do {
                // 创建一个 LiftWaitTime 实例
                let liftWaitTime = LiftWaitTime(
                    id: 0,  // Supabase 将自动生成 ID
                    resort_id: resortId,  // 使用传递的雪场 ID
                    date: Date(), // 使用当前日期
                    wait_time: waitTime,
                    created_at: nil // `created_at` 可以留为 nil，Supabase 会处理
                )

                // 使用 upsert 方法来避免唯一性约束问题
                let response = try await manager.client.from("LiftWaitTime").upsert(liftWaitTime).execute()
                print("等待时间上传成功: \(response)")
                showSuccessAlert = true // 显示成功提示
            } catch {
                print("上传失败: \(error.localizedDescription)")
            }
        }
    }
}


#Preview {
    Sheet2View(resortId: 2)
}



