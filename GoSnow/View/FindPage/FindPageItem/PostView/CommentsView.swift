//
//  CommentsView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/10/4.
//

import SwiftUI

struct CommentsView: View {
    let postId: Int

    var body: some View {
        VStack {
            Text("评论列表")
                .font(.largeTitle)
            // 这里可以实现加载与 postId 相关的评论
        }
        .navigationTitle("评论")
    }
}



#Preview {
    CommentsView(postId: 1)
}
