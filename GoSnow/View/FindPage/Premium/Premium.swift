//
//  Premium.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/27.
//
/*
import SwiftUI

struct Premium: View {
    var body: some View {
        NavigationStack{
            VStack{
                VStack{
                    VStack(alignment: .leading){
                        VStack {
                            Image("diamond")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                            
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.gray.opacity(0.5), radius: 10, x: 0, y: 10)
                        
                        
                        Text("欢迎订阅黑钻会员")
                            .font(.title)
                            .padding(.top, 20)
                        Text("您的订阅将是我做好GoSnow的最大动力！")
                            .fontWeight(.thin)
                    }
                    
                    Spacer()
                    VStack(alignment: .leading){
                        HStack{
                            Image(systemName: "square.stack.3d.up")
                                .foregroundStyle(Color.indigo)
                            Text("永久运动记录存储(标准版3条)")
                        }
                        .padding()
                        HStack{
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(Color.indigo)
                            Text("精美专业的个人滑雪报告")
                        }
                        .padding()
                        HStack(spacing: 5){
                            Image(systemName: "dumbbell.fill")
                                .foregroundStyle(Color.indigo)
                            
                            Text("预备雪季，体能训练计划")
                                
                        }
                        .padding()
                        HStack(spacing: 10){
                            Image(systemName: "person.badge.shield.checkmark.fill")
                                .foregroundStyle(Color.indigo)
                            Text("多样化的App图标与专属头像")
                        }
                        .padding()
                        
                        HStack(spacing: 10){
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(Color.indigo)
                            Text("畅快使用3D地图，浏览雪道难度")
                        }
                        .padding()
                    }
                    
                    .frame(width: 310)
                    .background(Color.white)
                    
                    
                    
                    ScrollView(.horizontal){
                        HStack {
                            PremiumCard1()
                            PremiumCard2()
                            PremiumCard3()
                        }
                    }
                    .padding()
                    
                }
            }
        }
    }
}

#Preview {
    Premium()
}
*/
