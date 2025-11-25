//
//  Models.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/11/5.
//

import Foundation



// carpool_posts 底表（与后端列一一对应）
public struct CarpoolPost: Codable, Identifiable {
    public let id: UUID
    public let user_id: UUID
    public let resort_id: Int

    public let depart_at: Date
    public let origin_text: String?
    public let note: String?

    public let is_hidden: Bool
    public let expires_at: Date
    public let depart_date_utc: String
    public let created_at: Date
    public let updated_at: Date
}

// 插入载荷（触发器会自动写 expires_at / depart_date_utc）
public struct CarpoolPostInsert: Codable {
    public let user_id: UUID
    public let resort_id: Int
    public let depart_at: String   // 传 ISO8601Z 字符串
    public let origin_text: String?
    public let note: String?
    public var is_hidden: Bool = false
}

// ISO8601（带 Z）
enum ISO8601Z {
    static let fmt: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withTimeZone]
        return f
    }()
    static func string(_ d: Date) -> String { fmt.string(from: d) }
}

// 某时区的一天时间窗
enum DayRange {
    static func inTimeZone(_ tzID: String, for date: Date) -> (start: Date, end: Date) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: tzID) ?? .current
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
}


