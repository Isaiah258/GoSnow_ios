//
//  EditProfile.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/27.
//

import SwiftUI
import PhotosUI
import Supabase

struct EditProfile: View {
    @Environment(\.dismiss) private var dismiss

    // 初值来自全局 Profile
    @State private var nickname: String = AuthManager.shared.userProfile?.user_name ?? ""
    @State private var pickedItem: PhotosPickerItem?
    @State private var selectedAvatarImage: UIImage?

    // 状态
    @State private var uploading = false
    @State private var alertIsPresented = false
    @State private var alertMessage = ""

    private var originalNick: String { AuthManager.shared.userProfile?.user_name ?? "" }
    private var originalAvatarURL: String { AuthManager.shared.userProfile?.avatar_url ?? "" }

    private var hasChanges: Bool {
        let nameChanged = nickname.trimmingCharacters(in: .whitespacesAndNewlines) != originalNick
        let avatarChanged = selectedAvatarImage != nil
        return nameChanged || avatarChanged
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 头像卡
                    Card {
                        VStack(spacing: 14) {
                            ZStack {
                                AvatarPreview(
                                    selectedImage: selectedAvatarImage,
                                    remoteURLString: originalAvatarURL
                                )
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 2))
                                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)

                                // 浮动相册按钮
                                HStack {
                                    Spacer()
                                    VStack {
                                        Spacer()
                                        PhotosPicker(selection: $pickedItem, matching: .images) {
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .overlay(Image(systemName: "pencil")
                                                    .font(.system(size: 14, weight: .semibold)))
                                                .frame(width: 34, height: 34)
                                                .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(uploading)
                                    }
                                }
                                .frame(width: 100, height: 100)
                            }
                            Text("从相册更换头像")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }

                    // 昵称
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("昵称")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            TextField("输入昵称", text: $nickname)
                                .textInputAutocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.secondarySystemBackground))
                                )
                        }
                    }

                    // 保存
                    Button {
                        Task { await saveProfile() }
                    } label: {
                        HStack {
                            if uploading { ProgressView().tint(.white) }
                            Text(uploading ? "保存中…" : "保存")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(hasChanges ? Color.blue : Color.gray.opacity(0.4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: (hasChanges ? Color.blue : .clear).opacity(0.18), radius: 8, y: 6)
                    }
                    .disabled(!hasChanges || uploading)
                }
                .padding(16)
            }
            .navigationTitle("编辑资料")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .onChange(of: pickedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) {
                        selectedAvatarImage = ui
                    }
                }
            }
        }
        .alert(isPresented: $alertIsPresented) {
            Alert(title: Text("提示"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("好的")))
        }
    }

    // 保存逻辑（无审核）
    private func saveProfile() async {
        guard let current = DatabaseManager.shared.getCurrentUser() else {
            alert("未登录，无法保存")
            return
        }
        let nick = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nick.isEmpty else {
            alert("昵称不能为空")
            return
        }

        uploading = true
        defer { uploading = false }

        var finalAvatarURL = originalAvatarURL

        // 若选择了新头像 → 直接上传（无审核）
        if let img = selectedAvatarImage {
            do {
                let url = try await DatabaseManager.shared.uploadAvatar(for: current.id, image: img)
                finalAvatarURL = url
            } catch {
                let ns = error as NSError
                let msg = (ns.userInfo["message"] as? String) ??
                          (ns.userInfo["error"] as? String) ??
                          ns.localizedDescription
                alert("上传头像失败：\(msg)")
                return
            }

        }

        // 入库
        do {
            let updatedUser = Users(id: current.id, user_name: nick, avatar_url: finalAvatarURL)
            try await DatabaseManager.shared.client
                .from("Users")
                .upsert(updatedUser)
                .execute()

            // 刷新全局并返回
            await AuthManager.shared.bootstrap()
            await MainActor.run {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            }
        } catch {
            alert("保存资料失败，请稍后再试。")
        }
    }

    private func alert(_ text: String) {
        alertMessage = text
        alertIsPresented = true
    }
}

// MARK: - 复用小组件（与你现有一致）
private struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.07), radius: 12, y: 6)
            )
    }
}

private struct AvatarPreview: View {
    let selectedImage: UIImage?
    let remoteURLString: String?

    var body: some View {
        Group {
            if let img = selectedImage {
                Image(uiImage: img).resizable().scaledToFill()
            } else if let s = remoteURLString, s.hasPrefix("http"), let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Circle().fill(Color.gray.opacity(0.15))
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable().scaledToFill()
                    .foregroundStyle(.gray)
                    .background(Color.gray.opacity(0.12))
            }
        }
    }
}






#Preview {
    EditProfile().environmentObject(UserData())
}





/*
 private struct ModerationReply: Decodable { let code: Int; let msg: String? }
 private struct SCFEnvelope: Decodable {
     let isBase64Encoded: Bool?
     let statusCode: Int?
     let headers: [String:String]?
     let body: String?
 }

 @inline(__always)
 private func moderationRequest(_ body: [String: Any]) async throws -> ModerationReply {
     let url = URL(string: "https://eurekamoment.fit")!   // 你的函数 URL/自定义域名
     var req = URLRequest(url: url)
     req.httpMethod = "POST"
     req.setValue("application/json", forHTTPHeaderField: "Content-Type")
     req.timeoutInterval = 12
     req.httpBody = try JSONSerialization.data(withJSONObject: body)

     let (data, resp) = try await URLSession.shared.data(for: req)
     guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
         throw URLError(.badServerResponse)
     }

     // 1) 直接尝试解码 {code,msg}
     if let direct = try? JSONDecoder().decode(ModerationReply.self, from: data) {
         return direct
     }

     // 2) 尝试解包 SCF envelope
     if let env = try? JSONDecoder().decode(SCFEnvelope.self, from: data),
        let bodyText = env.body {
         let innerData = Data(bodyText.utf8)
         if let inner = try? JSONDecoder().decode(ModerationReply.self, from: innerData) {
             return inner
         }
         // 2.1) 兜底再用 JSONSerialization 从 body 里抠 code
         if let obj = try? JSONSerialization.jsonObject(with: innerData) as? [String: Any],
            let code = obj["code"] as? Int {
             return ModerationReply(code: code, msg: obj["msg"] as? String)
         }
     }

     // 3) 最后兜底：从最外层 data 粗暴找 code
     if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let code = obj["code"] as? Int {
         return ModerationReply(code: code, msg: obj["msg"] as? String)
     }

     throw NSError(domain: "Moderation", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid moderation response"])
 }

 private func checkTextModeration(for text: String) async -> Bool {
     do {
         let r = try await moderationRequest(["type": "nickname", "text": text])
         return r.code == 0
     } catch {
         print("nickname moderation error:", error)
         return false
     }
 }

 private func checkImageModeration(image: UIImage) async -> Bool {
     let resized = image.resized(maxSide: 512)
     guard let data = resized.jpegData(compressionQuality: 0.7) else { return false }
     let b64 = data.base64EncodedString()
     do {
         let r = try await moderationRequest(["type": "avatars", "imageBase64": b64])
         return r.code == 0
     } catch {
         print("avatar moderation error:", error)
         return false
     }
 }
 */



/*
 import SwiftUI
 import Supabase
 import PhotosUI

 struct EditProfile: View {
     @EnvironmentObject var userData: UserData
     @State private var nickname: String = ""
     @State private var selectedAvatarName: String?
     @Environment(\.dismiss) var dismiss
     @State private var showAvatarSelection = false
     @State private var alertIsPresented = false
     @State private var alertMessage = ""
     @State private var pickedItem: PhotosPickerItem?
     @State private var selectedAvatarImage: UIImage?   // ← 用户自选的真实图片
     @State private var uploading = false
     
     private struct ModerationReply: Decodable {
         let code: Int
         let msg: String?
     }

     let avatarOptions = ["avatar_ice", "avatar_bottlecap", "avatar_donut"]

     var body: some View {
         NavigationStack {
             VStack(spacing: 20) {
                 if let img = selectedAvatarImage {
                     Image(uiImage: img)
                         .resizable()
                         .frame(width: 100, height: 100)
                         .clipShape(Circle())
                 } else if let avatarName = selectedAvatarName, let uiImage = UIImage(named: avatarName) {
                     Image(uiImage: uiImage)
                         .resizable()
                         .frame(width: 100, height: 100)
                         .clipShape(Circle())
                 } else if let urlString = userData.avatarName, urlString.hasPrefix("http"),
                           let url = URL(string: urlString) {
                     AsyncImage(url: url) { phase in
                         switch phase {
                         case .success(let img): img.resizable()
                         default:
                             Image(systemName: "person.crop.circle.fill").resizable().foregroundColor(.gray)
                         }
                     }
                     .frame(width: 100, height: 100)
                     .clipShape(Circle())
                 } else if let avatar = userData.userAvatar {
                     avatar.resizable().frame(width: 100, height: 100).clipShape(Circle())
                 } else {
                     Image(systemName: "person.crop.circle.fill")
                         .resizable()
                         .frame(width: 100, height: 100)
                         .clipShape(Circle())
                 }


                 PhotosPicker(selection: $pickedItem, matching: .images, photoLibrary: .shared()) {
                     Text("选择头像")
                         .font(.callout)
                         .padding(.horizontal, 12)
                         .padding(.vertical, 8)
                         .background(Color(.systemGray6))
                         .cornerRadius(8)
                 }
                 .onChange(of: pickedItem) { _, newItem in
                     guard let item = newItem else { return }
                     Task {
                         if let data = try? await item.loadTransferable(type: Data.self),
                            let ui = UIImage(data: data) {
                             // 先把预览更新（本地显示）
                             selectedAvatarImage = ui
                             selectedAvatarName = nil    // 取消“内置头像”选择
                         }
                     }
                 }


                 TextField("输入昵称", text: $nickname)
                     .padding()
                     .background(Color(.systemGray6))
                     .cornerRadius(8)
                     .padding(.horizontal)

                 Button(action: {
                     Task { await saveProfile() }
                 }) {
                     Text("保存")
                         .font(.headline)
                         .foregroundColor(.white)
                         .padding()
                         .frame(width: 200, height: 50)
                         .background(Color.blue)
                         .cornerRadius(10)
                 }
                 .padding()

                 Spacer()
             }
             .toolbar {
                 ToolbarItem(placement: .navigationBarLeading) {
                     Button("取消") {
                         dismiss()
                     }
                 }
             }
             .onAppear {
                 nickname = userData.userName ?? ""
                 selectedAvatarName = userData.avatarName
             }
             .onChange(of: selectedAvatarName) {
                 if let avatarName = selectedAvatarName, let uiImage = UIImage(named: avatarName) {
                     userData.userAvatar = Image(uiImage: uiImage)
                     userData.avatarName = avatarName
                 }
             }
             .alert(isPresented: $alertIsPresented) {
                 Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
             }
         }
     }

     // MARK: - 保存资料前进行昵称审核
     private func saveProfile() async {
         guard let user = DatabaseManager.shared.getCurrentUser() else { return }

         // 文本审核（昵称）
         let nameOK = await checkTextModeration(for: nickname)
         guard nameOK else {
             alertMessage = "昵称内容不合规，请重新输入。"
             alertIsPresented = true
             return
         }

         var finalAvatarURLOrName: String = userData.avatarName ?? "default_avatar"

         // 若用户新选了图片 → 先图片审核，再上传
         if let img = selectedAvatarImage {
             let ok = await checkImageModeration(image: img)
             guard ok else {
                 alertMessage = "头像未通过审核，请更换图片。"
                 alertIsPresented = true
                 return
             }

             uploading = true
             defer { uploading = false }

             do {
                 let publicURL = try await DatabaseManager.shared.uploadAvatar(for: user.id, image: img)
                 finalAvatarURLOrName = publicURL   // 用 URL 覆盖
             } catch {
                 alertMessage = "上传头像失败，请稍后再试。"
                 alertIsPresented = true
                 return
             }
         } else if let builtin = selectedAvatarName {
             // 选择了内置头像
             finalAvatarURLOrName = builtin
         }

         do {
             let updatedUser = Users(id: user.id, user_name: nickname, avatar_url: finalAvatarURLOrName)
             try await DatabaseManager.shared.client
                 .from("Users")
                 .upsert(updatedUser)
                 .execute()

             // 更新本地
             await MainActor.run {
                 userData.userName = nickname
                 userData.avatarName = finalAvatarURLOrName
                 if !finalAvatarURLOrName.hasPrefix("http") {
                     // 内置头像：给一个本地 Image，避免下一次刷新前的空白
                     if let ui = UIImage(named: finalAvatarURLOrName) {
                         userData.userAvatar = Image(uiImage: ui)
                     }
                 } else {
                     userData.userAvatar = nil // 远程 URL 用 AsyncImage
                 }
                 alertMessage = "资料已保存"
                 alertIsPresented = true
                 dismiss()
             }
         } catch {
             alertMessage = "保存资料失败，请稍后再试。"
             alertIsPresented = true
         }
     }


     // MARK: - 云函数审核昵称内容（BizType: nickname）
     private func checkTextModeration(for text: String) async -> Bool {
         guard let url = URL(string: "https://eurekamoment.fit") else { return false } // 替换为你的域名

         var request = URLRequest(url: url)
         request.httpMethod = "POST"
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")

         let body: [String: Any] = [
             "text": text,
             "type": "nickname" // 使用你为昵称审核设置的 BizType
         ]
         request.httpBody = try? JSONSerialization.data(withJSONObject: body)

         do {
             let (data, _) = try await URLSession.shared.data(for: request)

             // 🔽 把 response 先解包成 result
             let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
             let code = json?["code"] as? Int

             return code == 0 // 0 表示审核通过
         } catch {
             print("审核请求异常：\(error)")
             return false
         }
     }
     
     func checkImageModeration(image: UIImage) async -> Bool {
         // ⚠️ 如果你还没有上线图片审核接口，先返回 true 以便不阻塞流程
         // return true
         
         // 真正请求
         let resized = image.resized(maxSide: 512)
         guard let data = resized.jpegData(compressionQuality: 0.7) else { return false }
         let b64 = data.base64EncodedString()

         guard let url = URL(string: "https://eurekamoment.fit") else { return false } // 替换为你的图片审核 API
         var req = URLRequest(url: url)
             req.httpMethod = "POST"
             req.setValue("application/json", forHTTPHeaderField: "Content-Type")
             req.httpBody = try? JSONSerialization.data(withJSONObject: [
                 "imageBase64": b64,
                 "type": "avatars"   // ← 使用你的 BizType
             ])

         do {
             let (respData, _) = try await URLSession.shared.data(for: req)
             if let json = try JSONSerialization.jsonObject(with: respData) as? [String: Any],
                let code = json["code"] as? Int {
                 return code == 0
             }
         } catch {
             print("图片审核异常：\(error)")
         }
         return false
     }


 }

 #Preview {
     EditProfile()
         .environmentObject(UserData())
 }
 
 */



/*
 9.30
 import SwiftUI
 import Supabase
 import PhotosUI
 import UIKit

 struct EditProfile: View {
     @EnvironmentObject var userData: UserData
     @Environment(\.dismiss) private var dismiss

     // 输入/选择
     @State private var nickname: String = ""
     @State private var pickedItem: PhotosPickerItem?
     @State private var selectedAvatarImage: UIImage?   // 仅支持相册选图

     // UI 状态
     @State private var uploading = false
     @State private var alertIsPresented = false
     @State private var alertMessage = ""

     var body: some View {
         NavigationStack {
             ScrollView {
                 VStack(spacing: 16) {

                     // MARK: 头像卡片（无渐变描边）
                     Card {
                         VStack(spacing: 14) {
                             ZStack {
                                 AvatarPreview(
                                     selectedImage: selectedAvatarImage,
                                     remoteURLString: userData.avatarName
                                 )
                                 .frame(width: 100, height: 100)
                                 .clipShape(Circle())
                                 .overlay(
                                     Circle().stroke(.white.opacity(0.9), lineWidth: 2) // 细白边
                                 )
                                 .shadow(color: .black.opacity(0.06), radius: 8, y: 3)

                                 // 浮动相册按钮
                                 HStack {
                                     Spacer()
                                     VStack {
                                         Spacer()
                                         PhotosPicker(selection: $pickedItem, matching: .images) {
                                             Circle()
                                                 .fill(.ultraThinMaterial)
                                                 .overlay(
                                                     Image(systemName: "pencil")
                                                         .font(.system(size: 14, weight: .semibold))
                                                 )
                                                 .frame(width: 34, height: 34)
                                                 .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
                                         }
                                         .buttonStyle(.plain)
                                         .disabled(uploading)
                                     }
                                 }
                                 .frame(width: 100, height: 100)
                             }

                             Text("从相册更换头像")
                                 .font(.footnote)
                                 .foregroundStyle(.secondary)
                         }
                         .frame(maxWidth: .infinity)
                         .padding(.vertical, 8)
                     }

                     // MARK: 昵称卡片（无额外提示文案）
                     Card {
                         VStack(alignment: .leading, spacing: 10) {
                             Text("昵称")
                                 .font(.subheadline)
                                 .foregroundStyle(.secondary)

                             HStack(spacing: 10) {
                                 TextField("输入昵称", text: $nickname)
                                     .textInputAutocapitalization(.none)
                                     .disableAutocorrection(true)
                             }
                             .padding(12)
                             .background(
                                 RoundedRectangle(cornerRadius: 12, style: .continuous)
                                     .fill(Color(.secondarySystemBackground))
                             )
                         }
                     }

                     // MARK: 保存按钮（纯蓝色）
                     Button {
                         Task { await saveProfile() }
                     } label: {
                         Text(uploading ? "保存中…" : "保存")
                             .font(.headline)
                             .foregroundStyle(.white)
                             .frame(maxWidth: .infinity, minHeight: 52)
                             .background(Color.blue)
                             .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                             .shadow(color: .blue.opacity(0.18), radius: 8, y: 6)
                     }
                     .disabled(uploading)
                 }
                 .padding(16)
             }
             .navigationTitle("编辑资料")
             .toolbar {
                 ToolbarItem(placement: .navigationBarLeading) {
                     Button("取消") { dismiss() }
                 }
             }

             // iOS 17 的 onChange 签名（两参数）
             .onChange(of: pickedItem) { _, newItem in
                 guard let newItem else { return }
                 Task {
                     if let data = try? await newItem.loadTransferable(type: Data.self),
                        let ui = UIImage(data: data) {
                         selectedAvatarImage = ui
                     }
                 }
             }

             // 初始填充 + 联通性自检
             .onAppear {
                 nickname = userData.userName ?? ""
                 Task { await pingModeration() }   // ← 临时自检，看 Xcode 控制台输出
             }

             .alert(isPresented: $alertIsPresented) {
                 Alert(title: Text("提示"),
                       message: Text(alertMessage),
                       dismissButton: .default(Text("OK")))
             }
         }
     }

     // MARK: - 保存逻辑
     private func saveProfile() async {
         guard let user = DatabaseManager.shared.getCurrentUser() else { return }

         let nick = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
         guard !nick.isEmpty else {
             alertMessage = "昵称不能为空"
             alertIsPresented = true
             return
         }

         // 1) 审核昵称
         guard await checkTextModeration(for: nick) else {
             alertMessage = "昵称内容不合规，请重新输入。"
             alertIsPresented = true
             return
         }

         // 2) 头像：如有新图 → 审核 → 上传
         var finalAvatarURL = userData.avatarName ?? ""  // 现有远程 URL（若无则为空串）
         if let img = selectedAvatarImage {
             guard await checkImageModeration(image: img) else {
                 alertMessage = "头像未通过审核，请更换图片。"
                 alertIsPresented = true
                 return
             }

             uploading = true
             defer { uploading = false }
             do {
                 let publicURL = try await DatabaseManager.shared.uploadAvatar(for: user.id, image: img)
                 finalAvatarURL = publicURL
             } catch {
                 alertMessage = "上传头像失败，请稍后再试。"
                 alertIsPresented = true
                 return
             }
         }

         // 3) 入库
         do {
             let updatedUser = Users(id: user.id, user_name: nick, avatar_url: finalAvatarURL)
             try await DatabaseManager.shared.client
                 .from("Users")
                 .upsert(updatedUser)
                 .execute()

             await MainActor.run {
                 userData.userName = nick
                 userData.avatarName = finalAvatarURL.isEmpty ? userData.avatarName : finalAvatarURL
                 userData.userAvatar = nil // 远程 URL 由 AsyncImage/KF 加载
                 alertMessage = "资料已保存"
                 alertIsPresented = true
                 UIImpactFeedbackGenerator(style: .light).impactOccurred()
                 dismiss()
             }
         } catch {
             alertMessage = "保存资料失败，请稍后再试。"
             alertIsPresented = true
         }
     }

     // MARK: - 审核请求（对接你的云函数域名）——强日志版
     private struct ModerationReply: Decodable {
         let code: Int
         let msg: String?
         // 你若想要拿到 suggestion/label，可再加字段
     }
     private struct SCFEnvelope: Decodable {
         let isBase64Encoded: Bool?
         let statusCode: Int?
         let headers: [String:String]?
         let body: String?
     }

     @inline(__always)
     private func moderationRequest(_ body: [String: Any]) async throws -> ModerationReply {
         let urlString = "https://eurekamoment.fit"   // ← 确认就是这个，无斜杠/空格/旧域名
         guard let url = URL(string: urlString) else {
             throw URLError(.badURL)
         }

         var req = URLRequest(url: url)
         req.httpMethod = "POST"
         req.setValue("application/json", forHTTPHeaderField: "Content-Type")
         req.timeoutInterval = 15
         req.httpBody = try JSONSerialization.data(withJSONObject: body)

         // 关键日志：出站请求
         if let bodyText = String(data: req.httpBody ?? Data(), encoding: .utf8) {
             print("🔵 [Moderation] request to \(urlString) body=", bodyText)
         }

         do {
             let (data, resp) = try await URLSession.shared.data(for: req)
             let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
             print("🟣 [Moderation] http status=", status, "raw len=", data.count)

             // 1) 直接尝试解码 {code,msg}
             if let direct = try? JSONDecoder().decode(ModerationReply.self, from: data) {
                 print("🟢 [Moderation] direct decode ->", direct)
                 return direct
             }

             // 2) 尝试解包 SCF envelope
             if let env = try? JSONDecoder().decode(SCFEnvelope.self, from: data),
                let bodyText = env.body {
                 print("🟢 [Moderation] envelope status=\(env.statusCode ?? -1) body=", bodyText)
                 let innerData = Data(bodyText.utf8)
                 if let inner = try? JSONDecoder().decode(ModerationReply.self, from: innerData) {
                     return inner
                 }
                 // 2.1) 兜底再从 body 里抠 code
                 if let obj = try? JSONSerialization.jsonObject(with: innerData) as? [String: Any],
                    let code = obj["code"] as? Int {
                     return ModerationReply(code: code, msg: obj["msg"] as? String)
                 }
             }

             // 3) 打印原始文本，便于确认返回内容
             if let txt = String(data: data, encoding: .utf8) {
                 print("🟠 [Moderation] unknown response text=", txt)
             }

             throw NSError(domain: "Moderation",
                           code: -1,
                           userInfo: [NSLocalizedDescriptionKey: "Invalid moderation response"])
         } catch {
             let ns = error as NSError
             print("🔴 [Moderation] network error: domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription)")
             // 常见错误速查：
             // -1003  找不到主机（DNS）
             // -1009  无网络
             // -1200  SSL 握手失败
             // -1202  证书不受信
             // -1022  ATS 拦截（通常是 HTTP 或证书不合规）
             throw error
         }
     }

     private func checkTextModeration(for text: String) async -> Bool {
         do {
             let r = try await moderationRequest(["type": "nickname", "text": text])
             return r.code == 0
         } catch {
             print("nickname moderation error:", error)
             return false
         }
     }

     private func checkImageModeration(image: UIImage) async -> Bool {
         let resized = image.resized(maxSide: 512)
         guard let data = resized.jpegData(compressionQuality: 0.7) else { return false }
         let b64 = data.base64EncodedString()
         do {
             let r = try await moderationRequest(["type": "avatars", "imageBase64": b64])
             return r.code == 0
         } catch {
             print("avatar moderation error:", error)
             return false
         }
     }

     // MARK: - 联通性自检（GET）
     private func pingModeration() async {
         let url = URL(string: "https://eurekamoment.fit")!
         var req = URLRequest(url: url)
         req.httpMethod = "GET"
         req.timeoutInterval = 10
         do {
             let (data, resp) = try await URLSession.shared.data(for: req)
             let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
             print("🧪 [Moderation] PING status=\(code) len=\(data.count)")
             if let t = String(data: data, encoding: .utf8) {
                 print("🧪 [Moderation] PING text=", t)
             }
         } catch {
             let ns = error as NSError
             print("🧪🔴 [Moderation] PING error domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription)")
         }
     }
 }

 // MARK: - 复用小组件

 private struct Card<Content: View>: View {
     @ViewBuilder var content: Content
     var body: some View {
         VStack(alignment: .leading, spacing: 12) { content }
             .padding(16)
             .background(
                 RoundedRectangle(cornerRadius: 16, style: .continuous)
                     .fill(.ultraThinMaterial)
                     .overlay(
                         RoundedRectangle(cornerRadius: 16, style: .continuous)
                             .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                     )
                     .shadow(color: .black.opacity(0.07), radius: 12, y: 6)
             )
     }
 }

 private struct AvatarPreview: View {
     let selectedImage: UIImage?
     let remoteURLString: String?

     var body: some View {
         Group {
             if let img = selectedImage {
                 Image(uiImage: img).resizable().scaledToFill()
             } else if let s = remoteURLString, s.hasPrefix("http"), let url = URL(string: s) {
                 AsyncImage(url: url) { phase in
                     switch phase {
                     case .success(let img): img.resizable().scaledToFill()
                     default:
                         ZStack {
                             Circle().fill(Color.gray.opacity(0.15))
                             Image(systemName: "person.crop.circle.fill")
                                 .font(.system(size: 36))
                                 .foregroundStyle(.gray)
                         }
                     }
                 }
             } else {
                 Image(systemName: "person.crop.circle.fill")
                     .resizable().scaledToFill()
                     .foregroundStyle(.gray)
                     .background(Color.gray.opacity(0.12))
             }
         }
     }
 }









 #Preview {
     EditProfile().environmentObject(UserData())
 }
 */

