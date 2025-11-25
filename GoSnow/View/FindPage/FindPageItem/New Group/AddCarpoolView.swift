//
//  AddCarpoolView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/11/5.
//

import SwiftUI
import Supabase

struct AddCarpoolView: View {
    var onPublished: (() -> Void)? = nil

    @State private var selectedResort: ResortRef? = nil
    @State private var departAt: Date = Date()
    @State private var originText: String = ""
    @State private var note: String = ""

    @State private var resorts: [ResortRef] = []       // 也支持在线搜索，这里缓存热门/最近
    @State private var searchText: String = ""
    @State private var isPublishing = false
    @State private var uploadMessage: String = ""
    @State private var showUploadAlert = false

    private var isPublishButtonEnabled: Bool {
        selectedResort != nil
        && !originText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty   // ✅ 备注必填
    }


    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("出行信息")) {
                    
                    
                    DatePicker("出发时间", selection: $departAt, displayedComponents: [.date, .hourAndMinute])
                    // 雪场搜索（内嵌）
                    TextField("搜索雪场", text: $searchText)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(.plain) // 👈 无边框
                        .padding(.vertical, 8)

                        .onChange(of: searchText) { _, key in
                            Task { await searchResorts(key) }
                        }

                    if !searchText.isEmpty {
                        List(filteredResorts, id: \.id) { r in
                            Button {
                                selectedResort = r
                                searchText = ""
                            } label: {
                                HStack {
                                    Text(r.name)
                                    if selectedResort?.id == r.id {
                                        Spacer(); Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 220)
                    } else if let r = selectedResort {
                        Text("已选择雪场：\(r.name)")
                            .font(.headline)
                            .padding(.vertical)
                    }

                 

                    TextField("出发地（如 新宿西口）", text: $originText)

                    TextField("备注（可填微信）", text: $note)
                }

                Section(footer:
                    Text("本功能仅提供信息发布与对接，平台不参与任何交易，也不承担担保或赔付责任。请自行核验对方身份、车辆与路线。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                ) {
                    if isPublishing {
                        ProgressView("发布中…")
                    } else {
                        Button("发布", action: publish)
                            .disabled(!isPublishButtonEnabled)
                    }
                }


            }
            .navigationBarTitle("发布顺风车", displayMode: .inline)
            .onAppear {
                Task { await searchResorts("") }   // 可选：加载一些默认热门雪场
            }
            .alert(isPresented: $showUploadAlert) {
                Alert(title: Text("状态"), message: Text(uploadMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    // 根据输入过滤本地数组（服务端每次搜索会刷新 resorts）
    private var filteredResorts: [ResortRef] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return resorts }
        return resorts.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    private func searchResorts(_ key: String) async {
        do {
            struct Row: Decodable { let id: Int; let name_resort: String }
            let rows: [Row] = try await DatabaseManager.shared.client
                .from("Resorts_data")
                .select("id,name_resort")
                .ilike("name_resort", pattern: key.isEmpty ? "%" : "%\(key)%")
                .limit(30)
                .execute()
                .value
            let mapped = rows.map { ResortRef(id: $0.id, name: $0.name_resort) }
            await MainActor.run { self.resorts = mapped }
        } catch {
            await MainActor.run { self.resorts = [] }
        }
    }

    private func publish() {
        guard isPublishButtonEnabled, let r = selectedResort else { return }
        isPublishing = true

        Task {
            defer {
                isPublishing = false
                showUploadAlert = true
            }
            do {
                guard let user = DatabaseManager.shared.getCurrentUser() else {
                    throw NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "未登录"])
                }

                struct Payload: Encodable {
                    let user_id: UUID
                    let resort_id: Int
                    let depart_at: String
                    let origin_text: String?
                    let note: String?
                    let is_hidden: Bool = false
                }

                let payload = Payload(
                    user_id: user.id,
                    resort_id: Int(r.id),
                    depart_at: ISO8601DateFormatter().string(from: departAt),
                    origin_text: originText.trimmingCharacters(in: .whitespacesAndNewlines),
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
                )

                try await DatabaseManager.shared.client
                    .from("carpool_posts")
                    .insert(payload)
                    .execute()

                uploadMessage = "发布成功"
                onPublished?()
            } catch {
                if let pe = error as? PostgrestError, pe.code == "409" {
                    uploadMessage = "当日该雪场你已发布过一条，可编辑/删除原帖后再发。"
                } else {
                    uploadMessage = "发布失败：\(error.localizedDescription)"
                }
            }
        }
    }
}

