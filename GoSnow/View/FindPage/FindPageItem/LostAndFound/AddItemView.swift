//
//  AddItemView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/10/3.
//

import SwiftUI
import Supabase

struct AddItemView: View {
    // ✅ 新增：发布成功回调（可选）
    var onPublished: (() -> Void)? = nil

    @State private var itemDescription: String = ""
    @State private var contactInfo: String = ""
    @State private var selectedResort: String = ""
    @State private var selectedType: String = "lost"
    @State private var resorts: [Resorts_data] = []
    @State private var isPublishing: Bool = false
    @State private var showUploadAlert: Bool = false
    @State private var uploadMessage: String = ""
    @State private var isLoading: Bool = true
    @State private var searchText: String = ""

    private var isPublishButtonEnabled: Bool {
        !itemDescription.isEmpty &&
        !contactInfo.isEmpty &&
        !selectedResort.isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("发布类型")) {
                    Picker("Type", selection: $selectedType) {
                        Text("丢失").tag("lost")
                        Text("发现").tag("found")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("物品信息")) {
                    TextField("描述一下物品", text: $itemDescription)
                }

                Section(header: Text("联系方式")) {
                    TextField("填写能够与你取得联系的途径", text: $contactInfo)
                }

                Section {
                    TextField("搜索雪场", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical)

                    if !searchText.isEmpty {
                        List(filteredResorts, id: \.id) { resort in
                            Button(action: {
                                selectedResort = resort.name_resort
                                searchText = ""
                            }) {
                                Text(resort.name_resort)
                            }
                        }
                        .frame(maxHeight: 220)
                    } else {
                        if !selectedResort.isEmpty {
                            Text("已选择雪场: \(selectedResort)")
                                .font(.headline)
                                .padding(.vertical)
                        }
                    }
                }

                if isPublishing {
                    ProgressView("发布中...")
                } else {
                    Button(action: publishItem) {
                        Text("发布")
                    }
                    .disabled(!isPublishButtonEnabled)
                }
            }
            .navigationBarTitle("发布物品", displayMode: .inline)
            .alert(isPresented: $showUploadAlert) {
                Alert(
                    title: Text("Upload Status"),
                    message: Text(uploadMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                fetchResorts()
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

    func fetchResorts() {
        Task {
            do {
                let manager = DatabaseManager.shared
                resorts = try await manager.client
                    .from("Resorts_data")
                    .select()
                    .order("name_resort", ascending: true)
                    .execute()
                    .value
            } catch {
                print("Failed to fetch resorts: \(error)")
            }
        }
    }

    private func publishItem() {
        guard isPublishButtonEnabled else { return }
        isPublishing = true

        Task {
            defer {
                isPublishing = false
                showUploadAlert = true
            }

            do {
                let user = DatabaseManager.shared.getCurrentUser()
                guard let userId = user?.id else {
                    throw NSError(
                        domain: "Authentication",
                        code: 401,
                        userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]
                    )
                }

                let resortId = getResortIdByName(selectedResort)
                guard resortId != 0 else {
                    throw NSError(
                        domain: "Validation",
                        code: 400,
                        userInfo: [NSLocalizedDescriptionKey: "请选择有效的雪场"]
                    )
                }

                let itemData = LostAndFoundItems(
                    id: nil,
                    resort_id: resortId,
                    item_description: itemDescription,
                    contact_info: contactInfo,
                    type: selectedType,
                    user_id: userId,
                    created_at: nil // 由数据库默认填充
                )

                try await DatabaseManager.shared.client
                    .from("LostAndFoundItems")
                    .insert(itemData)
                    .execute()

                uploadMessage = "上传成功"
                clearForm()

                // ✅ 通知父级刷新并由父级关闭 sheet
                onPublished?()
            } catch {
                uploadMessage = "上传失败: \(error.localizedDescription)"
                print("Publish Error: \(error)")
            }
        }
    }

    func getResortIdByName(_ name: String) -> Int {
        return resorts.first { $0.name_resort == name }?.id ?? 0
    }

    private func clearForm() {
        itemDescription = ""
        contactInfo = ""
        selectedResort = ""
        selectedType = "lost"
    }
}

// 预览
struct AddItemView_Previews: PreviewProvider {
    static var previews: some View {
        AddItemView()
    }
}



/*
 import SwiftUI
 import Supabase

 struct AddItemView: View {
     @State private var itemDescription: String = ""
     @State private var contactInfo: String = ""
     @State private var selectedResort: String = ""
     @State private var selectedType: String = "lost"
     @State private var resorts: [Resorts_data] = []
     @State private var isPublishing: Bool = false
     @State private var showUploadAlert: Bool = false
     @State private var uploadMessage: String = ""
     @State private var isLoading: Bool = true
     @State private var searchText: String = ""

     private var isPublishButtonEnabled: Bool {
         !itemDescription.isEmpty &&
         !contactInfo.isEmpty &&
         !selectedResort.isEmpty
     }

     var body: some View {
         NavigationView {
             Form {
                 Section(header: Text("发布类型")) {
                     Picker("Type", selection: $selectedType) {
                         Text("丢失").tag("lost")
                         Text("发现").tag("found")
                     }
                     .pickerStyle(SegmentedPickerStyle())
                 }
                 
                 Section(header: Text("物品信息")) {
                     TextField("描述一下物品", text: $itemDescription)
                 }

                 Section(header: Text("联系方式")) {
                     TextField("填写能够与你取得联系的途径", text: $contactInfo)
                 }
                 
                 Section {
                     TextField("搜索雪场", text: $searchText)
                         .textFieldStyle(RoundedBorderTextFieldStyle())
                         .padding(.vertical)

                     if !searchText.isEmpty {
                         List(filteredResorts, id: \.id) { resort in
                             Button(action: {
                                 selectedResort = resort.name_resort
                                 searchText = ""
                             }) {
                                 Text(resort.name_resort)
                             }
                         }
                     } else {
                         if !selectedResort.isEmpty {
                             Text("已选择雪场: \(selectedResort)")
                                 .font(.headline)
                                 .padding(.vertical)
                         }
                     }
                 }

                 if isPublishing {
                     ProgressView("发布中...")
                 } else {
                     Button(action: publishItem) {
                         Text("发布")
                     }
                     .disabled(!isPublishButtonEnabled)
                 }
             }
             .navigationBarTitle("发布物品")
             .alert(isPresented: $showUploadAlert) {
                 Alert(title: Text("Upload Status"), message: Text(uploadMessage), dismissButton: .default(Text("OK")))
             }
             .onAppear {
                 fetchResorts()
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

     func fetchResorts() {
         Task {
             do {
                 let manager = DatabaseManager.shared
                 resorts = try await manager.client.from("Resorts_data").select().execute().value
             } catch {
                 print("Failed to fetch resorts: \(error)")
             }
         }
     }

     private func publishItem() {
         guard isPublishButtonEnabled else { return }
         isPublishing = true

         Task {
             do {
                 let user = DatabaseManager.shared.getCurrentUser()
                 guard let userId = user?.id else {
                     throw NSError(domain: "Authentication", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                 }

                 let itemData = LostAndFoundItems(
                     id: nil,
                     resort_id: getResortIdByName(selectedResort),
                     item_description: itemDescription,
                     contact_info: contactInfo,
                     type: selectedType,
                     user_id: userId,
                     created_at: nil // 不需要提供 created_at 的值
                 )

                 try await DatabaseManager.shared.client
                     .from("LostAndFoundItems")
                     .insert(itemData)
                     .execute()

                 uploadMessage = "上传成功"
                 clearForm()
             } catch {
                 uploadMessage = "上传失败: \(error.localizedDescription)"
                 print("Publish Error: \(error)") // 打印完整的错误信息进行调试
             }
             isPublishing = false
             showUploadAlert = true
         }
     }

     func getResortIdByName(_ name: String) -> Int {
         return resorts.first { $0.name_resort == name }?.id ?? 0
     }

     private func clearForm() {
         itemDescription = ""
         contactInfo = ""
         selectedResort = ""
         selectedType = "lost"
     }
 }

 // 预览
 struct AddItemView_Previews: PreviewProvider {
     @State static var isPresented = true
     static var userId = "sample_user_id"

     static var previews: some View {
         AddItemView()
     }
 }
*/







 

