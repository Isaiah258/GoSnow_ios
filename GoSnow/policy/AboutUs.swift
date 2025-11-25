//
//  AboutUs.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/27.
//

import SwiftUI

struct AboutUs: View {
    @State private var isCopied = false
    let emailAddress = "gosnow.serviceteam@gmail.com"
    
    var body: some View {
        List{
            Section{
                NavigationLink(destination: TermsView()){
                    Text("隐私政策")
                }
                NavigationLink(destination: CommunityGuidelinesView()){
                    Text("社区准则")
                }
                
                Link("WeatherKit法律声明", destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!)
                    .foregroundColor(.black)
                
            }
            Section{
                VStack(spacing: 20) {
                    Text("商务合作等任何问题请联系：\(emailAddress) 或前往微信服务号：雪兔滑行")
                    
                    
                    Button(action: {
                        UIPasteboard.general.string = emailAddress
                        isCopied = true
                        // 自动隐藏消息
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isCopied = false
                        }
                    }) {
                        Text("复制邮箱")
                            .padding(.vertical, 10)
                            .padding(.horizontal)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                    
                    if isCopied {
                        HStack {
                            Text("已复制")
                                .foregroundColor(.green)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: isCopied)
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .padding(.leading, 20)
            }
        }
    }
}




#Preview {
    AboutUs()
}
