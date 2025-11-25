//
//  BreakingReportView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/10/11.
//

import SwiftUI

struct BreakingReportView: View {
    @State private var showReportSheet = false // 控制 sheet 显示
    @State private var reports: [BreakingReports] = [] // 从 Supabase 获取的报告数组
    @State private var isLoading = false // 加载状态
    
    var body: some View {
        VStack(alignment: .leading) {
            if isLoading {
                ProgressView("加载中...") // 加载指示器
                    .padding()
            } else {
                // 循环显示所有报告
                List(reports) { report in
                    VStack(alignment: .leading) {
                        Text(report.report_content)
                            .font(.headline)
                        
                    }
                    .padding(.vertical, 5)
                }
            }
            
            Spacer()
            
            // 提交报告按钮
            Button(action: {
                showReportSheet.toggle()
            }) {
                Text("报告事件")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 300, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding()
            }
            .padding(.leading, 35)
        }
        .onAppear {
            Task {
                await fetchReports() // 页面加载时获取报告
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSheetView(reports: $reports) // 传递 reports 数组给 sheet
        }
    }

    // 获取报告的方法，使用 async/await
    func fetchReports() async {
        isLoading = true
        do {
            // 发起请求获取数据
            let response = try await DatabaseManager.shared.client
                .from("BreakingReports")
                .select()
                .execute()

            // 直接解码响应数据
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 // 设定日期解码策略
            reports = try decoder.decode([BreakingReports].self, from: response.data)
        } catch {
            print("获取报告失败: \(error.localizedDescription)")
        }
        isLoading = false
    }
}





#Preview {
    BreakingReportView()
}
