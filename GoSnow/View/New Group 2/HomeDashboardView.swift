//
//  HomeDashboardView.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/9/16.
//

import SwiftUI
import CoreLocation

import Foundation

@MainActor
final class StatsStore: ObservableObject {
    // 今日
    @Published var todayDistanceKm: Double = 0
    @Published var todayDeltaPct: Double? = nil

    // 累计
    @Published var totalDistanceKm: Double = 0
    @Published var totalDurationSec: Int = 0
    @Published var daysOnSnow: Int = 0

    private let store: LocalStore

    init(localStore: LocalStore = JSONLocalStore()) {
        self.store = localStore
    }

    /// 与旧 API 兼容：同名 `refresh()`，内部走异步加载并回填
    func refresh() {
        Task { await refreshAsync() }
    }

    /// 实际刷新逻辑
    func refreshAsync() async {
        let list: [SkiSession]
        do {
            if let json = store as? JSONLocalStore {
                list = try await json.loadSessionsAsync()
            } else {
                let s = self.store
                list = try await Task.detached(priority: .utility) { try s.loadSessions() }.value
            }
        } catch {
            print("❌ Stats refresh failed:", error)
            return
        }

        // 累计
        totalDistanceKm  = list.reduce(0) { $0 + $1.distanceKm }
        totalDurationSec = list.reduce(0) { $0 + $1.durationSec }

        // 今日
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let todayDist = list
            .filter { cal.isDate($0.startAt, inSameDayAs: today) }
            .reduce(0) { $0 + $1.distanceKm }
        todayDistanceKm = todayDist

        // 昨日对比
        if let yest = cal.date(byAdding: .day, value: -1, to: today) {
            let yDist = list
                .filter { cal.isDate($0.startAt, inSameDayAs: yest) }
                .reduce(0) { $0 + $1.distanceKm }
            todayDeltaPct = (yDist > 0) ? (todayDist - yDist) / yDist : nil
        } else {
            todayDeltaPct = nil
        }

        // 在雪天数：有时长的自然日计数
        var daySet = Set<Date>()
        for s in list where s.durationSec > 0 {
            daySet.insert(cal.startOfDay(for: s.startAt))
        }
        daysOnSnow = daySet.count
    }

    // 预览用
    static func demo() -> StatsStore {
        let ss = StatsStore()
        ss.totalDistanceKm = 235.4
        ss.totalDurationSec = 72*3600 + 35*60
        ss.daysOnSnow = 21
        ss.todayDistanceKm = 7.8
        ss.todayDeltaPct = 0.061
        return ss
    }
}


// MARK: - 首页
struct HomeDashboardView: View {
    @ObservedObject var store: StatsStore
    @State private var didAppear = false
    @ObservedObject private var auth = AuthManager.shared
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        HomeTopBar(seasonText: seasonLabel, avatarURL: auth.userProfile?.avatar_url)
                                                    .padding(.horizontal, 20)
                                                    .padding(.top, 8)

                        // 今日滑行
                        TodayDistanceCard(
                            km: store.todayDistanceKm,
                            deltaPct: store.todayDeltaPct
                        )
                        .padding(.horizontal, 20)

                        // 生涯统计
                        Text("生涯")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        HStack(alignment: .top, spacing: 12) {
                            // 左：总里程（动画）
                            LargeDistanceCardCenteredAnimated(
                                title: "总里程",
                                icon: "map.fill",
                                distanceKm: store.totalDistanceKm
                            )
                            .frame(minHeight: 150)

                            // 右：总时长 + 在雪天数（动画）
                            VStack(spacing: 12) {
                                SmallStatCardHoursAnimated(
                                    title: "总时长",
                                    icon: "stopwatch.fill",
                                    seconds: store.totalDurationSec,
                                    accent: .purple
                                )
                                SmallStatCardDaysAnimated(
                                    title: "在雪天数",
                                    icon: "snowflake",
                                    days: store.daysOnSnow,
                                    accent: .blue
                                )
                            }
                        }

                        .padding(.horizontal, 20)

                        // 精选
                        Text("精选")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        FeaturedRow()
                            .padding(.leading, 20)
                            .padding(.vertical, 6)

                        // 开始记录 CTA
                        NavigationLink {
                            RecordingView()            // ← 你的记录页面
                        } label: {
                            StartRecordingCTA()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        Spacer(minLength: 120)
                    }
                    .opacity(didAppear ? 1 : 0)
                    .offset(y: didAppear ? 0 : 8)
                    .animation(.easeOut(duration: 0.28), value: didAppear)
                }
                
            }
            .onAppear {
                didAppear = true
                store.refresh()
            }
            .navigationTitle("") // 顶栏已包含标题/头像
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // 季节标签：“25–26 雪季”
    private var seasonLabel: String {
        let c = Calendar(identifier: .gregorian)
        let comp = c.dateComponents([.year, .month], from: Date())
        guard let y = comp.year, let m = comp.month else { return "雪季" }
        let s = (m >= 10) ? y % 100 : (y - 1) % 100
        let e = (m >= 10) ? (y + 1) % 100 : y % 100
        return String(format: "%02d–%02d 雪季", s, e)
    }
}

// MARK: 顶栏（点击头像 -> ProfileSettingsView）
private struct TopBar: View {
    let seasonText: String
    var body: some View {
        HStack {
            Text(seasonText)
                .font(.title3.weight(.semibold))
            Spacer()
            NavigationLink {
                ProfileSettingsView()       // 进入账户资料与设置
            } label: {
                ZStack {
                    Circle().fill(Color(.tertiarySystemFill))
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                }
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(.primary.opacity(0.12), lineWidth: 1))
            }
        }
    }
}

// MARK: 今日滑行卡
private struct TodayDistanceCard: View {
    let km: Double
    let deltaPct: Double?

    var body: some View {
        RoundedContainer {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("今日滑行")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let p = deltaPct { DeltaPill(delta: p) }
                }

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(String(format: "%.1f", km))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("km")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary.opacity(0.9))
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
}

private struct DeltaPill: View {
    let delta: Double
    var isUp: Bool { delta >= 0 }
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right").font(.footnote.weight(.bold))
            Text(String(format: "%g%%", abs(delta) * 100)).font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .foregroundStyle(isUp ? .green : .red)
        .background(Capsule().fill((isUp ? Color.green : Color.red).opacity(0.12)))
    }
}

// MARK: 总里程卡：标题左、数值居中、单位左对齐
// 替代原 LargeDistanceCardCentered
private struct LargeDistanceCardCenteredAnimated: View {
    let title: String
    let icon: String
    let distanceKm: Double

    var body: some View {
        RoundedContainer {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    IconBadge(system: icon, tint: .green)
                    Text(title).font(.headline)
                    Spacer()
                }
                .padding(.bottom, 8)

                // 动画数字（居中）
                AnimatedNumericText(
                    value: distanceKm,
                    format: "%.1f",
                    suffix: nil,                                  // 单位独立展示在下方
                    font: .system(size: 46, weight: .bold, design: .rounded),
                    foreground: .primary
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .monospacedDigit()

                Text("km")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)

                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }
}
// 新增：把秒转为小时并做数值动画
private struct SmallStatCardHoursAnimated: View {
    let title: String
    let icon: String
    let seconds: Int
    let accent: Color

    var hours: Double {
        Double(seconds) / 3600.0
    }

    var body: some View {
        RoundedContainer {
            HStack(spacing: 12) {
                IconBadge(system: icon, tint: accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    AnimatedNumericText(
                        value: hours,
                        format: "%.1f",
                        suffix: " 小时",
                        font: .title3.weight(.bold),
                        foreground: .primary
                    )
                    .monospacedDigit()
                }
                Spacer()
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
    }
}
// 新增：天数动画（整数）
private struct SmallStatCardDaysAnimated: View {
    let title: String
    let icon: String
    let days: Int
    let accent: Color

    var body: some View {
        RoundedContainer {
            HStack(spacing: 12) {
                IconBadge(system: icon, tint: accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    AnimatedNumericText(
                        value: Double(days),
                        format: "%.0f",
                        suffix: " 天",
                        font: .title3.weight(.bold),
                        foreground: .primary
                    )
                    .monospacedDigit()
                }
                Spacer()
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
    }
}


// MARK: 右侧小卡
private struct SmallStatCard: View {
    let title: String
    let icon: String
    let value: String
    let accent: Color

    var body: some View {
        RoundedContainer {
            HStack(spacing: 12) {
                IconBadge(system: icon, tint: accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer()
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
    }
}

// MARK: - 精选：横向小卡片行
private struct FeaturedRow: View {
    private let spacing: CGFloat = 12
    private let width: CGFloat = 160
    private let height: CGFloat = 92

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                
                
                NavigationLink {
                    StatsView()
                        
                } label: {
                    FeaturedCard(
                        icon: "chart.line.uptrend.xyaxis",
                        tint: .orange,
                        title: "滑行数据",
                        subtitle: "周/月/雪季 趋势图表",
                        width: width, height: height
                    )
                }
                .buttonStyle(.plain)
                
                
                // 1) 雪况投票
                NavigationLink {
                    ResortsView()
                } label: {
                    FeaturedCard(
                        icon: "snowflake",
                        tint: .cyan,
                        title: "雪况投票",
                        subtitle: "一起评估今日雪况",
                        width: width, height: height
                    )
                }
                .buttonStyle(.plain)

                // 2) 数据补充
                NavigationLink {
                    DataContributionView()
                } label: {
                    FeaturedCard(
                        icon: "square.and.pencil",
                        tint: .indigo,
                        title: "数据补充",
                        subtitle: "与你一起完善",
                        width: width, height: height
                    )
                }
                .buttonStyle(.plain)

                
                // 3) 失物招领
                NavigationLink {
                    LostAndFoundView()
                        .navigationTitle("失物招领")
                } label: {
                    FeaturedCard(
                        icon: "magnifyingglass",
                        tint: .orange,
                        title: "失物招领",
                        subtitle: "发布与寻找，一键搞定",
                        width: width, height: height
                    )
                }
                .buttonStyle(.plain)
                
                



                
            }
            .padding(.trailing, 20)
        }
        .scrollClipDisabled()

    }
}


private struct FeaturedCard: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        RoundedContainer {
            VStack(alignment: .leading, spacing: 8) {
                // 图标与标题布局，沿用 SmallStatCard / 大卡风格
                HStack(spacing: 12) {
                    IconBadge(system: icon, tint: tint)
                        .frame(width: 32, height: 32)
                    Text(title)
                        .font(.headline)          // 与“生涯”行标题一致
                        .foregroundStyle(.primary)
                    Spacer()
                }

                Text(subtitle)
                    .font(.footnote)              // 与说明文字一致
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(12)                           // 和其它卡片保持同级 padding
        }
        .frame(width: width, height: height)       // 与精选区统一尺寸
    }
}



// MARK: - CTA
private struct StartRecordingCTA: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Text("开始记录")
            .font(.title3.weight(.bold))
            .foregroundStyle(scheme == .dark ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule().fill(scheme == .dark ? .white : .black)
            )
            .overlay(
                Capsule().stroke(.primary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: scheme == .dark ? .clear : .black.opacity(0.15),
                    radius: 12, x: 0, y: 8)
    }
}

private func formatHours1dp(_ seconds: Int) -> String {
    let h = Double(seconds) / 3600.0
    return String(format: "%.1f 小时", h)
}

// MARK: - 占位页面（空白，后续再完善）

struct SnowConditionVoteView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("雪况投票").font(.title2.bold())
            Text("这里将展示投票入口与结果可视化。").foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("雪况投票")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataContributionView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("上雪，和你一起完善:)").font(.title2.bold())
            Text("请前往对应雪场的详情页提交信息，或直接发送信息至gosnow.serviceteam@gmail.com").foregroundStyle(.secondary).textSelection(.enabled)
        }
        .padding()
        .navigationTitle("数据补充")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeaturePlaceholderView: View {
    let title: String
    var body: some View {
        VStack(spacing: 12) {
            Text(title).font(.title2.bold())
            Text("占位页面 · 后续扩展").foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}



/// 数值文本：支持小数/整数格式化与后缀；当 `value` 变化时触发 .numericText 动画
struct AnimatedNumericText: View {
    let value: Double
    let format: String          // 例如 "%.1f" / "%.0f"
    let suffix: String?         // 例如 "km" / " 小时" / " 天"
    let font: Font
    let foreground: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(String(format: format, value))
                .contentTransition(.numericText())                  // 关键
                .font(font)
                .foregroundStyle(foreground)
                .animation(.easeOut(duration: 0.25), value: value)  // 过渡节奏

            if let s = suffix, !s.isEmpty {
                Text(s)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
// MARK: 顶栏（点击头像 -> ProfileSettingsView）
private struct HomeTopBar: View {
    let seasonText: String
    let avatarURL: String?   // ✅ 新增：传入头像 URL

    var body: some View {
        HStack {
            Text(seasonText)
                .font(.title3.weight(.semibold))
            Spacer()
            NavigationLink {
                ProfileSettingsView()  // 进入账户资料与设置
            } label: {
                // ✅ 使用你已有的 AvatarBubble（支持远程 URL/占位）
                AvatarBubble(urlString: avatarURL)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(.primary.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}


// MARK: - 预览
#Preview("首页（精选）") {
    HomeDashboardView(store: .demo())
        .preferredColorScheme(.light)
}




/*
 
 import SwiftUI
 import CoreLocation

 // MARK: - 可插拔数据源的 Store（接入 DataStorageManager）
 final class StatsStore: ObservableObject {
     // 今日
     @Published var todayDistanceKm: Double = 0
     @Published var todayDeltaPct: Double? = nil  // 相比昨日（可为 nil）

     // 累计
     @Published var totalDistanceKm: Double = 0
     @Published var totalDurationSec: Int = 0
     @Published var daysOnSnow: Int = 0

     typealias TotalsFetcher = () -> (distanceKm: Double, durationSec: Int, daysOnSnow: Int)
     typealias DailyFetcher  = (_ date: Date) -> (distanceKm: Double, durationSec: Int)?

     private let fetchTotals: TotalsFetcher
     private let fetchDaily: DailyFetcher

     init(fetchTotals: @escaping TotalsFetcher,
          fetchDaily:  @escaping DailyFetcher) {
         self.fetchTotals = fetchTotals
         self.fetchDaily  = fetchDaily
         refresh()
     }

     /// 从本地存储刷新所有字段（总数据 + 今日 + 昨日对比）
     func refresh() {
         // 累计
         let t = fetchTotals()
         totalDistanceKm = t.distanceKm
         totalDurationSec = t.durationSec
         daysOnSnow = t.daysOnSnow

         // 今日
         let today = Calendar.current.startOfDay(for: Date())
         if let d = fetchDaily(today) {
             todayDistanceKm = d.distanceKm
         } else {
             todayDistanceKm = 0
         }

         // 昨日对比（若昨日为 0 则不显示百分比）
         if let y = fetchDaily(Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today) {
             if y.distanceKm > 0 {
                 todayDeltaPct = (todayDistanceKm - y.distanceKm) / y.distanceKm
             } else {
                 todayDeltaPct = nil
             }
         } else {
             todayDeltaPct = nil
         }
     }

     // Demo 构造（不接 DataStorageManager 时使用）
     static func demo() -> StatsStore {
         StatsStore(
             fetchTotals: { (235.4, 72*3600 + 35*60, 21) },
             fetchDaily: { date in
                 let isToday = Calendar.current.isDateInToday(date)
                 let isYesterday = Calendar.current.isDateInYesterday(date)
                 if isToday { return (7.8, 2*3600 + 20*60) }
                 if isYesterday { return (7.35, 2*3600) }
                 return nil
             }
         )
     }
 }

 // MARK: - 首页
 struct HomeDashboardView: View {
     @ObservedObject var store: StatsStore
     @AppStorage("favoriteResortId") private var favoriteResortId: Int?
     @State private var didAppear = false
     @State private var showBindSheet = false



     var body: some View {
         NavigationStack {
             ZStack {
                 LinearGradient(
                     colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                     startPoint: .top, endPoint: .bottom
                 )
                 .ignoresSafeArea()

                 ScrollView(.vertical, showsIndicators: false) {
                     VStack(alignment: .leading, spacing: 16) {
                         TopBar(seasonText: seasonLabel)
                             .padding(.horizontal, 20)
                             .padding(.top, 8)

                         // 今日滑行
                         TodayDistanceCard(
                             km: store.todayDistanceKm,
                             deltaPct: store.todayDeltaPct
                         )
                         .padding(.horizontal, 20)

                         Text("生涯")
                             .font(.title3.weight(.semibold))
                             .foregroundStyle(.primary)
                             .padding(.horizontal, 20)
                             .padding(.top, 8)

                         HStack(alignment: .top, spacing: 12) {
                             // 左：总里程
                             LargeDistanceCardCentered(
                                 title: "总里程",
                                 icon: "map.fill",
                                 distanceKm: store.totalDistanceKm
                             )
                             .frame(minHeight: 150)

                             // 右：总时长 + 在雪天数
                             VStack(spacing: 12) {
                                 SmallStatCard(
                                     title: "总时长",
                                     icon: "stopwatch.fill",
                                     value: formatHours1dp(store.totalDurationSec),
                                     accent: .purple
                                 )
                                 SmallStatCard(
                                     title: "在雪天数",
                                     icon: "snowflake",
                                     value: "\(store.daysOnSnow) 天",
                                     accent: .blue
                                 )
                             }
                         }
                         .padding(.horizontal, 20)

                         // 我的雪场（不含天气）
                         if let rid = favoriteResortId {
                             ResortSummaryCard(
                                 resort: ResortSummary.mock(id: rid),
                                 onDetail: { /* TODO: push ResortGuideView(resortId: rid) */ },
                                 onVote: { vote in
                                     // TODO: 调用你已实现的投票接口
                                     print("vote:", vote.rawValue)
                                 }
                             )
                             .padding(.horizontal, 20)
                         } else {
                             BindResortCard(onBind: {
                                 showBindSheet = true
                             })
                             .padding(.horizontal, 20)

                         }
                         
                         // 资讯
                         Text("资讯")
                             .font(.title3.weight(.semibold))
                             .foregroundStyle(.primary)
                             .padding(.horizontal, 20)

                         NewsCarousel(
                             items: NewsItem.mock(),                       // ← 用 mock 数据，后续可接接口
                             onTap: { item in
                                 // TODO: 在这里 push 到你的资讯详情页 / Safari
                                 // 例如：openURL(item.linkURL) 或 NavigationLink 到 NewsDetailView(item:)
                                 print("tap news:", item.title)
                             }
                         )
                         .padding(.leading, 20) // 左边与页面对齐
                         .padding(.vertical, 6)


                         
                         // ✅ 把 CTA 放进内容里（不算高度）
                         NavigationLink {
                             RecordingView()            // ← 你的记录页面
                         } label: {
                             StartRecordingCTA()        // ← 纯样式按钮
                         }
                         .padding(.horizontal, 20)      // 和首页卡片左右对齐
                         .padding(.top, 12)


                         // ✅ 给底部留白，避免被悬浮 TabBar 遮挡
                         Spacer(minLength: 120)
                     }
                     .opacity(didAppear ? 1 : 0)
                     .offset(y: didAppear ? 0 : 8)
                     .animation(.easeOut(duration: 0.28), value: didAppear)
                 }
             }
             .confirmationDialog("去“雪场”页绑定常用雪场", isPresented: $showBindSheet, titleVisibility: .visible) {
                 Button("知道了", role: .cancel) { }
             } message: {
                 Text("绑定后可在首页查看雪况与缆车等候，并进行投票。")
             }

             .onAppear {
                 didAppear = true
                 store.refresh() // 进入页面时刷新一次
             }
             // 录制结束后让首页自动刷新（RecordingView 结束时发这个通知即可）
             .onReceive(NotificationCenter.default.publisher(for: .runDidFinish)) { _ in
                 store.refresh()
             }
         }
     }

     // 季节标签：“25–26 雪季”
     private var seasonLabel: String {
         let c = Calendar(identifier: .gregorian)
         let comp = c.dateComponents([.year, .month], from: Date())
         guard let y = comp.year, let m = comp.month else { return "雪季" }
         let s = (m >= 10) ? y % 100 : (y - 1) % 100
         let e = (m >= 10) ? (y + 1) % 100 : y % 100
         return String(format: "%02d–%02d 雪季", s, e)
     }
 }

 // MARK: 顶栏
 // MARK: 顶栏（点击头像 -> ProfileSettingsView）
 private struct TopBar: View {
     let seasonText: String
     var body: some View {
         HStack {
             Text(seasonText)
                 .font(.title3.weight(.semibold))
             Spacer()
             NavigationLink {
                 ProfileSettingsView()       // ✅ 进入账户资料与设置
             } label: {
                 ZStack {
                     Circle().fill(Color(.tertiarySystemFill))
                     Image(systemName: "person.fill")
                         .font(.system(size: 16, weight: .bold))
                         .foregroundStyle(.primary)
                 }
                 .frame(width: 32, height: 32)
                 .overlay(Circle().stroke(.primary.opacity(0.12), lineWidth: 1))
             }
         }
     }
 }


 // MARK: 今日滑行卡
 private struct TodayDistanceCard: View {
     let km: Double
     let deltaPct: Double?

     var body: some View {
         RoundedContainer {
             VStack(alignment: .leading, spacing: 6) {
                 HStack {
                     Text("今日滑行")
                         .font(.subheadline.weight(.semibold))
                         .foregroundStyle(.secondary)
                     Spacer()
                     if let p = deltaPct { DeltaPill(delta: p) }
                 }

                 HStack(alignment: .firstTextBaseline, spacing: 10) {
                     Text(String(format: "%.1f", km))
                         .font(.system(size: 56, weight: .bold, design: .rounded))
                         .monospacedDigit()
                     Text("km")
                         .font(.title3.weight(.semibold))
                         .foregroundStyle(.primary.opacity(0.9))
                 }
             }
             .padding(18)
         }
         .frame(maxWidth: .infinity, minHeight: 120)
     }
 }

 private struct DeltaPill: View {
     let delta: Double
     var isUp: Bool { delta >= 0 }
     var body: some View {
         HStack(spacing: 6) {
             Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right").font(.footnote.weight(.bold))
             Text(String(format: "%g%%", abs(delta) * 100)).font(.footnote.weight(.semibold))
         }
         .padding(.horizontal, 10).padding(.vertical, 6)
         .foregroundStyle(isUp ? .green : .red)
         .background(Capsule().fill((isUp ? Color.green : Color.red).opacity(0.12)))
     }
 }

 // MARK: 总里程卡：标题左、数值居中、单位左对齐
 private struct LargeDistanceCardCentered: View {
     let title: String
     let icon: String
     let distanceKm: Double

     var body: some View {
         RoundedContainer {
             VStack(alignment: .leading, spacing: 0) {
                 HStack(spacing: 8) {
                     IconBadge(system: icon, tint: .green)
                     Text(title).font(.headline)
                     Spacer()
                 }
                 .padding(.bottom, 8)

                 Text(String(format: "%.1f", distanceKm))
                     .font(.system(size: 46, weight: .bold, design: .rounded))
                     .monospacedDigit()
                     .lineLimit(1)
                     .minimumScaleFactor(0.7)
                     .frame(maxWidth: .infinity, alignment: .center)

                 Text("km")
                     .font(.footnote.weight(.semibold))
                     .foregroundStyle(.secondary)
                     .padding(.top, 6)

                 Spacer(minLength: 0)
             }
             .padding(16)
         }
     }
 }

 // MARK: 右侧小卡
 private struct SmallStatCard: View {
     let title: String
     let icon: String
     let value: String
     let accent: Color

     var body: some View {
         RoundedContainer {
             HStack(spacing: 12) {
                 IconBadge(system: icon, tint: accent)
                 VStack(alignment: .leading, spacing: 4) {
                     Text(title)
                         .font(.subheadline.weight(.semibold))
                         .foregroundStyle(.secondary)
                     Text(value)
                         .font(.title3.weight(.bold))
                         .monospacedDigit()
                         .lineLimit(1)
                         .minimumScaleFactor(0.7)
                 }
                 Spacer()
             }
             .padding(16)
         }
         .frame(maxWidth: .infinity, minHeight: 80)
     }
 }

 // MARK: - 我的雪场（无天气）
 private struct ResortSummary: Identifiable {
     let id: Int
     let name: String
     let conditionText: String     // 例：粉雪 / 压雪 / 湿重
     let liftWaitText: String      // 例：10–15 分钟 / 短/中/长
     let updatedAt: Date

     static func mock(id: Int) -> ResortSummary {
         .init(id: id,
               name: "我的雪场",
               conditionText: "压雪 · 面干净",
               liftWaitText: "10–15 分钟",
               updatedAt: Date())
     }
 }

 private struct ResortSummaryCard: View {
     let resort: ResortSummary
     var onDetail: () -> Void
     var onVote: (_ value: LiftWaitVote) -> Void

     @State private var myVote: LiftWaitVote? = nil

     var body: some View {
         RoundedContainer {
             VStack(alignment: .leading, spacing: 12) {
                 HStack {
                     Text(resort.name).font(.headline)
                     Spacer()
                     Button {
                         onDetail()
                     } label: {
                         HStack(spacing: 4) {
                             Text("详情")
                             Image(systemName: "chevron.right")
                                 .font(.footnote.weight(.semibold))
                         }
                         .font(.subheadline.weight(.semibold))
                         .foregroundStyle(.primary)
                     }
                 }

                 HStack(spacing: 8) {
                     InfoChip(icon: "snowflake", text: resort.conditionText)
                     InfoChip(icon: "clock.badge", text: resort.liftWaitText)
                 }

                 HStack(spacing: 8) {
                     Text("缆车等候投票")
                         .font(.subheadline.weight(.semibold))
                         .foregroundStyle(.secondary)
                     Spacer()
                     VoteSegment(selected: $myVote) { vote in
                         myVote = vote
                         onVote(vote)
                     }
                 }
             }
             .padding(16)
         }
         .frame(maxWidth: .infinity)
     }
 }

 private enum LiftWaitVote: String, CaseIterable, Identifiable {
     case short, medium, long
     var id: String { rawValue }
     var title: String { switch self { case .short: "短"; case .medium: "中"; case .long: "长" } }
     var color: Color { switch self { case .short: .green; case .medium: .orange; case .long: .red } }
 }

 private struct VoteSegment: View {
     @Binding var selected: LiftWaitVote?
     var onSelect: (LiftWaitVote) -> Void

     var body: some View {
         HStack(spacing: 6) {
             ForEach(LiftWaitVote.allCases) { v in
                 Button {
                     onSelect(v)
                 } label: {
                     Text(v.title)
                         .font(.footnote.weight(.semibold))
                         .padding(.horizontal, 10)
                         .padding(.vertical, 6)
                         .background(
                             Capsule().fill((selected == v ? v.color : .primary.opacity(0.08)).opacity(selected == v ? 0.18 : 0.12))
                         )
                         .foregroundStyle(selected == v ? v.color : .primary)
                         .overlay(
                             Capsule().stroke(.primary.opacity(0.08), lineWidth: 1 / UIScreen.main.scale)
                         )
                 }
             }
         }
     }
 }


 // 未绑定引导
 private struct BindResortCard: View {
     var onBind: () -> Void
     var body: some View {
         RoundedContainer {
             HStack(spacing: 12) {
                 Image(systemName: "mappin.and.ellipse").font(.title3.weight(.bold))
                 VStack(alignment: .leading, spacing: 6) {
                     Text("绑定我的雪场").font(.headline)
                     Text("绑定后在首页查看雪况、缆车等候，并可投票。")
                         .font(.footnote)
                         .foregroundStyle(.secondary)
                 }
                 Spacer()
                 Button("去绑定", action: onBind)
                     .font(.subheadline.weight(.bold))
                     .padding(.horizontal, 12).padding(.vertical, 8)
                     .background(Capsule().fill(Color.black))
                     .foregroundStyle(.white)
             }
             .padding(16)
         }
         .frame(maxWidth: .infinity)
     }
 }
 private struct StartRecordingCTA: View {
     @Environment(\.colorScheme) private var scheme
     var body: some View {
         Text("开始记录")
             .font(.title3.weight(.bold))
             .foregroundStyle(scheme == .dark ? .black : .white)
             .frame(maxWidth: .infinity)
             .padding(.vertical, 16)
             .background(
                 Capsule().fill(scheme == .dark ? .white : .black)
             )
             .overlay(
                 Capsule().stroke(.primary.opacity(0.1), lineWidth: 1)
             )
             .shadow(color: scheme == .dark ? .clear : .black.opacity(0.15),
                     radius: 12, x: 0, y: 8)
     }
 }



 private func formatHours1dp(_ seconds: Int) -> String {
     let h = Double(seconds) / 3600.0
     return String(format: "%.1f 小时", h)
 }

 // 录制结束后可发这个通知来刷新首页
 extension Notification.Name {
     static let runDidFinish = Notification.Name("runDidFinish")
 }

 // MARK: - 预览
 #Preview("未绑定") {
     UserDefaults.standard.removeObject(forKey: "favoriteResortId")
     return HomeDashboardView(store: .demo())
         .preferredColorScheme(.light)
 }

 #Preview("已绑定") {
     UserDefaults.standard.set(1, forKey: "favoriteResortId")
     return HomeDashboardView(store: .demo())
         .preferredColorScheme(.light)
 }



 // MARK: - 模型
 struct NewsItem: Identifiable, Hashable {
     let id = UUID()
     let title: String
     let imageName: String?     // 本地占位图名（如无远程图）
     let imageURL: URL?         // 远程图（有则优先）
     let linkURL: URL?          // 点击跳转链接（可选）

     // 方便调试的 mock
     static func mock() -> [NewsItem] {
         return [
             .init(title: "北坡粉雪上线，雪况超出预期！",
                   imageName: "news1", imageURL: nil, linkURL: nil),
             .init(title: "本周末冷空气来袭，雪场补雪计划发布",
                   imageName: "news2", imageURL: nil, linkURL: nil),
             .init(title: "压雪车全线检修，夜滑品质升级",
                   imageName: "news3", imageURL: nil, linkURL: nil),
             .init(title: "资深教练讲解 carving 入门要点",
                   imageName: "news4", imageURL: nil, linkURL: nil)
         ]
     }
 }

 // MARK: - 横向列表容器
 struct NewsCarousel: View {
     let items: [NewsItem]
     var onTap: (NewsItem) -> Void

     private let cardWidth: CGFloat = 240
     private let cardHeight: CGFloat = 150
     private let spacing: CGFloat = 12

     var body: some View {
         ScrollView(.horizontal, showsIndicators: false) {
             HStack(spacing: spacing) {
                 ForEach(items) { item in
                     Button {
                         onTap(item)
                     } label: {
                         NewsCard(item: item, width: cardWidth, height: cardHeight)
                     }
                     .buttonStyle(.plain)
                 }
             }
             .padding(.trailing, 20) // 让右边也和页面边距对齐
         }
     }
 }

 // MARK: - 单个资讯卡片
 private struct NewsCard: View {
     let item: NewsItem
     let width: CGFloat
     let height: CGFloat

     @Environment(\.colorScheme) private var scheme
     private var border: Color { scheme == .dark ? .white.opacity(0.10) : .black.opacity(0.08) }
     private var shadow: Color { scheme == .dark ? .clear : .black.opacity(0.06) }

     var body: some View {
         ZStack(alignment: .bottomLeading) {
             // 背景图：优先远程，其次本地占位，最后灰底
             Group {
                 if let url = item.imageURL {
                     AsyncImage(url: url) { phase in
                         switch phase {
                         case .success(let img):
                             img.resizable().scaledToFill()
                         default:
                             placeholder
                         }
                     }
                 } else if let name = item.imageName, let img = UIImage(named: name) {
                     Image(uiImage: img).resizable().scaledToFill()
                 } else {
                     placeholder
                 }
             }
             .frame(width: width, height: height)
             .clipped()

             // 渐变遮罩，突出标题可读性
             LinearGradient(
                 colors: [Color.black.opacity(0.0), Color.black.opacity(0.55)],
                 startPoint: .top, endPoint: .bottom
             )
             .frame(height: height)
             .allowsHitTesting(false)

             // 标题
             Text(item.title)
                 .font(.subheadline.weight(.semibold))
                 .foregroundStyle(.white)
                 .lineLimit(2)
                 .padding(12)
         }
         .frame(width: width, height: height)
         .background(
             RoundedRectangle(cornerRadius: 16, style: .continuous)
                 .fill(.ultraThinMaterial.opacity(0.0001)) // 保持与首页风格统一的材质边框
         )
         .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
         .overlay(
             RoundedRectangle(cornerRadius: 16, style: .continuous)
                 .stroke(border, lineWidth: 1 / UIScreen.main.scale)
         )
         .shadow(color: shadow, radius: 12, x: 0, y: 6)
     }

     private var placeholder: some View {
         ZStack {
             Rectangle().fill(Color.gray.opacity(0.14))
             Image(systemName: "photo")
                 .font(.system(size: 28, weight: .semibold))
                 .foregroundStyle(.secondary)
         }
     }
 }



 private struct BindResortToast: View {
     var onAction: () -> Void
     var onClose: () -> Void
     @Environment(\.colorScheme) private var scheme

     var body: some View {
         VStack(alignment: .leading, spacing: 12) {
             HStack(spacing: 10) {
                 ZStack {
                     RoundedRectangle(cornerRadius: 8, style: .continuous)
                         .fill(Color.blue.opacity(0.15))
                     Image(systemName: "mappin.and.ellipse")
                         .font(.callout.weight(.semibold))
                         .foregroundStyle(.blue)
                 }
                 .frame(width: 28, height: 28)

                 Text("去“雪场”页绑定你的常用雪场")
                     .font(.headline)
                     .lineLimit(2)

                 Spacer()

                 Button(action: onClose) {
                     Image(systemName: "xmark")
                         .font(.system(size: 12, weight: .bold))
                         .foregroundStyle(.secondary)
                         .padding(8)
                 }
                 .buttonStyle(.plain)
             }

             Button(action: onAction) {
                 Text("知道了")
                     .font(.subheadline.weight(.bold))
                     .frame(maxWidth: .infinity)
                     .padding(.vertical, 10)
                     .background(Capsule().fill(scheme == .dark ? .white : .black))
                     .foregroundStyle(scheme == .dark ? .black : .white)
             }
             .buttonStyle(.plain)
         }
         .padding(16)
         .background(
             RoundedRectangle(cornerRadius: 22, style: .continuous)
                 .fill(scheme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.10) : .white)
         )
         .overlay(
             RoundedRectangle(cornerRadius: 22, style: .continuous)
                 .stroke(scheme == .dark ? .white.opacity(0.10) : .black.opacity(0.08),
                         lineWidth: 1 / UIScreen.main.scale)
         )
         .shadow(color: scheme == .dark ? .clear : .black.opacity(0.06),
                 radius: 10, x: 0, y: 8)
     }
 }
 */
