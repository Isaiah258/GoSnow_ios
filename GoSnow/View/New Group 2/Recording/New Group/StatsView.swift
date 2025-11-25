//
//  StatsView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/11/6.
//

import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var sessionsStore: SessionsStore

    @State private var scope: StatsScope = .week
    @State private var metric: StatsMetric = .duration

    @State private var series: [StatsPoint] = []
    @State private var summary = StatsSummary(totalDurationSec: 0, totalDistanceKm: 0, sessionsCount: 0)

    // 热力图数据（周/月 或 “雪季-当前页”）
    @State private var heatmapBuckets: [Date: Int] = [:]
    @State private var snowDaysCount: Int = 0
    @State private var heatmapDaysOrdered: [Date] = []

    // 当前用于 X 轴格式化的区间
    @State private var currentInterval: DateInterval?

    // —— 雪季：月份分页（11,12,1,2,3,4）——
    @State private var seasonMonths: [MonthBucket] = []
    @State private var seasonPageIndex: Int = 0

    private var selectedColor: Color {
        switch metric {
        case .duration:  return .orange
        case .distance:  return .green
        case .snowDays:  return .blue
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // 顶部：范围切换
            Picker("", selection: $scope) {
                Text("周").tag(StatsScope.week)
                Text("月").tag(StatsScope.month)
                Text("雪季").tag(StatsScope.season)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // 图表 / 热力图
            Group {
                if metric == .snowDays {
                    if scope == .season {
                        // 雪季：按月分页 + 横向滑动
                        SeasonMonthlyPager(
                            sessions: sessionsStore.sessions,
                            months: seasonMonths,
                            selection: $seasonPageIndex
                        )
                        .frame(height: 220)
                        .padding(.horizontal)
                    } else {
                        // 周 / 月：整段热力图
                        HeatmapGrid(
                            days: heatmapDaysOrdered,
                            values: heatmapBuckets,
                            color: .blue
                        )
                        .frame(height: 220)
                        .padding(.horizontal)
                    }
                } else {
                    if series.isEmpty {
                        VStack(spacing: 8) {
                            Text("暂无数据").foregroundStyle(.secondary)
                            Text("开始一次记录试试～").font(.footnote).foregroundStyle(.secondary)
                        }
                        .frame(height: 200)
                    } else {
                        Chart(series) { p in
                            AreaMark(
                                x: .value("日期", p.date),
                                y: .value(metric == .duration ? "分钟" : "公里", p.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(selectedColor.opacity(0.14))

                            LineMark(
                                x: .value("日期", p.date),
                                y: .value(metric == .duration ? "分钟" : "公里", p.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineJoin: .round))
                            .foregroundStyle(selectedColor)

                            PointMark(
                                x: .value("日期", p.date),
                                y: .value(metric == .duration ? "分钟" : "公里", p.value)
                            )
                            .symbol(.circle)
                            .symbolSize(28)
                            .foregroundStyle(selectedColor)
                        }
                        // 雪季折线的 X 轴仅显示“月份”
                        .applySeasonMonthAxisIfNeeded(scope: scope, interval: currentInterval)
                        .chartYAxisLabel(metric == .duration ? "分钟" : "公里")
                        .frame(height: 220)
                        .padding(.horizontal)
                    }
                }
            }

            // 摘要卡：持续时间 / 距离 / 雪天数（三选一）
            HStack(spacing: 12) {
                SummaryCard(
                    title: "持续时间",
                    value: timeString(minutes: Double(summary.totalDurationSec) / 60.0),
                    selected: metric == .duration,
                    color: .orange
                ) { metric = .duration }

                SummaryCard(
                    title: "距离",
                    value: String(format: "%.1f km", summary.totalDistanceKm),
                    selected: metric == .distance,
                    color: .green
                ) { metric = .distance }

                SummaryCard(
                    title: "雪天数",
                    value: "\(snowDaysCount) 天",
                    selected: metric == .snowDays,
                    color: .blue
                ) { metric = .snowDays }
            }
            .padding(.horizontal)

            // 次数
            HStack {
                Text("记录次数").foregroundStyle(.secondary)
                Spacer()
                Text("\(summary.sessionsCount) 次")
            }
            .padding(.horizontal)
            .padding(.top, 4)

            Spacer(minLength: 12)
        }
        .navigationTitle("活动")
        .navigationBarTitleDisplayMode(.large)
        // 避免 Array 需要 Equatable：用 onReceive
        .onReceive(sessionsStore.$sessions) { _ in recomputeAll() }
        .onChange(of: scope)  { _, _ in recomputeAll() }
        .onChange(of: metric) { _, _ in recomputeMetricSwitch() }
        .onChange(of: seasonPageIndex) { _, newIndex in
            // 切月时，只在“雪季 + 雪天数”下重建该页热力图
            guard scope == .season, metric == .snowDays else { return }
            rebuildSeasonPageHeatmap(page: newIndex)
        }
        .task { recomputeAll() }
    }

    // MARK: - 计算

    /// 切范围或数据时：重算月份分页 + 概览 + 折线/热力图
    private func recomputeAll() {
        let iv = intervalFor(scope: scope, now: Date())
        currentInterval = iv

        // 1) 雪季月份列表
        if scope == .season {
            seasonMonths = makeSeasonMonths()
            seasonPageIndex = min(seasonPageIndex, max(seasonMonths.count - 1, 0))
        } else {
            seasonMonths = []
            seasonPageIndex = 0
        }

        // 2) 概览 summary + 折线 series
        recomputeSeriesAndSummary(interval: iv)

        // 3) 热力图
        if metric == .snowDays {
            if scope == .season {
                rebuildSeasonPageHeatmap(page: seasonPageIndex)
            } else {
                buildHeatmap(iv: iv, sessions: sessionsStore.sessions.filter { iv.contains($0.startAt) })
            }
        } else {
            // 非雪天数：不需要热力图，但我们仍然更新 snowDaysCount（摘要展示用）
            buildHeatmap(iv: iv, sessions: sessionsStore.sessions.filter { iv.contains($0.startAt) })
        }
    }

    /// 仅切换指标时的快速响应（避免重复生成月份列表）
    private func recomputeMetricSwitch() {
        let iv = intervalFor(scope: scope, now: Date())
        if metric == .snowDays {
            if scope == .season {
                rebuildSeasonPageHeatmap(page: seasonPageIndex)
            } else {
                buildHeatmap(iv: iv, sessions: sessionsStore.sessions.filter { iv.contains($0.startAt) })
            }
        }
        // 折线图在 computeSeriesAndSummary 里已按 metric 生成，这里不重复算
    }

    private func recomputeSeriesAndSummary(interval iv: DateInterval) {
        let inRange = sessionsStore.sessions.filter { iv.contains($0.startAt) }

        // 概览
        let totalDuration = inRange.reduce(0) { $0 + $1.durationSec }
        let totalDistance = inRange.reduce(0.0) { $0 + $1.distanceKm }
        summary = StatsSummary(
            totalDurationSec: totalDuration,
            totalDistanceKm: totalDistance,
            sessionsCount: inRange.count
        )

        switch scope {
        case .week, .month:
            var cur = Calendar.current.startOfDay(for: iv.start)
            var days: [Date] = []
            while cur < iv.end {
                days.append(cur)
                cur = Calendar.current.date(byAdding: .day, value: 1, to: cur)!
            }
            let grouped = Dictionary(grouping: inRange) { Calendar.current.startOfDay(for: $0.startAt) }
            series = days.map { day in
                let items = grouped[day] ?? []
                switch metric {
                case .duration:
                    let minutes = Double(items.reduce(0) { $0 + $1.durationSec }) / 60.0
                    return .init(date: day, value: minutes)
                case .distance:
                    let km = items.reduce(0.0) { $0 + $1.distanceKm }
                    return .init(date: day, value: km)
                case .snowDays:
                    return .init(date: day, value: 0) // 雪天数走热力图
                }
            }

        case .season:
            // 折线：按周聚合
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: iv.start)!.start
            var starts: [Date] = []
            var cur = weekStart
            while cur < iv.end {
                starts.append(cur)
                cur = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: cur)!
            }
            let grouped = Dictionary(grouping: inRange) {
                Calendar.current.dateInterval(of: .weekOfYear, for: $0.startAt)!.start
            }
            series = starts.map { wStart in
                let items = grouped[wStart] ?? []
                switch metric {
                case .duration:
                    let minutes = Double(items.reduce(0) { $0 + $1.durationSec }) / 60.0
                    return .init(date: wStart, value: minutes)
                case .distance:
                    let km = items.reduce(0.0) { $0 + $1.distanceKm }
                    return .init(date: wStart, value: km)
                case .snowDays:
                    return .init(date: wStart, value: 0)
                }
            }
        }
    }

    /// 计算区间（周/月/“本年度雪季”：11/1 ~ 次年 4/30 23:59:59）
    private func intervalFor(scope: StatsScope, now: Date, calendar: Calendar = .current) -> DateInterval {
        switch scope {
        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)!.start
            let end   = calendar.date(byAdding: .day, value: 7, to: start)!
            return DateInterval(start: start, end: end)
        case .month:
            let start = calendar.dateInterval(of: .month, for: now)!.start
            let range = calendar.range(of: .day, in: .month, for: start)!.count
            let end   = calendar.date(byAdding: .day, value: range, to: start)!
            return DateInterval(start: start, end: end)
        case .season:
            let y = calendar.component(.year, from: now)
            let m = calendar.component(.month, from: now)
            if m >= 11 {
                let start = calendar.date(from: DateComponents(year: y,     month: 11, day: 1))!
                let end   = calendar.date(from: DateComponents(year: y + 1, month: 4,  day: 30, hour: 23, minute: 59, second: 59))!
                return DateInterval(start: start, end: end)
            } else if m <= 4 {
                let start = calendar.date(from: DateComponents(year: y - 1, month: 11, day: 1))!
                let end   = calendar.date(from: DateComponents(year: y,     month: 4,  day: 30, hour: 23, minute: 59, second: 59))!
                return DateInterval(start: start, end: end)
            } else {
                let start = calendar.date(from: DateComponents(year: y - 1, month: 11, day: 1))!
                let end   = calendar.date(from: DateComponents(year: y,     month: 4,  day: 30, hour: 23, minute: 59, second: 59))!
                return DateInterval(start: start, end: end)
            }
        }
    }

    /// 构建（整段）热力图 or 统计雪天数（自然日去重）
    private func buildHeatmap(iv: DateInterval, sessions: [SkiSession]) {
        var buckets: [Date: Int] = [:]
        let cal = Calendar.current

        // 完整日序列（稳定网格）
        var daysOrdered: [Date] = []
        var cur = cal.startOfDay(for: iv.start)
        while cur < iv.end {
            daysOrdered.append(cur)
            cur = cal.date(byAdding: .day, value: 1, to: cur)!
        }

        // 统计：一天内任意会话即“有雪”；强度=分钟（至少1）
        for s in sessions where iv.contains(s.startAt) && s.durationSec > 0 {
            let day = cal.startOfDay(for: s.startAt)
            let weight = max(1, s.durationSec / 60)
            buckets[day, default: 0] += weight
        }

        heatmapBuckets = buckets
        heatmapDaysOrdered = daysOrdered
        snowDaysCount = buckets.keys.count
    }

    /// 雪季月份列表（11,12,1,2,3,4）
    private func makeSeasonMonths(reference: Date = Date()) -> [MonthBucket] {
        let cal = Calendar(identifier: .gregorian)
        // 赛季区间
        let y = cal.component(.year, from: reference)
        let m = cal.component(.month, from: reference)
        let (start, end): (Date, Date) = {
            if m >= 11 {
                let s = cal.date(from: DateComponents(year: y,     month: 11, day: 1))!
                let e = cal.date(from: DateComponents(year: y + 1, month: 5,  day: 1))! // 5/1 不含
                return (s, e)
            } else if m <= 4 {
                let s = cal.date(from: DateComponents(year: y - 1, month: 11, day: 1))!
                let e = cal.date(from: DateComponents(year: y,     month: 5,  day: 1))!
                return (s, e)
            } else {
                let s = cal.date(from: DateComponents(year: y - 1, month: 11, day: 1))!
                let e = cal.date(from: DateComponents(year: y,     month: 5,  day: 1))!
                return (s, e)
            }
        }()

        var buckets: [MonthBucket] = []
        var cur = cal.startOfDay(for: start)
        while cur < end {
            let comps = cal.dateComponents([.year, .month], from: cur)
            let monthStart = cal.date(from: DateComponents(year: comps.year!, month: comps.month!, day: 1))!
            let nextMonth  = cal.date(byAdding: .month, value: 1, to: monthStart)!
            let monthEndEx = min(nextMonth, end) // [start, end)
            buckets.append(.init(year: comps.year!, month: comps.month!, start: monthStart, end: monthEndEx))
            cur = nextMonth
        }
        return buckets
    }

    /// 雪季：根据当前页（月）重建热力图数据
    private func rebuildSeasonPageHeatmap(page: Int) {
        guard !seasonMonths.isEmpty else {
            heatmapBuckets = [:]
            heatmapDaysOrdered = []
            snowDaysCount = 0
            return
        }
        let idx = min(max(page, 0), seasonMonths.count - 1)
        let m = seasonMonths[idx]
        let iv = DateInterval(start: m.start, end: m.end)

        let sessionsInMonth = sessionsStore.sessions.filter { $0.startAt >= m.start && $0.startAt < m.end }
        buildHeatmap(iv: iv, sessions: sessionsInMonth)
    }

    private func timeString(minutes: Double) -> String {
        let m = Int(round(minutes))
        let h = m / 60
        let mm = m % 60
        return h > 0 ? "\(h)小时\(mm)分" : "\(mm) 分钟"
    }
}

// MARK: - 摘要卡
private struct SummaryCard: View {
    let title: String
    let value: String
    let selected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(.system(size: 24, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .opacity(selected ? 0.95 : 0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? color : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? color : .clear, lineWidth: 1)
            )
            .foregroundStyle(selected ? Color.white : Color.primary)
            .shadow(color: selected ? color.opacity(0.32) : .clear, radius: 10, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 热力图（蓝色）
private struct HeatmapGrid: View {
    let days: [Date]
    let values: [Date: Int]
    let color: Color

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ForEach(["一","二","三","四","五","六","日"], id: \.self) { w in
                    Text(w).font(.caption2).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(days, id: \.self) { d in
                    let v = values[d] ?? 0
                    let op = opacity(for: v)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(v == 0 ? Color(.systemGray5) : color.opacity(op))
                        .frame(height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(Color.black.opacity(0.05), lineWidth: 0.5)
                        )
                        .accessibilityLabel(Text("\(dateLabel(d)): \(v == 0 ? "无" : "有")"))
                }
            }
        }
    }

    private func opacity(for value: Int) -> Double {
        if value <= 0 { return 0 }
        if value >= 60 { return 0.95 }
        if value >= 30 { return 0.75 }
        if value >= 10 { return 0.55 }
        return 0.35
    }

    private func dateLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "M月d日"
        return f.string(from: d)
    }
}

// MARK: - 雪季：月份分页 + 横滑（标题只写“几月”）
private struct MonthBucket: Identifiable, Hashable {
    var id: String { "\(year)-\(month)" }
    let year: Int
    let month: Int
    let start: Date   // 含
    let end: Date     // 不含

    var title: String { "\(month)月" }
}

private struct SeasonMonthlyPager: View {
    let sessions: [SkiSession]
    let months: [MonthBucket]
    @Binding var selection: Int

    private let onColor = Color.blue
    private let offColor = Color(.systemGray5)

    var body: some View {
        if months.isEmpty {
            RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6))
                .overlay(Text("本雪季暂无时间范围").foregroundStyle(.secondary))
        } else {
            VStack(spacing: 12) {
                Text(months[clampedIndex].title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TabView(selection: $selection) {
                    ForEach(Array(months.enumerated()), id: \.offset) { (idx, m) in
                        let (days, values) = monthHeatmapData(month: m, sessions: sessions)
                        HeatmapGrid(days: days, values: values, color: .blue)
                            .padding(.vertical, 4)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
        }
    }

    private var clampedIndex: Int { min(max(selection, 0), max(months.count - 1, 0)) }

    private func monthHeatmapData(month: MonthBucket, sessions: [SkiSession]) -> ([Date], [Date: Int]) {
        let cal = Calendar.current
        let iv = DateInterval(start: month.start, end: month.end)

        // 完整日序列
        var days: [Date] = []
        var cur = cal.startOfDay(for: month.start)
        while cur < month.end {
            days.append(cur)
            cur = cal.date(byAdding: .day, value: 1, to: cur)!
        }

        // 统计
        var buckets: [Date: Int] = [:]
        for s in sessions where iv.contains(s.startAt) && s.durationSec > 0 {
            let day = cal.startOfDay(for: s.startAt)
            let weight = max(1, s.durationSec / 60)
            buckets[day, default: 0] += weight
        }
        return (days, buckets)
    }
}

// MARK: - Chart X 轴样式辅助（雪季仅显示月份）
private extension View {
    func applySeasonMonthAxisIfNeeded(scope: StatsScope, interval: DateInterval?) -> some View {
        guard scope == .season, let iv = interval else { return AnyView(self) }
        return AnyView(
            self
                .chartXScale(domain: iv.start...iv.end)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.defaultDigits))
                    }
                }
        )
    }
}



/*
 说明：
 - 这里保留了你外部的 StatsScope / StatsMetric / StatsPoint / StatsSummary / SessionsAggregatorForStatus。
 - 如果 Aggregator 内部也做了季节过滤，不会冲突，因为我们在 StatsView 里已经把 sessions 先按本季裁了。
 - 你的 MAX_SESSIONS 已取消，不影响这里逻辑。
*/
