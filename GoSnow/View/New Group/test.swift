//
//  test.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/9/18.
//

import SwiftUI
import Charts

// MARK: - 「近一周雪况」图表组件
struct WeeklySnowChart: View {
    var data: [WeeklySnowData]

    // 依赖 Step1 的固定顺序与颜色
    private var domain: [String] { SnowConditionOrder.map { SnowConditionLabel[$0]! } }
    private var range:  [Color]  { SnowConditionOrder.map { SnowConditionColor[$0]! } }

    var body: some View {
        Chart(data) { d in
            BarMark(
                x: .value("雪况", d.snowCondition),
                y: .value("次数", d.count)
            )
            .cornerRadius(4)
        }
        .chartXScale(domain: domain)
        .chartForegroundStyleScale(domain: domain, range: range)
        .padding(20)
        .frame(height: 300)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - 「昨日缆车等待」图表组件
struct YesterdayLiftWaitChart: View {
    var data: [YesterdayLiftWaitTime]

    private var domain: [String] { WaitBinOrder.map { WaitBinLabel[$0]! } }
    private var range:  [Color]  { WaitBinOrder.map { WaitBinColor[$0]! } }

    var body: some View {
        Chart(data) { d in
            BarMark(
                x: .value("等待时间", d.waitTime),
                y: .value("次数", d.count)
            )
            .cornerRadius(4)
        }
        .chartXScale(domain: domain)
        .chartForegroundStyleScale(domain: domain, range: range)
        .padding(20)
        .frame(height: 300)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}


