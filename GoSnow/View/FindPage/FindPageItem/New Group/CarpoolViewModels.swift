//
//  CarpoolViewModels.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/11/5.
//

import Foundation

@MainActor
final class CarpoolListVM: ObservableObject {
    @Published var resorts: [Resorts_data] = []
    @Published var selectedResortId: Int?
    @Published var day: Date = Date()
    @Published var posts: [CarpoolPost] = []
    @Published var loading = false
    @Published var error: String?

    var selectedResortName: String? {
        guard let id = selectedResortId else { return nil }
        return resorts.first(where: { $0.id == id })?.name_resort
    }

    func loadResortsIfNeeded() async {
        guard resorts.isEmpty else { return }
        do {
            resorts = try await CarpoolAPI.fetchAllResorts()
            if selectedResortId == nil { selectedResortId = resorts.first?.id }
        } catch { errorMessage(error) }
    }

    func reload() async {
        guard let rid = selectedResortId else { posts = []; return }
        loading = true; defer { loading = false }
        do {
            let (s, e) = DayRange.inTimeZone("Asia/Tokyo", for: day)
            posts = try await CarpoolAPI.fetchPosts(resortID: Int(rid), start: s, end: e)
        } catch { errorMessage(error) }
    }

    private func errorMessage(_ e: Error) {
        self.error = (e as NSError).localizedDescription
    }
}

@MainActor
final class CarpoolPublishVM: ObservableObject {
    @Published var resorts: [Resorts_data] = []
    @Published var selectedResortId: Int?
    @Published var departAt: Date = Date()
    @Published var origin: String = ""
    @Published var note: String = ""
    @Published var busy = false
    @Published var error: String?

    var selectedResortName: String? {
        guard let id = selectedResortId else { return nil }
        return resorts.first(where: { $0.id == id })?.name_resort
    }

    var canSubmit: Bool {
        selectedResortId != nil && !origin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func loadResortsIfNeeded() async {
        guard resorts.isEmpty else { return }
        do { resorts = try await CarpoolAPI.fetchAllResorts() }
        catch { self.error = (error as NSError).localizedDescription }
    }

    func submit() async -> Bool {
        guard let rid = selectedResortId else { return false }
        busy = true; defer { busy = false }
        do {
            _ = try await CarpoolAPI.createPost(
                resortID: Int(rid),
                departAt: departAt,
                originText: origin,
                note: note.isEmpty ? nil : note
            )
            return true
        } catch {
            self.error = (error as NSError).localizedDescription
            return false
        }
    }
}
