//
//  ReportSheetView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/10/11.
//

import SwiftUI

struct ReportSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var reports: [BreakingReports] // 从 Supabase 获取的报告
    
    @State private var newReport = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("输入突发事件如：救援、儿童走丢...", text: $newReport)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    Task {
                        await submitReport() // 提交新报告
                    }
                }) {
                    Text("提交")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding()
                }
            }
            .navigationTitle("提交突发报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss() // 关闭 sheet
                    }
                }
            }
        }
    }
    
    // 提交新报告到 Supabase，使用 async/await
    func submitReport() async {
        guard let currentUser = DatabaseManager.shared.getCurrentUser() else {
            print("未登录用户不能提交报告")
            return
        }

        let newReport = BreakingReports(id: 0, user_id: currentUser.id, report_content: newReport)

        do {
            let _ = try await DatabaseManager.shared.client
                .from("BreakingResorts")
                .insert(newReport)
                .execute()
            
            reports.append(newReport) // 本地添加新的报告
            dismiss() // 关闭 sheet
        } catch {
            print("提交报告失败: \(error.localizedDescription)")
        }
    }
}




#Preview {
    // 创建一个临时的状态以供预览使用
    ReportSheetView(reports: .constant([])) // 绑定一个空数组
}


