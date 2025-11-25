//
//  Favorites.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/8.
//

import SwiftUI

struct Favorites: View {
    var body: some View {
        HStack{
            Text("编辑资料")
                .padding(.horizontal) // 增加内边距，使边框更明显
                .padding(.vertical, 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.black, lineWidth: 1)
                )
                
        }
    }
}

#Preview {
    Favorites()
}
