//
//  AuthenticationView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/7/8.
//

import SwiftUI

struct AuthenticationView: View {
    @State private var PhoneNumber = ""
    @State private var Verification = ""
    var body: some View {
        NavigationStack{
            VStack{
                Spacer()
                Image(systemName: "mountain.2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding()
                
                VStack{
                    TextField("输入你的手机号", text: $PhoneNumber)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal, 24)
                    TextField("输入验证码", text: $Verification)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal, 24)
                }
                Button {
                    
                } label: {
                    Text("重新发送")
                        .padding(.top,1)
                        .padding(.leading, 280)
                        .padding(.bottom)
                        .foregroundColor(.black)
                        .frame(width: .infinity, alignment: .trailing)
                        
                }

                
                Button {
                    
                } label: {
                    Text("登陆")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 352, height: 44)
                        .background(Color.black)
                        .cornerRadius(10)
                }
                Spacer()
                
                Divider()
                
                NavigationLink{
                    Text("还没有账户？")
                }label: {
                    HStack (spacing: 3){
                        Text("还没有账户？")
                        Text("注册")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.black)
                }
                .padding(.vertical, 20)
            }
        }
    }
}

#Preview {
    AuthenticationView()
}
