//
//  Welcome3View.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/23.
//

import SwiftUI

struct Welcome3View: View {
    var body: some View {
        VStack{
            Text("目前雪兔滑行正处于早期阶段")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("诸多功能将逐步上线请及时更新，欢迎你的反馈建议:)")
                .padding()
                .fontWeight(.medium)
            
        }
    }
}

#Preview {
    Welcome3View()
}
