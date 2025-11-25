//
//  DailySnowView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/6/18.
//

import SwiftUI

struct DailySnowView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 14) {
                        // 雪圈
                       

                        // 雪场（与雪圈同级）
                        CardLink(
                            title: "雪场",
                            subtitle: "搜索雪场、看数据与图表",
                            icon: "map.fill",
                            tint: .green
                        ) {
                            ResortsView()
                        }

                        // 失物招领
                        CardLink(
                            title: "失物招领",
                            subtitle: "丢失？捡到？这里快速对接",
                            icon: "magnifyingglass",
                            tint: .purple
                        ) {
                            LostAndFoundView()
                        }
                        
                        // 顺风车
                        CardLink(
                            title: "顺风车",
                            subtitle: "按雪场/日期找同行",
                            icon: "car.fill",      // 如想更像拼车可试 "car.2.fill"（iOS 16+）
                            tint: .orange
                        ) {
                            CarpoolView()
                        }
                        /*
                        CardLink(
                            title: "测试",
                            subtitle: "测试",
                            icon: "car.fill",      // 如想更像拼车可试 "car.2.fill"（iOS 16+）
                            tint: .orange
                        ) {
                            SkiMapKitDemoView()
                        }
                        */


                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("发现")
        }
    }
}

#Preview {
    DailySnowView()
}

// MARK: - 统一风格卡片链接（复用你项目里的 RoundedContainer / IconBadge）
private struct CardLink<Destination: View>: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    let tint: Color
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination().navigationBarTitleDisplayMode(.inline)) {
            RoundedContainer {
                HStack(spacing: 14) {
                    IconBadge(system: icon, tint: tint)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if let subtitle {
                            Text(subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 72)
            }
        }
        .buttonStyle(.plain)
    }
}




/*
// MARK: - 与首页一致的通用容器/图标
private struct RoundedContainer<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder var content: Content

    var body: some View {
        let surface: Color = scheme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.10) : .white
        let border:  Color = scheme == .dark ? .white.opacity(0.10) : .black.opacity(0.08)

        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(border, lineWidth: 1 / UIScreen.main.scale)
                )
                .shadow(color: scheme == .dark ? .clear : .black.opacity(0.06),
                        radius: 10, x: 0, y: 8)
            content
        }
    }
}

private struct IconBadge: View {
    let system: String
    let tint: Color
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tint.opacity(0.15))
            Image(systemName: system)
                .font(.callout.weight(.semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 32, height: 32)
    }
}


*/
/*
 
 import SwiftUI

 struct DailySnowView: View {
     var body: some View {
         NavigationStack {
             List {
                 Section{
                     NavigationLink(destination: PostMainView()) {
                         HStack(spacing: 11){
                             ZStack{
                                 RoundedRectangle(cornerRadius: 10)
                                     .fill(Color.blue)
                                     .frame(width: 30, height: 30)
                                 Image(systemName: "globe")
                                     .foregroundColor(Color.white)
                             }
                                 
                             Text("雪圈")
                                 .fontWeight(.regular)
                         }
                     }
                 
                     NavigationLink(destination: FriendsView()) {
                         HStack(spacing: 11){
                             ZStack{
                                 RoundedRectangle(cornerRadius: 10)
                                     .fill(Color.yellow)
                                     .frame(width: 30, height: 30)
                                 Image(systemName: "face.smiling")
                                     .foregroundColor(Color.white)
                             }
                             Text("好友列表")
                         }
                     }
                     NavigationLink(destination: LostAndFoundView()) {
                         HStack(spacing: 11){
                             ZStack{
                                 RoundedRectangle(cornerRadius: 10)
                                     .fill(Color.purple)
                                     .frame(width: 30, height: 30)
                                 Image(systemName: "magnifyingglass")
                                     .foregroundColor(Color.white)
                             }
                             Text("失物招领")
                         }
                     }
                 }
                 
                 Section(header:Text("学习")
                     .fontWeight(.semibold)
                 ){
                     NavigationLink(destination: FindCoachView()) {
                         HStack(spacing: 13){
                             
                             ZStack{
                                 RoundedRectangle(cornerRadius: 10)
                                     .fill(Color.mint)
                                     .frame(width: 30, height: 30)
                                 Image(systemName: "person.badge.shield.checkmark")
                                     .foregroundColor(Color.white)
                             }
                             Text("找教练")
                         }
                     }
                     NavigationLink(destination: GuideBookView()) {
                         HStack(spacing: 12){
                             ZStack{
                                 RoundedRectangle(cornerRadius: 10)
                                     .fill(Color.cyan)
                                     .frame(width: 30, height: 30)
                                 Image(systemName: "book")
                                     .foregroundColor(Color.white)
                             }
                             Text("滑雪指南书")
                         }
                     }
                 }
                 Section(header:Text("周边")
                     .fontWeight(.semibold)
                 ){
                     
                     
                     NavigationLink(destination: AppLogoView()) {
                         HStack(spacing: 16){
                             ZStack{
                                 RoundedRectangle(cornerRadius: 10)
                                     .fill(Color.black)
                                     .frame(width: 30, height: 30)
                                 Image(systemName: "flag.checkered")
                                     .foregroundColor(Color.white)
                             }
                             Text("赛事&活动")
                         }
                     }
                     NavigationLink(destination: AppLogoView()) {
                         HStack(spacing: 16){
                             ZStack{
                                 RoundedRectangle(cornerRadius: 10)
                                     .fill(Color.indigo)
                                     .frame(width: 30, height: 30)
                                 Image(systemName: "apps.iphone")
                                     .foregroundColor(Color.white)
                             }
                             Text("App图标")
                         }
                     }
                     /*
                     NavigationLink(destination: AppPlanView()) {
                         HStack(spacing: 16){
                             ZStack{
                                 RoundedRectangle(cornerRadius: 10)
                                     .fill(Color.purple)
                                     .frame(width: 30, height: 30)
                                 Image(systemName: "list.bullet.clipboard")
                                     .foregroundColor(Color.white)
                             }
                             Image(systemName: "list.bullet.clipboard")
                             Text("App更新与规划")
                         }
                     }
                     */
                     NavigationLink(destination: StickerView()) {
                         HStack(spacing: 15){
                             ZStack{
                                 RoundedRectangle(cornerRadius: 10)
                                     .fill(Color.green)
                                     .frame(width: 30, height: 30)
                                 Image(systemName: "tshirt")
                                     .foregroundColor(Color.white)
                             }

                             Text("贴纸与衣服")
                         }
                     }
                 }
             }
             .navigationTitle("发现") // 设置导航栏标题
         }
     }
 }

 #Preview {
     DailySnowView()
 }
 
 */
