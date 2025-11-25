//
//  Welcome1View.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/23.
//

import SwiftUI

struct Welcome1View: View {
    var body: some View {
        VStack{
            
            Text("欢迎使用雪兔滑行")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("雪兔滑行拥有众多实用功能")
                .fontWeight(.medium)
                .padding()
                .padding(.bottom, 50)
            
            VStack (spacing: 30){
                
                HStack(spacing: 30){
                    Image(systemName: "bolt.fill")
                        .foregroundColor(Color.orange)
                        .fontWeight(.bold)
                    Text("轻量：即开即用，回归工具本质拒绝臃肿")
                        .fontWeight(.medium)
                }
                .frame(width: 300)
                
                
                
                HStack(spacing: 30){
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.green)
                        .fontWeight(.bold)
                    Text("失物招领：不再担心发现或丢失物品时无从下手")
                        .fontWeight(.medium)
                }
                .frame(width: 300)
                
                HStack(spacing: 30){
                    Image(systemName: "map")
                        .foregroundColor(Color.indigo)
                        .fontWeight(.bold)
                    Text("雪场雪况：来自雪友分享的真实雪况与全面的雪场信息")
                        .fontWeight(.medium)
                }
                .frame(width: 300)
                
                HStack(spacing: 30){
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(Color.blue)
                        .fontWeight(.bold)
                    Text("好友定位：无需对讲机了解好友位置")
                        .fontWeight(.medium)
                }
                .frame(width: 300)
                
                
                /*HStack(spacing: 30){
                    Image(systemName: "map")
                        .foregroundColor(Color.orange)
                        .fontWeight(.bold)
                    Text("更多功能：运动记录、滑雪学习书、紧急救援、可靠教练...")
                        .fontWeight(.medium)
                }
                .frame(width: 300)*/
            }
            .padding()
        }
    }
}

#Preview {
    Welcome1View()
}
