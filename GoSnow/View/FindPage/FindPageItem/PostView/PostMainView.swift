//
//  PostMainView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/8.
//

import SwiftUI

struct PostMainView: View {
    @StateObject private var notificationVM = NotificationViewModel()
    @StateObject private var timelineVM = PostTimelineViewModel()
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            PostView(
                viewModel: timelineVM,
                notificationVM: notificationVM,
                navPath: $navPath
            )
            .navigationDestination(for: PostNavigation.self) { route in
                switch route {
                case .notification:
                    NotificationView(viewModel: notificationVM)
                case .compose(let uid):
                    AddPostScreen(userId: uid) {
                        navPath.removeLast()           // 返回到 PostView
                        Task { await timelineVM.refresh() }  // 刷新列表
                    }

                }
            }
        }
        .onAppear {
            Task { await notificationVM.checkUnreadNotifications() }
        }
    }
}


#Preview {
    PostMainView()
}

