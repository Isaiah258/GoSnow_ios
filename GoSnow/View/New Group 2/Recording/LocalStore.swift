//
//  LocalStore.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/11/6.
//

import Foundation


public protocol LocalStore {
    func saveSession(_ session: SkiSession) throws
    func loadSessions() throws -> [SkiSession]
}
