//
//  BreakingReportsViewModel.swift
//  GoSnow
//
//  Created by federico Liu on 2024/10/11.
//

import Foundation
import Supabase

// ViewModel 负责处理与突发报告相关的业务逻辑
class BreakingReportsViewModel: ObservableObject {
    @Published var latestReport: BreakingReports? // 用于保存最新的报告
    @Published var isLoading = false // 加载状态

    // 从 Supabase 中获取最新的突发报告
    func fetchLatestReport() async {
        isLoading = true
        do {
            let response = try await DatabaseManager.shared.client
                .from("BreakingReports") // 从 Supabase 的 "BreakingReports" 表获取数据
                .select()
                .order("id", ascending: false) // 按照 id 降序排列，获取最新记录
                .limit(1) // 只获取最新的一条数据
                .execute()

            // 打印返回的原始数据，调试时可使用
            if let rawData = String(data: response.data, encoding: .utf8) {
                print("原始数据: \(rawData)")
            }

            // 解码返回的数据
            let decoder = JSONDecoder()
            let reports = try decoder.decode([BreakingReports].self, from: response.data) // 直接解码
            latestReport = reports.first // 保存最新的报告
        } catch {
            print("获取报告失败: \(error.localizedDescription)")
        }
        isLoading = false
    }

}


