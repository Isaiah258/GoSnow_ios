//
//  CarpoolAPI.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/11/5.
//

import Foundation
import Supabase

enum CarpoolAPI {
    static var client: SupabaseClient { DatabaseManager.shared.client }
}

// CarpoolAPI.swift
extension CarpoolAPI {
    static func fetchAllResorts() async throws -> [Resorts_data] {
        try await client
            .from("Resorts_data")
            .select() // ✅ 取全列，避免解码缺字段
            .order("name_resort", ascending: true)
            .execute()
            .value
    }
}


extension CarpoolAPI {
    static func createPost(
        resortID: Int,
        departAt: Date,
        originText: String,
        note: String?
    ) async throws -> CarpoolPost {
        guard let u = DatabaseManager.shared.getCurrentUser() else {
            throw NSError(domain: "Carpool", code: 401, userInfo: [NSLocalizedDescriptionKey: "未登录"])
        }
        let payload = CarpoolPostInsert(
            user_id: u.id,
            resort_id: resortID,
            depart_at: ISO8601Z.string(departAt),
            origin_text: originText,
            note: (note?.isEmpty == true) ? nil : note
        )

        return try await client
            .from("carpool_posts")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    static func fetchPosts(
        resortID: Int,
        start: Date,
        end: Date
    ) async throws -> [CarpoolPost] {
        try await client
            .from("carpool_posts")
            .select()
            .eq("resort_id", value: resortID)   
            .gte("depart_at", value: ISO8601Z.string(start))
            .lt("depart_at",  value: ISO8601Z.string(end))
            .order("depart_at", ascending: true)
            .execute()
            .value
    }

    static func deletePost(id: UUID) async throws {
        _ = try await client
            .from("carpool_posts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    static func fetchMyPosts() async throws -> [CarpoolPost] {
        try await client
            .from("carpool_posts")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }
}

extension CarpoolAPI {
    struct CancelPatch: Encodable {
        let is_hidden: Bool
        let canceled_at: String?
    }

    static func cancelPost(id: UUID) async throws {
        let patch = CancelPatch(is_hidden: true, canceled_at: ISO8601Z.string(Date()))
        _ = try await client
            .from("carpool_posts")
            .update(patch)
            .eq("id", value: id.uuidString)
            .execute()
    }

    static func restorePost(id: UUID) async throws { // 可选：撤销取消
        let patch = CancelPatch(is_hidden: false, canceled_at: nil)
        _ = try await client
            .from("carpool_posts")
            .update(patch)
            .eq("id", value: id.uuidString)
            .execute()
    }
}
