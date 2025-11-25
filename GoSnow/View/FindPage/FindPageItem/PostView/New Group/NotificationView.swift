//
//  NotificationView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/6.
//

import SwiftUI
import Kingfisher

struct NotificationView: View {
    @ObservedObject var viewModel: NotificationViewModel
    @State private var prefetcher: ImagePrefetcher?

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.notifications) { n in
                    NotificationRowView(notification: n)
                }
            }
            .navigationTitle("通知")
            .refreshable { await viewModel.loadNotifications() }
            .task {
                await viewModel.loadNotifications()
                await viewModel.markAllNotificationsAsRead()
            }
            .onChange(of: viewModel.notifications.map(\.id)) { _, _ in
                // 用最新的 notifications 重算 URL
                let urls = viewModel.notifications
                    .compactMap { $0.actor_avatar_url }
                    .filter { $0.hasPrefix("http") }
                    .compactMap(URL.init(string:))
                prefetcher?.stop()
                prefetcher = ImagePrefetcher(urls: urls)
                prefetcher?.start()
            }

            .onDisappear { prefetcher?.stop() }
        }
    }
}





