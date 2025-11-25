import SwiftUI
import Supabase

struct Sheet3View: View {
    // MARK: - State
    @State private var feedbackText = ""
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    // 上限：与当前产品风格保持一致（500 字）
    private let maxChars = 500

    // 键盘焦点
    @FocusState private var inputFocused: Bool

    // 依赖
    let manager = DatabaseManager.shared
    let resortId: Int

    init(resortId: Int) {
        self.resortId = resortId
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 顶部标题
                    Text("提交反馈")
                        .font(.title2.weight(.bold))
                        .padding(.top, 6)

                    // 说明
                    Text("帮助我们完善雪场信息（如缆车/雪道信息等）。如可，请附上联系方式以便我们核实与跟进。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // 输入区（无边框、多行）
                    ZStack(alignment: .topLeading) {
                        if feedbackText.isEmpty {
                            Text("请输入你想补充修正的信息，有联系方式更好:)")
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                        }

                        TextEditor(text: $feedbackText)
                            .font(.body)
                            .scrollContentBackground(.hidden) // 去系统背景
                            .background(Color.clear)          // 无背景
                            .frame(minHeight: 160)            // 多行高度
                            .focused($inputFocused)           // 焦点绑定
                            .padding(.horizontal, -4)         // 微调排版
                    }

                    // 计数 & 细分隔线
                    HStack {
                        Spacer()
                        let count = feedbackText.count
                        Text("\(count)/\(maxChars)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(count > maxChars - 40 ? .orange : .secondary)
                    }

                    Divider()

                    // 错误提示区块（一致风格）
                    if let errorMessage {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.callout.weight(.bold))
                                .foregroundStyle(.orange)
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.orange.opacity(0.08))
                        )
                    }

                    // 主按钮
                    Button(action: submitFeedback) {
                        HStack {
                            if isSubmitting { ProgressView().scaleEffect(0.8) }
                            Text("提交反馈")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(isSubmitDisabled ? Color.gray.opacity(0.5) : Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(isSubmitDisabled)
                    .animation(.easeInOut(duration: 0.18), value: isSubmitting)
                    .animation(.easeInOut(duration: 0.18), value: feedbackText)

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                // 点击空白处收起键盘
                .contentShape(Rectangle())
                .onTapGesture { inputFocused = false }
            }
            .background(Color(.systemGroupedBackground))
            // 下拉/拖动时交互式收起键盘
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(DragGesture().onChanged { _ in inputFocused = false })

            // 大标题样式保持 inline，符合你当前导航风格
            .navigationBarTitleDisplayMode(.inline)

            // 键盘工具条：收起
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { inputFocused = false }
                }
            }

            // 成功提示
            .alert("提交成功", isPresented: $showSuccessAlert) {
                Button("好的") {}
            } message: {
                Text("您的反馈已成功提交。感谢参与共建！")
            }
        }
        // 输入限制（硬性截断，避免超出）
        .onChange(of: feedbackText) { _, newValue in
            if newValue.count > maxChars {
                feedbackText = String(newValue.prefix(maxChars))
            }
        }
    }

    // 是否允许提交
    private var isSubmitDisabled: Bool {
        let trimmed = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        return isSubmitting || trimmed.isEmpty
    }

    // MARK: - Action
    private func submitFeedback() {
        guard !isSubmitDisabled else { return }
        inputFocused = false
        errorMessage = nil
        isSubmitting = true

        Task {
            do {
                let payload = ResortFeedback(
                    id: 0, // 由后端自增
                    resort_id: resortId,
                    resortfeedback: feedbackText.trimmingCharacters(in: .whitespacesAndNewlines),
                    created_at: Date()
                )

                try await manager.client
                    .from("ResortFeedback")
                    .insert(payload)
                    .execute()

                // 成功重置
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    showSuccessAlert = true
                    feedbackText = ""
                }
            } catch {
                // 友好错误
                errorMessage = "上传失败：\(error.localizedDescription)"
            }
            isSubmitting = false
        }
    }
}

#Preview {
    Sheet3View(resortId: 2)
}
