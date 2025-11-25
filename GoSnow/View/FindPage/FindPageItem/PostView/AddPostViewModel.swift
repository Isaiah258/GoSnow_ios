//
//  AddPostViewModel.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/5/14.
//

import SwiftUI
import PhotosUI
import Supabase
import Kingfisher

// ✅ 插入使用的结构体
struct PostInsertPayload: Codable {
    let user_id: UUID
    let content: String
    let image_urls: [String]?
    let post_resort_id: Int?
}

// ✅ 内容审核返回结构体
struct ModerationResponse: Codable {
    let pass: Bool
}


@MainActor
class AddPostViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var attachments: [UIImage] = []
    @Published var pickerItems: [PhotosPickerItem] = []
    @Published var isPosting = false
    @Published var errorMessage: String?
    private var prefetcher: ImagePrefetcher?
    // 雪场选择相关
    @Published var resorts: [Resorts_data] = []
    @Published var searchText: String = ""
    @Published var selectedResort: Resorts_data?
    @Published var statusMessage: String?   // ✅ 新增

    
    var selectedResortId: Int? {
        selectedResort?.id
    }

    private let userId: UUID
    private let onComplete: () -> Void

    init(userId: UUID, onComplete: @escaping () -> Void) {
        self.userId = userId
        self.onComplete = onComplete
        fetchResorts()
    }

    func loadImages(onLimit: ((Bool) -> Void)? = nil) {
        Task {
            var newImages: [UIImage] = []

            for item in pickerItems {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    // 在这里统一处理为 JPEG 格式（UIImage 已经可以是 HEIC）
                    UIGraphicsBeginImageContext(image.size)
                    image.draw(in: CGRect(origin: .zero, size: image.size))
                    let jpegImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    if let jpegImage = jpegImage {
                        newImages.append(jpegImage)
                    }
                }
            }

            let remaining = max(0, 4 - attachments.count)
            let willOverflow = newImages.count > remaining

            attachments.append(contentsOf: newImages.prefix(remaining))
            pickerItems = []

            onLimit?(willOverflow)
        }
    }



    func post() async {
        // ✅ 防抖 & 入参校验
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty else { return }
        if isPosting { return }
        await MainActor.run { isPosting = true; errorMessage = nil }

        let client = DatabaseManager.shared.client

        // 1) 会话
        guard let session = try? await client.auth.session else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            await MainActor.run {
                self.errorMessage = "未登录，无法发布"
                self.isPosting = false
            }
            return
        }
        let uid = session.user.id

        // 2) 上传图片（路线B：无需 uid 前缀）
        var imageUrls: [String] = []
        if !attachments.isEmpty {
            do {
                for img in attachments {
                    guard let data = img.compressedJPEGData(maxSizeKB: 500) else { continue }
                    let path = "post-media/\(UUID().uuidString).jpg"
                    try await client.storage.from("post").upload(path, data: data)
                    let url = try client.storage.from("post").getPublicURL(path: path)
                    imageUrls.append(url.absoluteString)
                }
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                await MainActor.run {
                    self.errorMessage = "图片上传失败：\(error.localizedDescription)"
                    self.isPosting = false
                }
                return
            }
        }

        // 3) 插入帖子
        do {
            let payload = PostInsertPayload(
                user_id: uid,
                content: content,
                image_urls: imageUrls.isEmpty ? nil : imageUrls, // 列已统一为 jsonb 数组
                post_resort_id: selectedResortId
            )
            let res = try await client.from("Post").insert(payload).execute()
            guard res.status == 201 else {
                await MainActor.run {
                    self.errorMessage = "发布失败：\(res.status)"
                    self.isPosting = false
                }
                return
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "发布失败：\(error.localizedDescription)"
                self.isPosting = false
            }
            return
        }

        // 4) ✅ 成功反馈 + 刷新列表 + 返回列表页
        await MainActor.run {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.isPosting = false

            // 通知“全部帖子”刷新（ResortPostsView 如需只刷某雪场，可带 resortId）
            NotificationCenter.default.post(
                name: .postDidCreate,
                object: nil,
                userInfo: ["resortId": self.selectedResortId as Any]
            )

            // 回调上交给父导航（PostMainView 里会 pop 回列表）
            self.onComplete()
        }
    }





    

    /*
     func post() {
         // ✅ 防止重复进入
         guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty else { return }
         if isPosting { return }

         isPosting = true
         errorMessage = nil
         statusMessage = nil

         Task {
             let client = DatabaseManager.shared.client

             guard let session = try? await client.auth.session else {
                 self.errorMessage = "未登录，无法发布（无会话）"
                 self.isPosting = false                 // ✅ 失败也复位
                 return
             }
             let uidLower = session.user.id.uuidString.lowercased()

             var imageUrls: [String] = []
             if !attachments.isEmpty {
                 do {
                     for image in attachments {
                         guard let data = image.compressedJPEGData(maxSizeKB: 500) else { continue }
                         let path = "post-media/\(uidLower)/\(UUID().uuidString).jpg"
                         try await client.storage.from("post").upload(path, data: data)
                         let url = try client.storage.from("post").getPublicURL(path: path)
                         imageUrls.append(url.absoluteString)
                     }
                 } catch {
                     self.errorMessage = "图片上传失败：\(error.localizedDescription)"
                     self.isPosting = false             // ✅ 失败也复位
                     return
                 }
             }

             do {
                 let payload = PostInsertPayload(
                     user_id: session.user.id,
                     content: content,
                     image_urls: imageUrls.isEmpty ? nil : imageUrls,
                     post_resort_id: selectedResortId
                 )
                 let res = try await client.from("Post").insert(payload).execute()
                 guard res.status == 201 else {
                     self.errorMessage = "发布失败：\(res.status)"
                     self.isPosting = false             // ✅ 失败也复位
                     return
                 }
             } catch {
                 self.errorMessage = "发布失败：\(error.localizedDescription)"
                 self.isPosting = false                 // ✅ 失败也复位
                 return
             }

             // ✅ 成功：立即关 loading，提示，并回调
             UIImpactFeedbackGenerator(style: .light).impactOccurred()
             self.isPosting = false
             self.statusMessage = "发布成功"

             let rid = self.selectedResortId
             NotificationCenter.default.post(name: .postDidCreate, object: nil, userInfo: ["resortId": rid as Any])

             DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                 self?.onComplete()
                 self?.statusMessage = nil
             }
         }
     }
     
     */


    private func moderateContent(text: String, imageUrls: [String]) async throws -> Bool {
        guard let url = URL(string: "https://eurekamoment.fit") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "text": text,
            "imageUrls": imageUrls
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ModerationResponse.self, from: data)
        return response.pass
    }

    func fetchResorts() {
        Task {
            do {
                let manager = DatabaseManager.shared
                resorts = try await manager.client.from("Resorts_data").select().execute().value
            } catch {
                print("❌ Failed to fetch resorts: \(error)")
            }
        }
    }

    var filteredResorts: [Resorts_data] {
        if searchText.isEmpty {
            return []
        } else {
            return resorts.filter { $0.name_resort.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    
    func prefetchImages(for posts: [Post]) {
        let urls: [URL] =
            posts.compactMap { URL(string: $0.avatar_url ?? "") } +
            posts.flatMap { $0.image_urls?.compactMap { URL(string: $0) } ?? [] }

        prefetcher?.stop()
        prefetcher = ImagePrefetcher(urls: urls)
        prefetcher?.start()
    }
}



/*
 import SwiftUI
 import PhotosUI
 import Supabase

 // ✅ 插入使用的结构体（避免 [String: Any] 的 Codable 报错）
 struct PostInsertPayload: Codable {
     let user_id: UUID
     let content: String
     let image_urls: [String]?
 }

 // ✅ 内容审核返回结构体（不需要建表，仅用于解析审核服务返回值）
 struct ModerationResponse: Codable {
     let pass: Bool
 }

 @MainActor
 class AddPostViewModel: ObservableObject {
     @Published var content: String = ""
     @Published var attachments: [UIImage] = []
     @Published var pickerItems: [PhotosPickerItem] = []
     @Published var isPosting = false
     @Published var errorMessage: String?

     private let userId: UUID
     private let onComplete: () -> Void

     init(userId: UUID, onComplete: @escaping () -> Void) {
         self.userId = userId
         self.onComplete = onComplete
     }

     func loadImages() {
         Task {
             for item in pickerItems {
                 if let data = try? await item.loadTransferable(type: Data.self),
                    let image = UIImage(data: data) {
                     attachments.append(image)
                 }
             }
             pickerItems.removeAll()
         }
     }

     func post() {
         guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty else {
             return
         }

         isPosting = true
         errorMessage = nil

         Task {
             do {
                 let client = DatabaseManager.shared.client
                 var imageUrls: [String] = []

                 for image in attachments {
                     guard let data = image.jpegData(compressionQuality: 0.8) else { continue }
                     let uuid = UUID().uuidString
                     let path = "post-media/\(userId.uuidString)/\(uuid).jpg"

                     try await client.storage.from("post").upload(path, data: data)
                     let publicUrl = try client.storage.from("post").getPublicURL(path: path)
                     imageUrls.append(publicUrl.absoluteString)
                 }

                 let isSafe = try await moderateContent(text: content, imageUrls: imageUrls)
                 guard isSafe else {
                     errorMessage = "内容审核未通过"
                     isPosting = false
                     return
                 }

                 let payload = PostInsertPayload(
                     user_id: userId,
                     content: content,
                     image_urls: imageUrls.isEmpty ? nil : imageUrls
                 )

                 let res = try await client
                     .from("Post")
                     .insert(payload)
                     .execute()

                 guard res.status == 201 else {
                     throw NSError(domain: "PostUpload", code: res.status, userInfo: [NSLocalizedDescriptionKey: "上传失败：\(res.status)"])
                 }

                 onComplete()
             } catch {
                 errorMessage = "发布失败：\(error.localizedDescription)"
                 print("❌ post error:", error)
             }

             isPosting = false
         }
     }

     private func moderateContent(text: String, imageUrls: [String]) async throws -> Bool {
         guard let url = URL(string: "https://eurekamoment.fit") else {
             throw URLError(.badURL)
         }

         var request = URLRequest(url: url)
         request.httpMethod = "POST"
         request.addValue("application/json", forHTTPHeaderField: "Content-Type")

         let body: [String: Any] = [
             "text": text,
             "imageUrls": imageUrls
         ]

         request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

         let (data, _) = try await URLSession.shared.data(for: request)
         let response = try JSONDecoder().decode(ModerationResponse.self, from: data)
         return response.pass
     }
 }
 
 */


