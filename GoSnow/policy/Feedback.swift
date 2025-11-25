//
//  Feedback.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/27.
//

import SwiftUI

struct Feedback: View {
    @State private var feedbackContent = ""
    @State private var contactInfo = ""
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("反馈内容（必填）")) {
                        TextEditor(text: $feedbackContent)
                            .frame(height: 150)
                            
                    }

                    Section(header: Text("联系方式（选填）")) {
                        TextField("请输入你的联系方式", text: $contactInfo)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                    }
                }
                
                Button(action: submitFeedback) {
                    Text(isSubmitting ? "提交中..." : "提交反馈")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                .disabled(feedbackContent.isEmpty || isSubmitting) // 必填项为空时禁用按钮
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
                }
                
                Spacer()
            }
            .navigationTitle("用户反馈")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // 提交反馈
    func submitFeedback() {
        guard !feedbackContent.isEmpty else { return }
        
        isSubmitting = true
        
        Task {
            do {
                let manager = DatabaseManager.shared
                let feedback = FeedBackForUs(id: 0, content: feedbackContent, contact: contactInfo)
                
                // 插入到 Supabase 数据库
                try await manager.client.from("FeedBackForUs")
                    .insert([
                        "content": feedback.content,
                        "contact": feedback.contact.isEmpty ? nil : feedback.contact
                    ])
                    .execute()
                
                alertMessage = "反馈提交成功，谢谢您的支持！"
                resetForm()
            } catch {
                alertMessage = "提交反馈时出错，请稍后再试。"
            }
            
            isSubmitting = false
            showAlert = true
        }
    }
    
    // 重置表单
    func resetForm() {
        feedbackContent = ""
        contactInfo = ""
    }
}


#Preview {
    Feedback()
}

