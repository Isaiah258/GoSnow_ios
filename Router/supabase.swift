//
//  Data.swift
//  GoSnow
//
//  Created by federico Liu on 2024/9/8.
//

import Foundation
import Supabase

import SQLite3

public class DatabaseManager{
    static let shared = DatabaseManager()
    
    private init(){}
    
    
    let client = SupabaseClient(
      supabaseURL: URL(string: "https://crals6q5g6h44cne3j40.baseapi.memfiredb.com")!,
      supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImV4cCI6MzMwMjA1OTI5MSwiaWF0IjoxNzI1MjU5MjkxLCJpc3MiOiJzdXBhYmFzZSJ9.FYvFCQVIJn-iL-t9lxYOSzD__jJZMQMDtynLh-wTyHQ"
    )
    //获取用户
    func getCurrentUser() -> User? {
            return client.auth.currentUser
    }
    
    func uploadSkiRecord(_ record: SkiRecord) async {
        do {
            // Attempt to upsert the record
            let response = try await client
                .from("SkiRecords")
                .upsert(record)
                .execute()
            
            print("记录上传成功: \(response)")
        } catch {
            print("记录上传失败: \(error.localizedDescription)")
        }
    }

}







struct Country: Decodable, Identifiable {
  let id: Int
  let name: String
}




struct Coach: Codable, Identifiable {
    let id: UUID
    let price: Int
    let contentCoach: String
    let contactCoach: String
}


struct Resorts_data: Codable, Identifiable, Hashable{
    let id: Int
    let uuid_resorts: UUID
    let name_resort: String
    let trail_count: Int?
    let trail_length: Float?
    let lift_count: Int?
    let carpet_count: Int?
    let park: String?
    let backcountry: String?
    let night: String?
    let map_url: String?
}

struct DailySnowConditions: Codable, Identifiable {
    let id: Int
    let resort_id: Int
    let date: Date
    let condition: String
    let created_at: String?  
}

struct ResortFeedback: Codable {
    var id: Int
    var resort_id: Int
    var resortfeedback: String
    var created_at: Date?
}


struct LiftWaitTime: Codable {
    var id: Int
    var resort_id: Int
    var date: Date
    var wait_time: String
    var created_at: Date?
}

struct LostAndFoundItems: Codable, Identifiable{
    let id: Int?
    let resort_id: Int
    let item_description: String
    let contact_info: String
    let type: String
    let user_id: UUID
    let created_at: Date?
    
}



struct Post: Codable, Identifiable{
    let id: Int?
    let user_id: UUID
    let content: String
    let like_count: Int?
    let comment_count: Int?
    let post_resort_id: Int
    let created_at: Date?
    let Users: Users? // Users 是一个嵌套的结构体
    var user_name: String? // 改为可变属性
    var avatar_url: String? // 改为可变属性
    // 联表查询字段
    var user: User?
    let image_urls: [String]?
}

struct PostComments: Codable, Identifiable {
    let id: Int?
    let post_id: Int
    let user_id: UUID
    let content: String
    let created_at: Date?
    let parent_comment_id: Int?
    //let Users: Users?
}

struct PostCommentLikes: Codable {
    let comment_id: Int
    let user_id: UUID
}

struct UserBrief: Decodable, Hashable {
    let id: UUID
    let user_name: String?
    let avatar_url: String?
}

struct CommentLikeCount: Decodable {
    let comment_id: Int
    let count: Int
}

struct PostCommentItem: Decodable, Identifiable, Hashable {
    let id: Int?
    let post_id: Int
    let user_id: UUID
    let content: String
    let created_at: Date?
    let parent_comment_id: Int?
    let user: UserBrief?   // ← 来自 Users 的联表字段
}
struct PostNotifications: Codable, Identifiable {
    let id: Int
    let user_id: UUID
    let from_user_id: UUID
    let post_id: Int?
    let comment_id: Int?
    let type: String
    let created_at: Date
    let is_read: Bool

    //  联表结果：用户信息（来自 Users 表）
    let from_user: Users?
    
    //  加入被引用的评论或帖子内容（联表）
    let comment: PostComments?
    let post: Post?
    
    var actor_name: String?
    var actor_avatar_url: String?
}



struct NotificationInsertPayload: Codable {
    let user_id: UUID
    let from_user_id: UUID
    let comment_id: Int?
    let post_id: Int
    let type: String
}




struct Friends: Codable, Identifiable {
    let id: String
    let user_id: String
    let friend_id: String
    let status: String
}

struct FriendRequest: Encodable {
    let userId: String
    let friendId: String
    let status: String
}

struct BreakingReports: Codable, Identifiable {
    let id: Int
    let user_id: UUID
    let report_content: String
}

struct FeedBackForUs: Codable, Identifiable {
    let id: Int
    let content: String
    let contact: String
}

struct Report: Codable, Identifiable {
    let id: Int
    let post_id: Int
    let reporter_id: UUID
}


struct SkiRecord: Codable, Identifiable {
    let id: UUID?
    let user_id: UUID
    let date: String // 格式化的日期字符串 (ISO 8601 格式推荐)
    let distance: Double // 滑行的里程数，单位是公里
    let time: Int // 滑行时间，以秒为单位

    init(id: UUID? = nil, user_id: UUID, date: Date, distance: Double, time: Int) {
        self.id = id
        self.user_id = user_id
        self.date = ISO8601DateFormatter().string(from: date) // 将 Date 转换为 ISO 8601 字符串
        self.distance = distance
        self.time = time
    }
}


struct sport_data: Codable, Identifiable{
    let id: UUID
    let total_distance: Int
    let total_days: Int
}

struct sport_record: Codable, Identifiable{
    let id: UUID
    let sport_time: Int
    let sport_length: Int
    let sport_caloies: Int
}

struct Users: Codable, Identifiable{
    let id: UUID
    let user_name: String
    let avatar_url: String?
}


struct lost_and_found: Codable, Identifiable{
    let id: UUID
    let item_name: String
    let lostandfound_time: Date
    let contact_infoL: String
    let item_description: String
}

struct area: Codable, Identifiable{
    let id: Int
    let area: String
}

struct Replies: Codable, Identifiable {
    let id: Int
    let post_id: Int
    let user_id: UUID
    let content: String
}



// 定义一个只包含插入字段的新类型
struct NewReply: Codable {
  let post_id: Int
  let user_id: String
  let content: String
}

//ranking算法
enum RankingPeriod {
    case today, week
}

struct PostLikes: Codable, Identifiable {
    let id: Int?        // 若表里没有自增 id，可以删掉这一列
    let post_id: Int
    let user_id: UUID
}



/*
// Struct for leaderboard row data
struct RankingRowData: Identifiable, Codable {
    let id: UUID
    let user_id: UUID
    let total_distance: Double
}

// Enum for ranking period with date range calculation
extension DatabaseManager {
    enum RankingPeriod {
        case today
        case thisWeek

        var dateRange: (start: Date, end: Date) {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            switch self {
            case .today:
                return (start: today, end: today)
            case .thisWeek:
                let weekAgo = calendar.date(byAdding: .day, value: -6, to: today)!
                return (start: weekAgo, end: today)
            }
        }
    }
    
    // Fetch rankings with date range filtering
    func fetchRankings(for period: RankingPeriod) async throws -> [RankingRowData] {
        // Calculate the date range based on the selected period
        let dateRange = period.dateRange
        let dateFormatter = ISO8601DateFormatter()
        let startDate = dateFormatter.string(from: dateRange.start)
        let endDate = dateFormatter.string(from: dateRange.end)
        
        // Perform the query with the calculated date range
        let response = try await client
            .from("SkiRecords")
            .select("user_id, sum(distance) as total_distance")
            .gte("date", value: startDate)
            .lte("date", value: endDate)
            .order("total_distance", ascending: false)
            .limit(10) // Limit to top 10 rankings
            .get() // Use `.get()` to directly parse into `[RankingRowData]`
        
        // The response is now directly parsed into `[RankingRowData]`
        return response
    }
}



*/


//雪场数据
/*
 HStack {
 Text("Trail Count:")
 Text(resorts_data.trail_count != nil ? "\(resorts_data.trail_count!)" : "N/A") // 如果 trail_count 为空，显示 "N/A"
}
*/

/*func fetchresorts_data() async throws -> [resorts_data] {
    let query = try await client
            .from("resorts_data")
            .select()
            .execute()
    guard let data = query.data as? [[String: Any]] else {
            throw NSError(domain: "Data parsing error", code: -1, userInfo: nil)
        }

        do {
            let resorts = try JSONDecoder().decode([resorts_data].self, from: JSONSerialization.data(withJSONObject: data))
            return resorts
        } catch {
            print("Error decoding resorts: \(error)")
            throw error
        }
    
    
}
*/
