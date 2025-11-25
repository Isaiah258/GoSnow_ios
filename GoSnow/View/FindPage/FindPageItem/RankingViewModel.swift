//
//  RankingViewModel.swift
//  GoSnow
//
//  Created by federico Liu on 2024/11/6.
//
/*
import Foundation
import Supabase

class RankingViewModel: ObservableObject {
    @Published var friendsRanking: [SkiRecord] = []

    func fetchFriendsRanking() {
        guard let currentUser = DatabaseManager.shared.getCurrentUser() else {
            print("User not authenticated")
            return
        }

        let today = DateFormatter.iso8601.string(from: Date()) // Get current date in ISO 8601 format
        
        // Query Supabase for skiing records of friends from today
        Task {
            do {
                let query = try await DatabaseManager.shared.client
                    .from("SkiRecords")
                    .select()
                    .eq("user_id", value: currentUser.id) // Adjust query if you need to fetch data of friends
                    .gte("date", value: today)
                    .lte("date", value: today)
                    .order("distance", ascending: false)
                    .execute()

                // Process the response and update the ranking
                if let records = query.data as? [[String: Any]] {
                    self.friendsRanking = records.compactMap { record in
                        // Decode the SkiRecord from the Supabase response
                        guard let jsonData = try? JSONSerialization.data(withJSONObject: record, options: []) else { return nil }
                        return try? JSONDecoder().decode(SkiRecord.self, from: jsonData)
                    }
                }
            } catch {
                print("Error fetching rankings: \(error)")
            }
        }
    }
}


*/
