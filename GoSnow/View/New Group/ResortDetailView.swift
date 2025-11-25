//
//  ResortDetailView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/7/14.
//

/*import SwiftUI
import MapKit
import Charts

struct ResortDetailView: View {
    let resorts: Resorts
    //let ResortName: String // 雪场名称
    //let Location: String // 雪场地点
    let altitude: String // 海拔
    let verticalDrop: String // 落差
    let trailLength: String // 雪道长度
    let liftCount: String // 缆车数量
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // 雪场名称和地点
                HStack {
                    Text(resorts.ResortsName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer() 
                }
                Text(resorts.Location)
                    .font(.headline)
                Spacer()
                // 雪场数据
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "arrowtriangle.up.fill")
                            Text("海拔: \(altitude)")
                        }
                        HStack {
                            Image(systemName: "arrowtriangle.down.fill")
                            Text("落差: \(verticalDrop)")
                        }
                    }
                    .fontWeight(.semibold)
                    Spacer()
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "arrowtriangle.right.fill")
                            Text("雪道长度: \(trailLength)")
                        }
                        HStack {
                            Image(systemName: "figure.seated.seatbelt")
                            Text("缆车数量: \(liftCount)")
                        }
                    }
                    .fontWeight(.semibold)
                }
                .padding()
                .frame(width: 360,height: 100)
                .background(Color.cyan)
                .cornerRadius(10)

                // 雪场地图
                VStack(alignment: .leading) {
                    Text("雪场地图")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.bottom, 5)
                    Image("resorts-wanlong")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                    HStack {
                        Spacer()
                        Text("点击下载原图")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                        Spacer()
                    }
                }
                
                // 雪友评价
                VStack(alignment: .leading) {
                    Text("雪况评价")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.bottom, 5)

                    // 过去 48 小时雪况评价
                    
                    SnowConditionChartView()
                        .frame(width: 350)
                    

                    // 过去一周雪况评价
                    SnowConditionChart2View()
                        .frame(width: 350)
                        .padding(.top, 10)
                }
                .padding(.bottom)

                // 雪场联系方式/官方网站
                VStack(alignment: .leading) {
                    Text("联系方式")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.bottom, 5)
                    Text("电话: (555) 555-5555")
                    Text("网址: www.example-resort.com")
                }
            }
            .padding() //
        }
    }
}





#Preview {
    ResortDetailView(resorts: resorts[0], altitude: "2000", verticalDrop: "1000", trailLength: "50", liftCount: "10")
}
*/
