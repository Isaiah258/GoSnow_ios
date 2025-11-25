//
//  Welcome2View.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/23.
//

import SwiftUI

struct Welcome2View: View {
    var body: some View {
        VStack{
            
            Text("社区因你而丰富")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("向同好分享感受")
                .fontWeight(.medium)
                .padding()
                .padding(.bottom, 50)
            
            VStack (spacing: 30){
                HStack(spacing: 20){
                    Image(systemName: "megaphone")
                        .foregroundColor(Color.blue)
                        .fontWeight(.bold)
                    Text("雪况分享：了解每日雪况（详情见雪场页）")
                        .fontWeight(.medium)
                }
                .frame(width: 300)
                
                HStack(spacing: 20){
                    Image(systemName: "pencil.and.scribble")
                        .foregroundColor(Color.indigo)
                        .fontWeight(.bold)
                    Text("雪圈时刻：发现雪季生活的实用信息")
                        .fontWeight(.medium)
                }
                .frame(width: 300)
                
                HStack(spacing: 20){
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(Color.indigo)
                        .fontWeight(.bold)
                    Text("滑雪指南：帮助更多的人顺利走上冰雪")
                        .fontWeight(.medium)
                }
                .frame(width: 300)
                
                
            }
            .padding()
        }

    }
}

#Preview {
    Welcome2View()
}
