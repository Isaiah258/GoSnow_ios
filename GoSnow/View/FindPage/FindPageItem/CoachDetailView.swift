//
//  CoachDetailView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/10/15.
//

import SwiftUI

struct CoachDetailView: View {
    var body: some View {
        HStack {
            HStack{
                
            }
            .frame(width: 150, height: 150)
            .background(Color.gray)
            VStack(alignment: .leading){
                Text("教练名称")
                Text("简介：")
                Spacer()
                Text("价格：100/h")
            }
            .frame(height: 150)
            .padding()
        }
        .padding(.vertical)
        .padding(.horizontal, 20)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}

#Preview {
    CoachDetailView()
}
