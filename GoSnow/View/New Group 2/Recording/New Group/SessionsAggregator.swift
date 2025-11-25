//
//  SessionsAggregator.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/11/6.
//

import Foundation

enum SessionsAggregatorForStatus {
    static func interval(for scope: StatsScope, around now: Date = Date(), calendar: Calendar = .current) -> DateInterval {
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
            // 规则：11/1 → 次年 4/30（含）
            let comps = calendar.dateComponents([.year, .month], from: now)
            let year  = comps.year!
            if (11...12).contains(comps.month!) {
                let start = calendar.date(from: DateComponents(year: year, month: 11, day: 1))!
                let end   = calendar.date(from: DateComponents(year: year + 1, month: 5, day: 1))! // 5/1 不含
                return DateInterval(start: start, end: end)
            } else {
                let start = calendar.date(from: DateComponents(year: year - 1, month: 11, day: 1))!
                let end   = calendar.date(from: DateComponents(year: year, month: 5, day: 1))!
                return DateInterval(start: start, end: end)
            }
        }
    }

    static func compute(
        sessions: [SkiSession],
        scope: StatsScope,
        metric: StatsMetric,
        calendar: Calendar = .current
    ) -> (series: [StatsPoint], summary: StatsSummary) {

        let iv = interval(for: scope, around: Date(), calendar: calendar)
        let inRange = sessions.filter { iv.contains($0.startAt) }

        // 总结
        let totalDuration = inRange.reduce(0) { $0 + $1.durationSec }
        let totalDistance = inRange.reduce(0.0) { $0 + $1.distanceKm }
        let summary = StatsSummary(
            totalDurationSec: totalDuration,
            totalDistanceKm: totalDistance,
            sessionsCount: inRange.count
        )

        switch scope {
        case .week, .month:
            // 按“日”分桶
            var cur = calendar.startOfDay(for: iv.start)
            var dayStarts: [Date] = []
            while cur < iv.end {
                dayStarts.append(cur)
                cur = calendar.date(byAdding: .day, value: 1, to: cur)!
            }

            let grouped = Dictionary(grouping: inRange) { s in
                calendar.startOfDay(for: s.startAt)
            }

            let points: [StatsPoint] = dayStarts.map { day in
                let items = grouped[day] ?? []
                switch metric {
                case .duration:
                    let minutes = Double(items.reduce(0) { $0 + $1.durationSec }) / 60.0
                    return .init(date: day, value: minutes)
                case .distance:
                    let km = items.reduce(0.0) { $0 + $1.distanceKm }
                    return .init(date: day, value: km)
                case .snowDays:
                    // 这一天是否有任一会话（有=1，无=0）
                    let hasAny = !items.isEmpty
                    return .init(date: day, value: hasAny ? 1.0 : 0.0)
                }
            }
            return (points, summary)

        case .season:
            // 按“周”分桶
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: iv.start)!.start
            var starts: [Date] = []
            var cur = weekStart
            while cur < iv.end {
                starts.append(cur)
                cur = calendar.date(byAdding: .weekOfYear, value: 1, to: cur)!
            }

            let grouped = Dictionary(grouping: inRange) { s in
                calendar.dateInterval(of: .weekOfYear, for: s.startAt)!.start
            }

            let points: [StatsPoint] = starts.map { wStart in
                let items = grouped[wStart] ?? []
                switch metric {
                case .duration:
                    let minutes = Double(items.reduce(0) { $0 + $1.durationSec }) / 60.0
                    return .init(date: wStart, value: minutes)
                case .distance:
                    let km = items.reduce(0.0) { $0 + $1.distanceKm }
                    return .init(date: wStart, value: km)
                case .snowDays:
                    // 该周内“有会话的不同自然日”数量（0~7）
                    let uniqueDays = Set(items.map { calendar.startOfDay(for: $0.startAt) })
                    return .init(date: wStart, value: Double(uniqueDays.count))
                }
            }
            return (points, summary)
        }
    }
}
