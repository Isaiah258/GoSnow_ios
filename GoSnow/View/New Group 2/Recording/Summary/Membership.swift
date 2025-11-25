//
//  Membership.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/10.
//

import Foundation

// Recording/Domain/Membership.swift
enum Membership {
    static var isVIP: Bool { false }          // TODO: 接你真实会员系统
    static var maxSessions: Int { isVIP ? 1000 : 5 }
}
