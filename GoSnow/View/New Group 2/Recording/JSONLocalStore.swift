//
//  JSONLocalStore.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/10.
//

import Foundation

final class JSONLocalStore: LocalStore {
    private let fm = FileManager.default
    private lazy var dirURL: URL = {
        let url = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        return url.appendingPathComponent("sessions", isDirectory: true)
    }()

    init() {
        try? fm.createDirectory(at: dirURL, withIntermediateDirectories: true)
    }

    func saveSession(_ session: SkiSession) throws {
        let data = try JSONEncoder().encode(session)
        let url = dirURL.appendingPathComponent("\(session.id.uuidString).json")
        try data.write(to: url, options: .atomic)
    }

    func loadSessions() throws -> [SkiSession] {
        guard let contents = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil) else { return [] }
        var result: [SkiSession] = []
        for url in contents where url.pathExtension == "json" {
            if let data = try? Data(contentsOf: url),
               let s = try? JSONDecoder().decode(SkiSession.self, from: data) {
                result.append(s)
            }
        }
        return result.sorted { $0.startAt > $1.startAt }
    }
}

extension JSONLocalStore {
    func pruneToLimit(_ max: Int) {
        guard max > 0 else { return }
        let sessions = (try? loadSessions()) ?? []
        if sessions.count <= max { return }
        let toDelete = sessions.sorted { $0.startAt < $1.startAt }
                               .prefix(sessions.count - max)
        for s in toDelete {
            let url = dirURL.appendingPathComponent("\(s.id.uuidString).json")
            try? FileManager.default.removeItem(at: url)
        }
    }
}

/*
// JSONLocalStore.swift
extension JSONLocalStore {
    func pruneToLimit(_ max: Int) { /* no-op: 不再裁剪 */ }
    func pruneToLimitAsync(_ max: Int) async { /* no-op */ }
}
*/

// JSONLocalStore+Async.swift




extension JSONLocalStore {
    func saveSessionAsync(_ session: SkiSession) async throws {
        try await Task.detached(priority: .utility) { [self] in
            try self.saveSession(session)
        }.value
    }

    func loadSessionsAsync() async throws -> [SkiSession] {
        try await Task.detached(priority: .utility) { [self] in
            try self.loadSessions()
        }.value
    }

    func pruneToLimitAsync(_ max: Int) async {
        await Task.detached(priority: .utility) { [self] in
            self.pruneToLimit(max)
        }.value
    }
 
}
/*


*/
