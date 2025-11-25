//
//  AddPostView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/10/3.
//

import SwiftUI
import PhotosUI

struct AddPostView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: AddPostViewModel
    @FocusState private var isEditorFocused: Bool
    @State private var showImageLimitWarning = false

    private let maxChars = 500   // 轻量字数上限，避免误触长文本

    init(userId: UUID, onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddPostViewModel(userId: userId, onComplete: onComplete))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // === 雪场选择 ===
                VStack(alignment: .leading, spacing: 10) {

                    HStack {
                        Label("选择雪场", systemImage: "mappin.and.ellipse")
                            .font(.headline)
                        Spacer()
                        if let selected = viewModel.selectedResort {
                            // 已选雪场：可一键清除
                            Button {
                                withAnimation { viewModel.selectedResort = nil }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(selected.name_resort).lineLimit(1)
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
                            TextField("搜索雪场以发布", text: $viewModel.searchText)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .focused($isEditorFocused)
                            if !viewModel.searchText.isEmpty {
                                Button {
                                    viewModel.searchText = ""
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

                    if !viewModel.filteredResorts.isEmpty {
                        // 轻量下拉建议：卡片感 + 小阴影
                        VStack(spacing: 6) {
                            ForEach(viewModel.filteredResorts, id: \.id) { resort in
                                Button {
                                    withAnimation {
                                        viewModel.selectedResort = resort
                                        viewModel.searchText = ""
                                        UIApplication.shared.endEditing()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundStyle(.blue)
                                        Text(resort.name_resort)
                                            .foregroundStyle(.primary)
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

                // === 文本输入 ===
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("正文", systemImage: "square.and.pencil")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.content.count)/\(maxChars)")
                            .font(.caption)
                            .foregroundStyle(viewModel.content.count > maxChars ? .red : .secondary)
                    }

                    ZStack(alignment: .topLeading) {
                        if viewModel.content.isEmpty {
                            Text("这里输入正文")
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: Binding(
                            get: { viewModel.content },
                            set: { viewModel.content = String($0.prefix(maxChars)) }
                        ))
                        .focused($isEditorFocused)
                        .frame(minHeight: 140)
                        // 隐藏系统默认背景，确保完全“无框感”
                        .scrollContentBackground(.hidden)
                        .padding(.top, 4)           // 轻微内边距，避免文字贴边
                    }
                }

                // === 图片预览 + 选择 ===
                VStack(alignment: .leading, spacing: 10) {
                    Label("图片", systemImage: "photo.on.rectangle")
                        .font(.headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(viewModel.attachments.enumerated()), id: \.offset) { index, img in
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
                                            viewModel.attachments.remove(at: index)
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

                            if viewModel.attachments.count < 4 {
                                PhotosPicker(
                                    selection: $viewModel.pickerItems,
                                    maxSelectionCount: 4 - viewModel.attachments.count,
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
                                .onChange(of: viewModel.pickerItems) {
                                    showImageLimitWarning = false
                                    viewModel.loadImages { isOverLimit in
                                        showImageLimitWarning = isOverLimit
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

                // 错误/提示
                if let error = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        // 让键盘更容易消失（滑动 / 点空白 / 任意拖动）
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture { UIApplication.shared.endEditing() }
        .simultaneousGesture(DragGesture().onChanged { _ in UIApplication.shared.endEditing() })

        .navigationTitle("发布雪圈")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            //ToolbarItem(placement: .navigationBarLeading) {
             //   Button("取消") { dismiss() }
          //  }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    guard !viewModel.isPosting else { return }
                    UIApplication.shared.endEditing()
                    Task { await viewModel.post() }   // ✅ 在异步上下文里调用
                } label: {
                    if viewModel.isPosting { ProgressView() } else { Text("发布") }
                }

                .disabled(
                    viewModel.isPosting ||
                    (viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.attachments.isEmpty) ||
                    viewModel.selectedResort == nil
                )
            }


            // 键盘上方工具条：一键收起 + 计数
            ToolbarItemGroup(placement: .keyboard) {
                Button("收起") {
                    isEditorFocused = false
                    UIApplication.shared.endEditing()
                }
                Spacer()
                Text("\(viewModel.content.count)/\(maxChars)")
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            viewModel.fetchResorts()
            // 初次聚焦，方便直接输入
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isEditorFocused = true
            }
        }
    }
}

// MARK: - 预览（可直接看导航样式）
#Preview("AddPostView Light") {
    NavigationStack {
        AddPostView(userId: UUID()) { }
    }
    .environment(\.colorScheme, .light)
}



// MARK: - 背景点击收起键盘
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}



extension Notification.Name {
    static let postDidCreate = Notification.Name("postDidCreate")
}






/*
 import SwiftUI
 import PhotosUI

 struct AddPostView: View {
     @Environment(\.dismiss) private var dismiss

     @StateObject private var viewModel: AddPostViewModel
     @FocusState private var isEditorFocused: Bool
     @State private var showImageLimitWarning = false

     // 不再接收 isPresented 绑定
     init(userId: UUID, onComplete: @escaping () -> Void) {
         _viewModel = StateObject(
             wrappedValue: AddPostViewModel(userId: userId, onComplete: onComplete)
         )
     }

     var body: some View {
         // ⛔️ 不要再包 NavigationStack（这会与父栈竞争）
         ScrollView {
             VStack(spacing: 16) {
                 // === 雪场选择 ===
                 VStack(alignment: .leading, spacing: 12) {
                     ZStack(alignment: .leading) {
                         if viewModel.searchText.isEmpty {
                             HStack {
                                 Text("搜索雪场以发布")
                                     .foregroundColor(.blue)
                                     .padding(.horizontal, 14)
                                     .padding(.vertical, 10)
                             }
                         }
                         TextField("", text: $viewModel.searchText)
                             .autocapitalization(.none)
                             .disableAutocorrection(true)
                             .padding(.horizontal, 14)
                             .padding(.vertical, 10)
                             .background(
                                 RoundedRectangle(cornerRadius: 25)
                                     .stroke(Color.blue, lineWidth: 1)
                             )
                     }

                     if !viewModel.searchText.isEmpty {
                         ScrollView {
                             LazyVStack(alignment: .leading, spacing: 6) {
                                 ForEach(viewModel.filteredResorts, id: \.id) { resort in
                                     Button {
                                         viewModel.selectedResort = resort
                                         viewModel.searchText = ""
                                         UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                     } label: {
                                         Text(resort.name_resort)
                                             .padding(.vertical, 8)
                                             .padding(.horizontal, 14)
                                             .background(
                                                 RoundedRectangle(cornerRadius: 25)
                                                     .stroke(Color.blue, lineWidth: 1)
                                             )
                                             .foregroundColor(.blue)
                                     }
                                 }
                             }
                         }
                         .frame(maxHeight: 140)
                     } else if let selected = viewModel.selectedResort {
                         Text("已选择雪场：\(selected.name_resort)")
                             .font(.subheadline)
                             .foregroundColor(.secondary)
                             .padding(.top, 4)
                     }
                 }

                 // === 文本输入 ===
                 ZStack(alignment: .topLeading) {
                     if viewModel.content.isEmpty {
                         Text("有什么新鲜事？")
                             .foregroundColor(.secondary)
                             .padding(.horizontal, 4)
                             .padding(.vertical, 8)
                     }
                     TextEditor(text: $viewModel.content)
                         .frame(minHeight: 120)
                         .focused($isEditorFocused)
                 }
                 .padding(4)
                 .onAppear {
                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                         isEditorFocused = true
                     }
                 }

                 // === 图片预览 + 选择 ===
                 ScrollView(.horizontal, showsIndicators: false) {
                     HStack(spacing: 12) {
                         ForEach(Array(viewModel.attachments.enumerated()), id: \.offset) { index, img in
                             ZStack(alignment: .topTrailing) {
                                 Image(uiImage: img)
                                     .resizable()
                                     .scaledToFill()
                                     .frame(width: 80, height: 80)
                                     .clipped()
                                     .cornerRadius(6)

                                 Button {
                                     viewModel.attachments.remove(at: index)
                                     showImageLimitWarning = false
                                 } label: {
                                     Image(systemName: "xmark.circle.fill")
                                         .foregroundColor(.white)
                                         .background(Circle().fill(Color.black.opacity(0.6)))
                                 }
                                 .offset(x: 6, y: -6)
                             }
                         }

                         if viewModel.attachments.count < 4 {
                             PhotosPicker(
                                 selection: $viewModel.pickerItems,
                                 maxSelectionCount: 4 - viewModel.attachments.count,
                                 matching: .images
                             ) {
                                 ZStack {
                                     RoundedRectangle(cornerRadius: 15)
                                         .stroke(Color.blue, lineWidth: 1)
                                         .frame(width: 80, height: 80)

                                     Image(systemName: "camera")
                                         .font(.title2)
                                         .foregroundColor(.blue)
                                 }
                             }
                             .onChange(of: viewModel.pickerItems) {
                                 showImageLimitWarning = false
                                 viewModel.loadImages { isOverLimit in
                                     showImageLimitWarning = isOverLimit
                                 }
                             }
                         }
                     }
                     .padding(.horizontal, 4)
                 }

                 // 错误/提示
                 if let error = viewModel.errorMessage {
                     Text(error).foregroundColor(.red).font(.subheadline)
                 }
                 if showImageLimitWarning {
                     Text("最多只能选择 4 张图片")
                         .foregroundColor(.red)
                         .font(.caption)
                         .padding(.leading, 8)
                 }
             }
             .padding()
         }
         .navigationTitle("发布雪圈")
         .navigationBarTitleDisplayMode(.inline)
         .toolbar {
             ToolbarItem(placement: .navigationBarLeading) {
                 Button("取消") { dismiss() } // 直接关闭
             }
             ToolbarItem(placement: .navigationBarTrailing) {
                 Button {
                     viewModel.post()
                 } label: {
                     if viewModel.isPosting { ProgressView() } else { Text("发布") }
                 }
                 .disabled(
                     viewModel.isPosting ||
                     (viewModel.content.isEmpty && viewModel.attachments.isEmpty) ||
                     viewModel.selectedResort == nil
                 )
             }
         }
         .onAppear { viewModel.fetchResorts() }
     }
 }
 */

