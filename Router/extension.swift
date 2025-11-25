//
//  extension.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/7/25.
//

import Foundation
import UIKit
import Storage

extension Post: Hashable {
    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


extension UIImage {
    /// 压缩 JPEG 图片至指定大小（KB），默认最大 500KB
    func compressedJPEGData(maxSizeKB: Int = 500) -> Data? {
        let maxBytes = maxSizeKB * 1024
        var compression: CGFloat = 1.0
        guard var data = self.jpegData(compressionQuality: compression) else { return nil }

        // 尝试逐步压缩直到小于目标大小或压缩比过低
        while data.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            if let newData = self.jpegData(compressionQuality: compression) {
                data = newData
            } else {
                break
            }
        }

        return data
    }
}

extension DatabaseManager {
    /// 上传头像到 avatars/<uid>/avatar_*.jpg 并返回公开 URL（公有桶）
    func uploadAvatar(for userId: UUID, image: UIImage) async throws -> String {
        // A) 可选：确认当前已登录（命中 RLS 的前提）
        _ = try await client.auth.user()

        // B) 处理图片：居中裁剪 + 缩放 + JPEG
        let square  = image.centerCroppedSquare()
        let resized = square.resized(maxSide: 512)
        guard let data = resized.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "Avatar", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "JPEG 编码失败"])
        }

        // C) 路径必须以 <uid>/ 开头，才能命中策略
        let bucket = "avatars"
        let ts       = Int(Date().timeIntervalSince1970)
        let filename = "avatar_\(ts)_\(UUID().uuidString.prefix(8)).jpg"
        let path     = "\(userId.uuidString)/\(filename)"

        // D) 上传（沿用你发帖代码的旧签名 + FileOptions）
        try await client.storage
            .from(bucket)
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))

        // E) 公开 URL（沿用你发帖代码的 API 命名）
        let publicURL = try client.storage
            .from(bucket)
            .getPublicURL(path: path)
            .absoluteString

        return publicURL
    }
}


/*
extension DatabaseManager {
    /// 上传头像并返回公开 URL
    func uploadAvatar(for userId: UUID, image: UIImage) async throws -> String {
        // 1) 居中裁剪成方图 + 缩放 512
        let square = image.centerCroppedSquare()
        let resized = square.resized(maxSide: 512)
        guard let data = resized.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "Avatar", code: -1, userInfo: [NSLocalizedDescriptionKey: "JPEG 编码失败"])
        }

        // 2) 生成路径
        let ts = Int(Date().timeIntervalSince1970)
        let filename = "avatar_\(ts)_\(UUID().uuidString.prefix(8)).jpg"
        let path = "\(userId.uuidString)/\(filename)"  // <uid>/avatar_xxx.jpg

        // 3) 上传
        try await client.storage
            .from("avatars")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))

        // 4) 公网 URL
        let publicURL = try client.storage.from("avatars").getPublicURL(path: path)

        // 5) 保存到 Users.avatar_url
        _ = try await client
            .from("Users")
            .update(["avatar_url": publicURL.absoluteString])
            .eq("id", value: userId.uuidString)
            .execute()

        return publicURL.absoluteString
    }
}

*/

extension UIImage {
    func centerCroppedSquare() -> UIImage {
        let size = min(size.width, size.height)
        let x = (self.size.width - size) / 2.0
        let y = (self.size.height - size) / 2.0
        let rect = CGRect(x: x, y: y, width: size, height: size)

        guard let cg = self.cgImage?.cropping(to: rect) else { return self }
        return UIImage(cgImage: cg, scale: self.scale, orientation: self.imageOrientation)
    }

    func resized(maxSide: CGFloat) -> UIImage {
        let side = max(size.width, size.height)
        guard side > maxSide else { return self }
        let scale = maxSide / side
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}




extension DatabaseManager {
    /// 失物招领：上传 1 张图片并返回公开 URL（桶：lost_and_found_images）
    func uploadLostFoundImage(for userId: UUID, image: UIImage) async throws -> String {
        // 中心裁剪成方形 + 等比缩放（最长边 1024）
        let square = image.centerCroppedSquare()
        let resized = square.resized(maxSide: 1024)
        guard let data = resized.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "LAF", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "JPEG 编码失败"])
        }

        // 路径：<uid>/laf_<ts>_<rand>.jpg
        let ts = Int(Date().timeIntervalSince1970)
        let filename = "laf_\(ts)_\(UUID().uuidString.prefix(8)).jpg"
        let path = "\(userId.uuidString)/\(filename)"

        // 上传
        try await client.storage
            .from("lost_and_found_images")
            .upload(path, data: data,
                    options: FileOptions(contentType: "image/jpeg", upsert: true))

        // 公开 URL（你的 SDK 版本可能标成 throws；这里用 try? 兼容）
        if let url = try? client.storage
            .from("lost_and_found_images")
            .getPublicURL(path: path) {
            return url.absoluteString
        } else {
            // 兜底：如果 SDK 改动导致失败，可换成你服务端签 URL 的方案
            throw NSError(domain: "LAF", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "获取公开 URL 失败"])
        }
    }
}


enum SessionsAggregator {
    /// 计算总里程、总时长、在雪天数（自然日去重，duration>0 记一天）
    static func totals<T>(
        from sessions: [T],
        distanceKm: (T) -> Double,
        durationSec: (T) -> Int,
        date: (T) -> Date
    ) -> (distanceKm: Double, durationSec: Int, daysOnSnow: Int) {
        var totalKm = 0.0
        var totalSec = 0
        var daySet = Set<Date>()
        let cal = Calendar.current

        for s in sessions {
            let dur = durationSec(s)
            totalKm += distanceKm(s)
            totalSec += dur
            if dur > 0 {
                daySet.insert(cal.startOfDay(for: date(s)))
            }
        }
        return (totalKm, totalSec, daySet.count)
    }

    /// 聚合某一天
    static func daily<T>(
        from sessions: [T],
        on day: Date,
        distanceKm: (T) -> Double,
        durationSec: (T) -> Int,
        date: (T) -> Date
    ) -> (distanceKm: Double, durationSec: Int)? {
        let cal = Calendar.current
        let target = cal.startOfDay(for: day)
        var km = 0.0, sec = 0
        var found = false

        for s in sessions where cal.isDate(cal.startOfDay(for: date(s)), inSameDayAs: target) {
            km += distanceKm(s)
            sec += durationSec(s)
            found = true
        }
        return found ? (km, sec) : nil
    }
}
