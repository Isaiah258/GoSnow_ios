//
//  StatsTypes.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/11/6.
//

import Foundation

enum StatsScope: CaseIterable { case week, month, season }   // 周/月/雪季
enum StatsMetric: CaseIterable { case duration, distance, snowDays }   // 只做这两个

struct StatsSummary {
    var totalDurationSec: Int
    var totalDistanceKm: Double
    var sessionsCount: Int
}

struct StatsPoint: Identifiable {
    let date: Date                      // 桶的代表时间（天或周起始）
    let value: Double                   // 图表值：duration 用“分钟”，distance 用 “公里”
    var id: Date { date }
}

