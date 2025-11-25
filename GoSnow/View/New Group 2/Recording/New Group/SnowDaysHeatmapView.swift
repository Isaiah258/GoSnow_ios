//
//  SnowDaysHeatmapView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/11/7.
//

import SwiftUI

// MARK: - 范围枚举（与你现有一致即可）
enum SnowScope: Hashable {
    case week, month, season
}

// MARK: - 颜色与阈值（分钟）
fileprivate struct SnowTheme {
    // 0 分钟（无滑行）用浅灰
    static let empty = Color(.systemGray6)
    // 蓝色阶（低 → 高）
    static let steps: [Color] = [
        Color(red: 0.82, green: 0.92, blue: 1.00), // 1~15min
        Color(red: 0.57, green: 0.77, blue: 0.97), // 15~60
        Color(red: 0.23, green: 0.53, blue: 0.90), // 60~180
        Color(red: 0.05, green: 0.27, blue: 0.63)  // 180+
    ]
    // 对应阈值（上开区间）
    static let thresholds = [15, 60, 180] // 单位：分钟
}

// MARK: - 主视图
struct SnowDaysHeatmapView: View {
    let sessions: [SkiSession]
    let scope: SnowScope
    let now: Date = Date()

    @State private var grid: SnowGrid = SnowGrid.empty

    var body: some View {
        VStack(spacing: 12) {
            // 标题 + 说明
            HStack {
                Text(titleText)
                    .font(.headline)
                Spacer()
                LegendView()
            }
            .padding(.horizontal)

            // 网格
            Group {
                switch scope {
                case .week:
                    WeekStrip(grid: grid)
                case .month:
                    MonthGrid(grid: grid)
                case .season:
                    SeasonGrid(grid: grid)
                }
            }
            .animation(.snappy, value: grid.cells)

            // 雪天数摘要
            HStack {
                Text("雪天数")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(grid.snowDays) 天")
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
        }
        .onAppear { recompute() }
        .onChange(of: scope) { _, _ in recompute() }
        .onChange(of: sessions.count) { _, _ in recompute() } // 简易触发
    }

    private var titleText: String {
        switch scope {
        case .week:
            let r = DateRangeBuilder.week(of: now)
            return "本周 \(fmt(r.start, "M/d"))–\(fmt(r.end, "M/d"))"
        case .month:
            let r = DateRangeBuilder.month(of: now)
            return "\(fmt(r.start, "yyyy年M月"))"
        case .season:
            let r = DateRangeBuilder.season(for: now)
            let seasonLabel = seasonName(for: r.start)
            return "\(seasonLabel) 雪季"
        }
    }

    private func seasonName(for start: Date) -> String {
        let y = Calendar.current.component(.year, from: start) % 100
        let next = (y + 1) % 100
        return String(format: "%02d–%02d", y, next)
    }

    private func fmt(_ d: Date, _ pat: String) -> String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = .current
        f.dateFormat = pat
        return f.string(from: d)
    }

    private func recompute() {
        let cal = Calendar.current
        let range: (start: Date, end: Date) = {
            switch scope {
            case .week:   return DateRangeBuilder.week(of: now)
            case .month:  return DateRangeBuilder.month(of: now)
            case .season: return DateRangeBuilder.season(for: now)
            }
        }()

        // 1) 每日总分钟
        let minutesByDay = HeatmapAggregator.dailyMinutes(
            sessions: sessions, start: range.start, end: range.end, calendar: cal
        )

        // 2) 构建网格
        switch scope {
        case .week:
            grid = HeatmapAggregator.buildWeekGrid(start: range.start, minutes: minutesByDay, calendar: cal)
        case .month:
            grid = HeatmapAggregator.buildMonthGrid(start: range.start, minutes: minutesByDay, calendar: cal)
        case .season:
            grid = HeatmapAggregator.buildSeasonGrid(range: range, minutes: minutesByDay, calendar: cal)
        }
    }
}

// MARK: - 网格数据模型
fileprivate struct SnowCell: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let minutes: Int
}

fileprivate struct SnowGrid {
    var cells: [SnowCell] = []
    var columns: Int = 7
    var rows: Int = 1
    var snowDays: Int = 0

    static let empty = SnowGrid()
}

// MARK: - 聚合器
fileprivate enum HeatmapAggregator {
    static func stripTime(_ date: Date, calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    /// 计算每日总分钟（跨天会话按自然日切割）
    static func dailyMinutes(
        sessions: [SkiSession],
        start: Date, end: Date,
        calendar: Calendar
    ) -> [Date: Int] {
        var map: [Date: Int] = [:]
        for s in sessions {
            // 跳过不在范围的
            let s0 = max(s.startAt, start)
            let e0 = min(s.endAt, end)
            guard e0 >= s0, s.durationSec > 0 else { continue }

            // 逐日切割（确保跨午夜正确分配）
            var cursor = calendar.startOfDay(for: s0)
            let endDay = calendar.startOfDay(for: e0)

            while cursor <= endDay {
                let dayStart = cursor
                guard let next = calendar.date(byAdding: .day, value: 1, to: dayStart) else { break }
                let dayEnd = min(next, end)
                // 该日与会话交集
                let segStart = max(s0, dayStart)
                let segEnd = min(e0, dayEnd)
                let sec = max(0, Int(segEnd.timeIntervalSince(segStart)))
                if sec > 0 {
                    map[dayStart, default: 0] += Int(ceil(Double(sec) / 60.0))
                }
                cursor = next
            }
        }
        return map
    }

    static func buildWeekGrid(start: Date, minutes: [Date: Int], calendar: Calendar) -> SnowGrid {
        var cells: [SnowCell] = []
        let s = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: start))!
        for i in 0..<7 {
            let d = calendar.date(byAdding: .day, value: i, to: s)!
            cells.append(.init(date: d, minutes: minutes[calendar.startOfDay(for: d)] ?? 0))
        }
        let snow = cells.filter { $0.minutes > 0 }.count
        return SnowGrid(cells: cells, columns: 7, rows: 1, snowDays: snow)
    }

    static func buildMonthGrid(start: Date, minutes: [Date: Int], calendar: Calendar) -> SnowGrid {
        let range = calendar.range(of: .day, in: .month, for: start)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: start))!
        let firstWeekdayIndex = (calendar.component(.weekday, from: firstOfMonth) + 6) % 7 // 0=周一
        var cells: [SnowCell] = []

        // 前置空白
        for _ in 0..<firstWeekdayIndex {
            cells.append(.init(date: Date.distantPast, minutes: -1))
        }
        // 当月天
        for day in range {
            let d = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)!
            cells.append(.init(date: d, minutes: minutes[calendar.startOfDay(for: d)] ?? 0))
        }
        // 行数
        let rows = Int(ceil(Double(cells.count) / 7.0))
        let snow = cells.filter { $0.minutes > 0 }.count
        return SnowGrid(cells: cells, columns: 7, rows: rows, snowDays: snow)
    }

    static func buildSeasonGrid(range: (start: Date, end: Date), minutes: [Date: Int], calendar: Calendar) -> SnowGrid {
        // 以周为列，周一开始；7 行对应周一~周日
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: range.start))!
        var days: [Date] = []
        var d = startOfWeek
        while d <= range.end {
            days.append(d)
            d = calendar.date(byAdding: .day, value: 1, to: d)!
        }
        // 按“列”为单位排列：列数 = 周数
        let totalWeeks = Int(ceil(Double(days.count) / 7.0))
        var cells: [SnowCell] = []
        for i in 0..<(totalWeeks * 7) {
            let date = (i < days.count) ? days[i] : Date.distantPast
            let min = (date == Date.distantPast) ? -1 : (minutes[calendar.startOfDay(for: date)] ?? 0)
            cells.append(.init(date: date, minutes: min))
        }
        let snow = cells.filter { $0.minutes > 0 }.count
        return SnowGrid(cells: cells, columns: totalWeeks, rows: 7, snowDays: snow)
    }
}

// MARK: - 范围构造（雪季：当季 11/1 ~ 次年 4/30）
fileprivate enum DateRangeBuilder {
    static func week(of date: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let s = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let e = cal.date(byAdding: .day, value: 7, to: s)!.addingTimeInterval(-1)
        return (s, e)
    }

    static func month(of date: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let s = cal.date(from: cal.dateComponents([.year, .month], from: date))!
        let range = cal.range(of: .day, in: .month, for: s)!
        let e = cal.date(byAdding: .day, value: range.count, to: s)!.addingTimeInterval(-1)
        return (s, e)
    }

    /// 25–26季：2025-11-01 ~ 2026-04-30（根据“今天”落在哪个季，自动判断）
    static func season(for today: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: today)
        let y = comps.year!
        let m = comps.month!
        if m >= 11 { // 今年 11~12 -> 本季从今年11/1到明年4/30
            let s = cal.date(from: DateComponents(year: y, month: 11, day: 1))!
            let e = cal.date(from: DateComponents(year: y + 1, month: 4, day: 30, hour: 23, minute: 59, second: 59))!
            return (s, e)
        } else if m <= 4 { // 今年 1~4 -> 本季从去年11/1到今年4/30
            let s = cal.date(from: DateComponents(year: y - 1, month: 11, day: 1))!
            let e = cal.date(from: DateComponents(year: y, month: 4, day: 30, hour: 23, minute: 59, second: 59))!
            return (s, e)
        } else {
            // 非雪季月份（5~10）：显示“即将到来的季”
            let s = cal.date(from: DateComponents(year: y, month: 11, day: 1))!
            let e = cal.date(from: DateComponents(year: y + 1, month: 4, day: 30, hour: 23, minute: 59, second: 59))!
            return (s, e)
        }
    }
}

// MARK: - 颜色映射
fileprivate func colorFor(minutes: Int) -> Color {
    guard minutes > 0 else { return SnowTheme.empty }
    let mins = minutes
    if mins <= SnowTheme.thresholds[0] { return SnowTheme.steps[0] }
    if mins <= SnowTheme.thresholds[1] { return SnowTheme.steps[1] }
    if mins <= SnowTheme.thresholds[2] { return SnowTheme.steps[2] }
    return SnowTheme.steps[3]
}

// MARK: - 视图：图例
fileprivate struct LegendView: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("0").font(.caption2).foregroundStyle(.secondary)
            ForEach(0..<SnowTheme.steps.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3).fill(SnowTheme.steps[i])
                    .frame(width: 14, height: 10)
            }
            Text("180+ min").font(.caption2).foregroundStyle(.secondary)
        }
    }
}

// MARK: - 周：7格横条
fileprivate struct WeekStrip: View {
    let grid: SnowGrid
    var body: some View {
        HStack(spacing: 6) {
            ForEach(grid.cells) { c in
                RoundedRectangle(cornerRadius: 4)
                    .fill(c.minutes >= 0 ? colorFor(minutes: c.minutes) : Color.clear)
                    .frame(height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.black.opacity(0.05), lineWidth: 0.5)
                    )
                    .accessibilityLabel(label(for: c))
            }
        }
        .padding(.horizontal)
    }

    private func label(for c: SnowCell) -> Text {
        if c.minutes <= 0 { return Text("无活动") }
        return Text("\(c.minutes) 分钟")
    }
}

// MARK: - 月：日历式 7xN 网格
fileprivate struct MonthGrid: View {
    let grid: SnowGrid
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    var body: some View {
        LazyVGrid(columns: cols, spacing: 6) {
            ForEach(grid.cells) { c in
                RoundedRectangle(cornerRadius: 4)
                    .fill(c.minutes >= 0 ? colorFor(minutes: c.minutes) : Color.clear)
                    .frame(height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.black.opacity(0.05), lineWidth: 0.5)
                    )
                    .accessibilityLabel(label(for: c))
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }

    private func label(for c: SnowCell) -> Text {
        if c.minutes < 0 { return Text("无") }
        if c.minutes == 0 { return Text("无活动") }
        return Text("\(c.minutes) 分钟")
    }
}

// MARK: - 雪季：以“周”为列，7 行为星期
fileprivate struct SeasonGrid: View {
    let grid: SnowGrid
    var body: some View {
        // 将一维 cells 按列（周）转置成 7 行
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                let weeks = grid.columns
                ForEach(0..<weeks, id: \.self) { w in
                    VStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { r in
                            let idx = w * 7 + r
                            let c = grid.cells.indices.contains(idx) ? grid.cells[idx] : SnowCell(date: .distantPast, minutes: -1)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(c.minutes >= 0 ? colorFor(minutes: c.minutes) : Color.clear)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(Color.black.opacity(0.05), lineWidth: 0.5)
                                )
                                .accessibilityLabel(c.minutes > 0 ? Text("\(c.minutes) 分钟") : Text("无活动"))
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .frame(height: 120)
    }
}

