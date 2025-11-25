//
//  ResortsPostComposerView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/10/9.
//

import SwiftUI
import PhotosUI
import Storage
import Supabase

// 你的模型：
// struct ResortRef: Hashable, Identifiable { var id: Int; var name: String }

struct ResortsPostComposerView: View {
    // 兼容你原来的调用方式：ResortsPostComposerView { didPost in ... }
    var onFinish: (_ didPost: Bool) -> Void
    init(onFinish: @escaping (_ didPost: Bool) -> Void) {
        self.onFinish = onFinish
    }

    @Environment(\.dismiss) private var dismiss

    // 正文
    @State private var content: String = ""
    @FocusState private var isEditorFocused: Bool
    private let maxChars = 500

    // 雪场搜索（内嵌）
    @State private var selectedResort: ResortRef? = nil
    @State private var searchText: String = ""
    @State private var filteredResorts: [ResortRef] = []
    @FocusState private var isSearchFocused: Bool
    @State private var searchTask: Task<Void, Never>? = nil

    // 图片
    @State private var attachments: [UIImage] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showImageLimitWarning = false

    // 状态
    @State private var isPosting = false
    @State private var errMsg: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // === 雪场选择（内嵌搜索）===
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("选择雪场", systemImage: "mappin.and.ellipse")
                                .font(.headline)
                            Spacer()
                            if let r = selectedResort {
                                Button {
                                    withAnimation { selectedResort = nil }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(r.name).lineLimit(1)
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(.thinMaterial)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                TextField("搜索雪场以发布", text: $searchText)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .focused($isSearchFocused)
                                if !searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 12).padding(.vertical, 10)
                        }
                        .frame(height: 44)

                        if !filteredResorts.isEmpty {
                            VStack(spacing: 6) {
                                ForEach(filteredResorts, id: \.id) { r in
                                    Button {
                                        withAnimation {
                                            selectedResort = r
                                            searchText = ""
                                            filteredResorts = []
                                            isSearchFocused = false
                                            dismissKeyboard()
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "checkmark.circle")
                                                .foregroundStyle(.blue)
                                            Text(r.name).foregroundStyle(.primary)
                                            Spacer()
                                        }
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(.tertiarySystemBackground))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                            )
                        }
                    }

                    // === 正文（无边框 TextEditor + 500 字）===
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("正文", systemImage: "square.and.pencil")
                                .font(.headline)
                            Spacer()
                            Text("\(content.count)/\(maxChars)")
                                .font(.caption)
                                .foregroundStyle(content.count > maxChars ? .red : .secondary)
                        }

                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("这里输入正文")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $content)
                                .focused($isEditorFocused)
                                .frame(minHeight: 140)
                                .scrollContentBackground(.hidden)
                                .padding(.top, 4)
                                .onChange(of: content) { _, new in
                                    if new.count > maxChars { content = String(new.prefix(maxChars)) }
                                }
                        }
                    }

                    // === 图片（最多 4 张）===
                    VStack(alignment: .leading, spacing: 10) {
                        Label("图片", systemImage: "photo.on.rectangle")
                            .font(.headline)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(attachments.enumerated()), id: \.offset) { idx, img in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 86, height: 86)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                                            )
                                        Button {
                                            withAnimation {
                                                attachments.remove(at: idx)
                                                showImageLimitWarning = false
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundStyle(.white)
                                                .shadow(radius: 1)
                                        }
                                        .offset(x: 6, y: -6)
                                    }
                                }

                                if attachments.count < 4 {
                                    PhotosPicker(
                                        selection: $pickerItems,
                                        maxSelectionCount: 4 - attachments.count,
                                        matching: .images
                                    ) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(.secondarySystemBackground))
                                                .frame(width: 86, height: 86)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                                                )
                                            Image(systemName: "plus.viewfinder")
                                                .font(.title3)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .onChange(of: pickerItems) { _, items in
                                        showImageLimitWarning = false
                                        Task {
                                            var newImgs: [UIImage] = []
                                            for item in items {
                                                if let data = try? await item.loadTransferable(type: Data.self),
                                                   let img = UIImage(data: data) {
                                                    newImgs.append(img)
                                                }
                                            }
                                            attachments.append(contentsOf: newImgs.prefix(4 - attachments.count))
                                            if newImgs.count > (4 - attachments.count) {
                                                showImageLimitWarning = true
                                            }
                                            pickerItems = []
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }

                        if showImageLimitWarning {
                            Text("最多只能选择 4 张图片")
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.leading, 2)
                        }
                    }

                    if let msg = errMsg {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(msg)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            // 键盘易消失
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture { dismissKeyboard() }
            .simultaneousGesture(DragGesture().onChanged { _ in dismissKeyboard() })

            .navigationTitle("发布")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onFinish(false)           // 取消回调
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isPosting ? "发布中…" : "发布") {
                        Task { await submit() }
                    }
                    .disabled(isPosting || !isValid)
                }

                // 键盘上方工具条
                ToolbarItemGroup(placement: .keyboard) {
                    Button("收起") {
                        isEditorFocused = false
                        isSearchFocused = false
                        dismissKeyboard()
                    }
                    Spacer()
                    Text("\(content.count)/\(maxChars)")
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: searchText) { _, key in
                searchTask?.cancel()
                searchTask = Task { [key] in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await searchResorts(key)
                }
            }
        }
    }

    // 校验
    private var isValid: Bool {
        selectedResort != nil &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        attachments.count <= 4
    }

    // 关闭键盘（避免扩展重名）
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    // 搜索雪场
    private func searchResorts(_ key: String) async {
        guard !key.isEmpty else {
            await MainActor.run { filteredResorts = [] }
            return
        }
        do {
            let c = DatabaseManager.shared.client
            struct Row: Decodable { let id: Int; let name_resort: String }
            let rows: [Row] = try await c
                .from("Resorts_data")
                .select("id,name_resort")
                .ilike("name_resort", pattern: "%\(key)%")
                .limit(30)
                .execute()
                .value
            await MainActor.run {
                filteredResorts = rows.map { ResortRef(id: $0.id, name: $0.name_resort) }
            }
        } catch {
            await MainActor.run { filteredResorts = [] }
        }
    }

    // 提交：插入 post → 上传图片 → 关联图片
    private func submit() async {
        guard isValid, let resort = selectedResort else { return }
        isPosting = true; defer { isPosting = false }

        do {
            struct InsertPost: Encodable { let body: String?; let resort_id: Int }
            struct ResortPostRow: Decodable { let id: UUID }

            let client = DatabaseManager.shared.client
            let inserted: [ResortPostRow] = try await client
                .from("resorts_post")
                .insert(InsertPost(
                    body: content.trimmingCharacters(in: .whitespacesAndNewlines),
                    resort_id: resort.id
                ))
                .select()
                .limit(1)
                .execute()
                .value

            guard let postRow = inserted.first else {
                throw NSError(domain: "post", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "insert returned empty"])
            }

            // 上传图片
            var urls: [String] = []
            for (idx, uiImg) in attachments.enumerated() {
                if let url = try await uploadImage(uiImg, keyPrefix: postRow.id.uuidString, index: idx) {
                    urls.append(url)
                }
            }
            if !urls.isEmpty {
                struct PostImageRowInsert: Encodable { let post_id: UUID; let url: String }
                let payload = urls.map { PostImageRowInsert(post_id: postRow.id, url: $0) }
                _ = try await client.from("resorts_post_images").insert(payload).execute()
            }

            onFinish(true)   // ✅ 成功回调
            dismiss()
        } catch {
            errMsg = error.localizedDescription
        }
    }

    // 上传到 Storage（Public 桶），返回公有 URL
    private func uploadImage(_ image: UIImage, keyPrefix: String, index: Int) async throws -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let path = "\(keyPrefix)/\(index)_\(Int(Date().timeIntervalSince1970)).jpg"

        let opts = FileOptions(contentType: "image/jpeg")
        try await DatabaseManager.shared.client
            .storage
            .from("resorts-post-images")
            .upload(path, data: data, options: opts)

        let publicURL = try DatabaseManager.shared.client
            .storage
            .from("resorts-post-images")
            .getPublicURL(path: path)
        return publicURL.absoluteString
    }
}

