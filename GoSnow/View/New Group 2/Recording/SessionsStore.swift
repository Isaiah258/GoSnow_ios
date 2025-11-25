//
//  SessionsStore.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/12.
//

import Foundation
import Combine

@MainActor
final class SessionsStore: ObservableObject {
    @Published private(set) var sessions: [SkiSession] = []
    @Published private(set) var totalDistanceKm: Double = 0
    @Published private(set) var totalDurationSec: Int = 0
    @Published private(set) var totalSessions: Int = 0

    private let store: LocalStore
    private var bag = Set<AnyCancellable>()

    init(store: LocalStore = JSONLocalStore()) {
        self.store = store
    }

    func ingest(_ s: SkiSession) {
        if !sessions.contains(where: { $0.id == s.id }) {
            sessions.insert(s, at: 0)
            recomputeTotals()
        }
    }

    func reload() async {
        do {
            let list: [SkiSession]
            if let json = store as? JSONLocalStore {
                list = try await json.loadSessionsAsync()
            } else {
                let s = self.store
                list = try await Task.detached(priority: .utility) { try s.loadSessions() }.value
            }
            self.sessions = list
            self.recomputeTotals()
        } catch {
            print("❌ loadSessions failed: \(error)")
        }
    }

    private func recomputeTotals() {
        totalSessions    = sessions.count
        totalDistanceKm  = sessions.reduce(0) { $0 + $1.distanceKm }
        totalDurationSec = sessions.reduce(0) { $0 + $1.durationSec }
    }
}


extension Notification.Name {
    static let sessionSaved = Notification.Name("session_saved")
}

