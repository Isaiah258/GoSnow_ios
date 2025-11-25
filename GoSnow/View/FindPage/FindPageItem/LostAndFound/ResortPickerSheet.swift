//
//  ResortPickerSheet.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/17.
//

import SwiftUI

struct ResortPickerSheet: View {
    let resorts: [Resorts_data]
    @Binding var selectedResortId: Int?
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var filtered: [Resorts_data] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return resorts }
        return resorts.filter { $0.name_resort.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectedResortId = nil
                        dismiss()
                        onDone()
                    } label: {
                        HStack {
                            Text("所有雪场")
                            if selectedResortId == nil {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Section {
                    ForEach(filtered, id: \.id) { r in
                        Button {
                            selectedResortId = r.id
                            dismiss()
                            onDone()
                        } label: {
                            HStack {
                                Text(r.name_resort)
                                if selectedResortId == r.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索雪场")
            .navigationTitle("选择雪场")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                        onDone()
                    }
                }
            }
        }
    }
}


