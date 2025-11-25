//
//  ResortGuideView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/10/12.
//

import SwiftUI

struct ResortGuideView: View {
    // 获取 dismiss 环境变量，用于关闭 sheet
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            Spacer()
            Text("当前没有收藏雪场，请去雪场页收藏常用雪场: )")
                .padding()
            Text("收藏后在此便可以随时看到常用雪场的信息了")
                .padding()
            Spacer()
            // "知道了"按钮
            Button(action: {
                dismiss() // 点击按钮后关闭当前 sheet
            }) {
                Text("知道了")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 350, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}


#Preview {
    ResortGuideView()
}
