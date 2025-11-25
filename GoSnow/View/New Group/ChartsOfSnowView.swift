//
//  ChartsOfSnowView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/15.
//

import SwiftUI
import Charts
import Supabase

struct ChartsOfSnowView: View {
    @State private var showSheet1 = false
    @State private var showSheet2 = false
    @State private var showSheet3 = false
    @State private var showFullImage = false // 用于控制图片全屏显示
    @State private var resortData: Resorts_data? // 这是特定的雪场数据
    @State private var mapImage: Image? // 用于显示缓存的地图图片
    @State private var weeklySnowData: [WeeklySnowData] = []
    @State private var yesterdayLiftWaitData: [YesterdayLiftWaitTime] = []
    @AppStorage("favoriteResortId") private var favoriteResortId: Int? // 保存常用雪场 ID
    @State var resorts_data: [Resorts_data] = []
    let cacheExpiryInterval: TimeInterval = 7 * 24 * 60 * 60 // 7天缓存有效期，秒数表示

    var resortId: Int

    var body: some View {
        
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    if let resort = resortData {
                        /*
                        HStack {
                            Text(resort.name_resort) // 使用 Supabase 中的雪场名称
                                .font(.headline)
                            Spacer()
                            
                            // 添加收藏按钮
                            Button(action: {
                                if favoriteResortId == resortId {
                                    favoriteResortId = nil // 取消收藏
                                } else {
                                    favoriteResortId = resortId // 设置为常用雪场
                                }
                            }) {
                                Image(systemName: favoriteResortId == resortId ? "star.fill" : "star")
                                    .foregroundColor(favoriteResortId == resortId ? .yellow : .gray)
                            }
                            .padding(.trailing, 35)
                        }
                        .padding(.leading)
                        */
                        HStack {
                            Button(action: { self.showSheet1 = true }) {
                                VStack(spacing: 10) {
                                    Image(systemName: "cloud.fill")
                                        .foregroundColor(Color("ShareWeather"))
                                    Text("报告雪况")
                                        .foregroundColor(Color("ShareWeather"))
                                }
                                .frame(width: 150, height: 80)
                                .background(RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("ShareWeatherBackground")))
                            }
                            .sheet(isPresented: $showSheet1) { Sheet1View(resortId: resortId) }
                            .presentationDetents([.fraction(0.5)])

                            Button(action: { self.showSheet2 = true }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "face.smiling.inverse")
                                        .foregroundColor(Color("ShareWeather"))
                                    Text("报告人流量")
                                        .foregroundColor(Color("ShareWeather"))
                                }
                                .frame(width: 150, height: 80)
                                .background(RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("ShareWeatherBackground")))
                            }
                            .sheet(isPresented: $showSheet2) { Sheet2View(resortId: resortId) }
                            .presentationDetents([.fraction(0.5)])

                            Button(action: { self.showSheet3 = true }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(Color("ShareWeather"))
                                }
                                .frame(width: 50, height: 80)
                                .background(RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("ShareWeatherBackground")))
                            }
                            .sheet(isPresented: $showSheet3) { Sheet3View(resortId: resortId) }
                            .presentationDetents([.fraction(0.5)])
                        }

                        // 显示额外的雪场信息
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 20) {
                                VStack {
                                    Text("\(resort.trail_count ?? 0)")
                                        .font(.title3)
                                    Text("雪道数量")
                                }
                                Divider()
                                VStack {
                                    Text(String(format: "%.1f km", resort.trail_length ?? 0.0))
                                        .font(.title3)
                                    Text("雪道长度")
                                }

                                Divider()
                                VStack {
                                    Text("\(resort.lift_count ?? 0)")
                                        .font(.title3)
                                    Text("缆车数量")
                                }
                                Divider()
                                VStack {
                                    Text("\(resort.carpet_count ?? 0)")
                                    Text("魔毯数量")
                                }
                                Divider()
                                VStack {
                                    Text("\(resort.park ?? "无")")
                                    Text("公园")
                                }
                                Divider()
                                VStack {
                                    Text("\(resort.backcountry ?? "无")")
                                    Text("野雪")
                                }
                                Divider()
                                VStack {
                                    Text("\(resort.night ?? "无")")
                                    Text("夜场")
                                }
                            }
                            .padding()
                        }
                        .frame(height: 80)
                        Divider()

                        // 显示雪场地图和雪况
                        VStack(alignment: .leading, spacing: 20) {
                            Section {
                                VStack(alignment: .leading) {
                                    Text("雪场地图")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .padding(.bottom, 5)

                                    if let cachedImage = getCachedMapImage() {
                                        cachedImage
                                            .resizable()
                                            .scaledToFit()
                                            .cornerRadius(10)
                                            .onTapGesture { showFullImage = true }
                                            .fullScreenCover(isPresented: $showFullImage) {
                                                if let validUrl = URL(string: resort.map_url ?? "") {
                                                    ZoomableImageFullScreen(url: validUrl)
                                                } else {
                                                    ZStack {
                                                        Color.black.ignoresSafeArea()
                                                        Text("无效的地图 URL").foregroundColor(.white)
                                                    }
                                                }
                                            }

                                    } else if let mapUrlString = resort.map_url, let mapUrl = URL(string: mapUrlString) {
                                        AsyncImage(url: mapUrl) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                                    .cornerRadius(10)
                                                    .onTapGesture { showFullImage = true }
                                                    .fullScreenCover(isPresented: $showFullImage) {
                                                        if let validUrl = URL(string: resort.map_url ?? "") {
                                                            ZoomableImageFullScreen(url: validUrl)
                                                        } else {
                                                            ZStack {
                                                                Color.black.ignoresSafeArea()
                                                                Text("无效的地图 URL").foregroundColor(.white)
                                                            }
                                                        }
                                                    }

                                            case .failure(_):
                                                Text("图片加载失败")
                                            default:
                                                ProgressView()
                                            }
                                        }
                                        .onAppear {
                                            Task {
                                                await cacheMapImage(from: mapUrl) // 移到这里
                                            }
                                        }
                                    } else {
                                        Text("无可用地图")
                                            .foregroundColor(.gray)
                                    }
                                }


                            }
                            Section {
                                if weeklySnowData.isEmpty {
                                    // 如果没有数据，显示提示信息
                                    VStack {
                                        Text("当前没有足够的数据汇总一周的雪况")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding()
                                        
                                    }
                                } else {
                                    // 有数据时显示正常的 Chart
                                    let domain = SnowConditionOrder.map { SnowConditionLabel[$0]! }
                                    let range  = SnowConditionOrder.map { SnowConditionColor[$0]! }

                                    Chart(weeklySnowData) { d in
                                        BarMark(x: .value("雪况", d.snowCondition),
                                                y: .value("次数", d.count))
                                            .cornerRadius(4)
                                    }
                                    .chartXScale(domain: domain)
                                    .chartForegroundStyleScale(domain: domain, range: range)
                                    .padding(20)
                                    .frame(height: 300)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                }
                            } header: {
                                Text("近一周雪况")
                                    .font(.title3)
                                    .bold()
                                    .textCase(.uppercase)
                            }

                            
                            Section {
                                if yesterdayLiftWaitData.isEmpty {
                                    VStack {
                                        Text("当前没有足够的昨日缆车等待时间数据")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding()
                                    }
                                } else {
                                    let wDomain = WaitBinOrder.map { WaitBinLabel[$0]! }
                                    let wRange  = WaitBinOrder.map { WaitBinColor[$0]! }

                                    Chart(yesterdayLiftWaitData) { d in
                                        BarMark(x: .value("等待时间", d.waitTime),
                                                y: .value("次数", d.count))
                                            .cornerRadius(4)
                                    }
                                    .chartXScale(domain: wDomain)
                                    .chartForegroundStyleScale(domain: wDomain, range: wRange)
                                    .padding(20)
                                    .frame(height: 300)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                }
                                
                            } header: {
                                Text("昨日缆车等待情况")
                                    .font(.title3)
                                    .bold()
                                    .textCase(.uppercase)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            
                        }
                        .padding()
                    } else {
                        Text("加载中...") // 无数据时显示加载提示
                    }
                }
            }
            .background(.ultraThinMaterial)
            .navigationTitle(resortData?.name_resort ?? "加载中...") // 依赖加载的雪场数据
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: fetchResorts) // 页面出现时调用数据加载
        
    }

    // 基于 resortId 获取雪场数据
    func fetchResorts() {
            // 先检查缓存
            if let cachedData = getCachedResortData() {
                self.resortData = cachedData
                return
            }
            
            // 如果没有缓存或缓存过期，从 Supabase 获取
            Task {
                do {
                    let manager = DatabaseManager.shared
                    let resorts: [Resorts_data] = try await manager.client.from("Resorts_data").select().execute().value
                    
                    if let foundResort = resorts.first(where: { $0.id == resortId }) {
                        resortData = foundResort
                        cacheResortData(foundResort) // 获取成功后缓存数据
                    } else {
                        print("未找到匹配的雪场")
                    }
                } catch {
                    dump(error)
                }
            }
        }
    
    func fetchSnowDataForPastWeek() async throws -> [WeeklySnowData] {
        let manager = DatabaseManager.shared
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!

        // ✅ 过滤到当前雪场、近 7 天
        let rows: [DailySnowConditions] = try await manager.client
            .from("DailySnowConditions")
            .select()
            .eq("resort_id", value: resortId)
            .gte("date", value: sevenDaysAgo)
            .lte("date", value: now)
            .execute()
            .value

        // ✅ 统一映射 & 聚合
        var bucket: [SnowCondition: Int] = [:]
        for r in rows {
            let c = normalizeSnowCondition(r.condition)
            bucket[c, default: 0] += 1
        }

        // ✅ 按固定顺序输出，避免图表顺序乱跳
        return SnowConditionOrder.map { cond in
            WeeklySnowData(snowCondition: SnowConditionLabel[cond]!, count: bucket[cond, default: 0])
        }.filter { $0.count > 0 } // 没数据的不画（也可保留为 0）
    }


    

    func fetchWeeklySnowData() {
        Task {
            do {
                let data = try await fetchSnowDataForPastWeek()
                self.weeklySnowData = data
            } catch {
                print("Error fetching weekly snow data: \(error)")
                self.weeklySnowData = []
            }
        }
    }
    
    func fetchLiftWaitData() {
            Task {
                do {
                    let manager = DatabaseManager.shared
                    // 假设 LiftWaitCount 是你用来处理汇总数据的结构
                    let response = try await manager.client
                        .from("LiftWaitTime")
                        .select()
                        .execute()
                    
                    // 在这里解析响应并填充 liftWaitData
                    // 你需要根据需要进行数据处理和分组
                    print("数据获取成功: \(response)")
                } catch {
                    print("数据获取失败: \(error.localizedDescription)")
                }
            }
        }
    
    func fetchYesterdayLiftWaitData() {
            Task {
                do {
                    let data = try await fetchLiftWaitDataForYesterday()
                    self.yesterdayLiftWaitData = data
                } catch {
                    print("Error fetching yesterday lift wait data: \(error)")
                    self.yesterdayLiftWaitData = []
                }
            }
        }

    func fetchLiftWaitDataForYesterday() async throws -> [YesterdayLiftWaitTime] {
        let manager = DatabaseManager.shared
        let cal = Calendar.current
        let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -1, to: Date())!)
        let end   = cal.date(byAdding: .day, value: 1, to: start)! // 次日 0 点

        // ✅ 按雪场 + 日区间过滤（避免精确等值匹配失败）
        let rows: [LiftWaitTime] = try await manager.client
            .from("LiftWaitTime")
            .select()
            .eq("resort_id", value: resortId)
            .gte("date", value: start)
            .lt("date", value: end)
            .execute()
            .value

        // ✅ 分桶（支持字符串或分钟）
        var bucket: [WaitBin: Int] = [:]
        for r in rows {
            // 假设你的表字段是 String（如果是 Int 分钟，替换成 binWait(minutes: r.wait_minutes)）
            let b = binWait(r.wait_time)
            bucket[b, default: 0] += 1
        }

        // ✅ 稳定顺序 + 标签
        return WaitBinOrder.map { b in
            YesterdayLiftWaitTime(waitTime: WaitBinLabel[b]!, count: bucket[b, default: 0])
        }.filter { $0.count > 0 }
    }

    
    // 使用缓存机制
        func cacheResortData(_ data: Resorts_data) {
            let encodedData = try? JSONEncoder().encode(data)
            UserDefaults.standard.set(encodedData, forKey: "cachedResortData_\(resortId)")
            UserDefaults.standard.set(Date(), forKey: "resortDataCacheDate_\(resortId)")
        }

        func getCachedResortData() -> Resorts_data? {
            if let cacheDate = UserDefaults.standard.object(forKey: "resortDataCacheDate_\(resortId)") as? Date,
               Date().timeIntervalSince(cacheDate) < cacheExpiryInterval {
                if let data = UserDefaults.standard.data(forKey: "cachedResortData_\(resortId)"),
                   let decodedData = try? JSONDecoder().decode(Resorts_data.self, from: data) {
                    return decodedData
                }
            }
            return nil
        }

    // 下载并缓存图片
    func cacheMapImage(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            UserDefaults.standard.set(data, forKey: "cachedMapImage_\(resortId)")
            UserDefaults.standard.set(Date(), forKey: "mapImageCacheDate_\(resortId)")
            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.mapImage = Image(uiImage: image)
                }
            }
        } catch {
            print("图片缓存失败：\(error.localizedDescription)")
        }
    }

    // 从缓存中读取图片
    func getCachedMapImage() -> Image? {
        if let cacheDate = UserDefaults.standard.object(forKey: "mapImageCacheDate_\(resortId)") as? Date,
           Date().timeIntervalSince(cacheDate) < cacheExpiryInterval {
            if let data = UserDefaults.standard.data(forKey: "cachedMapImage_\(resortId)"),
               let uiImage = UIImage(data: data) {
                return Image(uiImage: uiImage)
            }
        }
        return nil
    }

}


struct WeeklySnowData: Identifiable {
    var id = UUID()
    var snowCondition: String
    var count: Int // 统计该雪况出现的次数
}

struct YesterdayLiftWaitTime: Identifiable {
    var id = UUID()
    var waitTime: String // 等待时间描述
    var count: Int // 该等待时间出现的次数
}


#Preview {
    ChartsOfSnowView(resortId: 2) // 测试时使用特定的雪场ID
}




// MARK: 雪况：统一分类 + 标签 + 颜色 + 顺序
enum SnowCondition: String, CaseIterable {
    case powder, groomed, packed, icy, slush, wet, unknown
}
let SnowConditionOrder: [SnowCondition] = [.powder, .groomed, .packed, .icy, .slush, .wet, .unknown]
let SnowConditionLabel: [SnowCondition: String] = [
    .powder: "粉雪", .groomed: "压雪", .packed: "硬实", .icy: "结冰",
    .slush: "湿重", .wet: "融雪", .unknown: "其他"
]
let SnowConditionColor: [SnowCondition: Color] = [
    .powder: .blue, .groomed: .green, .packed: .gray, .icy: .cyan,
    .slush: .orange, .wet: .teal, .unknown: .secondary
]
func normalizeSnowCondition(_ raw: String) -> SnowCondition {
    let s = raw.lowercased()
    if s.contains("粉") || s.contains("powder") { return .powder }
    if s.contains("压") || s.contains("groom")  { return .groomed }
    if s.contains("硬") || s.contains("packed") { return .packed }
    if s.contains("冰") || s.contains("icy")    { return .icy }
    if s.contains("湿") || s.contains("slush")  { return .slush }
    if s.contains("融") || s.contains("wet")    { return .wet }
    return .unknown
}

// MARK: 缆车等待：统一分桶（分钟）+ 标签 + 顺序
enum WaitBin: String, CaseIterable, Identifiable {
    case lt5, m5_10, m10_20, m20_30, gt30
    var id: String { rawValue }
}
let WaitBinOrder: [WaitBin] = [.lt5, .m5_10, .m10_20, .m20_30, .gt30]
let WaitBinLabel: [WaitBin: String] = [
    .lt5: "<5", .m5_10: "5–10", .m10_20: "10–20", .m20_30: "20–30", .gt30: "30+"
]
let WaitBinColor: [WaitBin: Color] = [
    .lt5: .green, .m5_10: .mint, .m10_20: .yellow, .m20_30: .orange, .gt30: .red
]

// 支持字符串（"短/中/长" 或 "10-20 分钟"）与数值两种来源
func binWait(_ value: String) -> WaitBin {
    let s = value.trimmingCharacters(in: .whitespacesAndNewlines)
    // 直接映射短/中/长
    if s.contains("短") { return .m5_10 }
    if s.contains("中") { return .m10_20 }
    if s.contains("长") { return .m20_30 }
    // 抽取数字区间
    let nums = s.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
    let m = nums.isEmpty ? nil : (nums.count == 1 ? nums[0] : (nums[0] + nums[1]) / 2)
    return binWait(minutes: m)
}
func binWait(minutes: Int?) -> WaitBin {
    guard let m = minutes else { return .m10_20 } // 无法解析时给个中档
    switch m {
    case ..<5: return .lt5
    case 5..<10: return .m5_10
    case 10..<20: return .m10_20
    case 20..<30: return .m20_30
    default: return .gt30
    }
}




