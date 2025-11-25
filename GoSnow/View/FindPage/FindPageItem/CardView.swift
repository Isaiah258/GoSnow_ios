//
//  CardView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/1/22.
//
/*
import SwiftUI

struct QuestionCardView: View {
    let question: String
    let answer: String
    let image: String  // 新增图片参数

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(image)  // 动态使用传入的图片
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 180, height: 180)
            
            CardText
                .padding(.horizontal)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 8)
    }
    
    var CardText: some View {
        VStack {
            Text(question)
                .font(.headline)
                .foregroundStyle(Color.black)
        }
        .foregroundStyle(Color.gray)
        .padding(.bottom, 16)
    }
}

#Preview {
    QuestionCardView(question: "滑雪一定贵吗？", answer: "详细内容将在下个版本更新。", image: "question_money")
}


*/
