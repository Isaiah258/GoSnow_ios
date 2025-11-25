//
//  GoSnowApp.swift
//  GoSnow
//
//  Created by federico Liu on 2024/6/18.
//

import SwiftUI
import Kingfisher
import Combine

@main
struct GoSnowApp: App {
    @StateObject private var sessionsStore: SessionsStore
    @StateObject private var statsStore: StatsStore
    @StateObject private var tabBarState = FloatingTabBarState()

    init() {
        // Kingfisher 缓存配置
        ImageCache.default.memoryStorage.config.expiration = .seconds(6 * 3600)
        ImageCache.default.diskStorage.config.expiration   = .days(14)
        ImageCache.default.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
        ImageCache.default.diskStorage.config.sizeLimit        = 500 * 1024 * 1024

        // 复用同一个本地存储
        let localStore = JSONLocalStore()

        // 会话仓库
        let sess = SessionsStore(store: localStore)
        _sessionsStore = StateObject(wrappedValue: sess)

        // 统计仓库（新版本只需传 localStore，内部自行扫描聚合）
        _statsStore = StateObject(wrappedValue: StatsStore(localStore: localStore))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(statsStore: statsStore)
                .environmentObject(sessionsStore)
                .environmentObject(tabBarState)

                // 会话变化 -> 触发统计刷新（轻量，内部异步从 JSON 扫描）
                .onReceive(sessionsStore.$sessions) { _ in
                    statsStore.refresh()
                }

                .task {
                    // 启动先加载历史会话，再刷新统计
                    await sessionsStore.reload()
                    statsStore.refresh()
                    await AuthManager.shared.bootstrap()   // 你原有的登录恢复
                }
        }
    }
}





    

