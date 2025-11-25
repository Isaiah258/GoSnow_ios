//
//  QuestionDetailView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/1/22.
//
import SwiftUI


struct QuestionDetailView: View {
    let question: String
    let answer: String
    let image: String

    var body: some View {
        ScrollView {
            VStack {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                
                Text(question)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                
                
                Spacer()
            }
            .navigationTitle("问题详情")
        }
    }
}

struct QuestionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionDetailView(question: "滑雪贵吗？", answer: "**滑雪**的费用主要由很多因素决定，包括雪场、设备租赁、住宿等。下个版本将会详细解释。", image: "question_money")
    }
}

