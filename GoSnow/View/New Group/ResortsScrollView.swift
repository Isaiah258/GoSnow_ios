//
//  ResortsScrollView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/12.
//
/*
import SwiftUI


struct ResortsScrollView: View {
    @State var resorts_data: [Resorts_data] = []
    let resorts: Resorts
    
    var body: some View {
        VStack(alignment: .leading){
            resorts.image
                .resizable()
                .aspectRatio(CGSize(width: 1, height: 1),contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Text("\(Text("\(resorts.ResortsName)").font(.headline).fontWeight(.bold).baselineOffset(-6.6))")
            
            Text(resorts.Location)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom)
            
            Button {
                //add
            } label: {
                Text("详情")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ResortsScrollView(resorts: resorts[0])
}
 
 
 
 import SwiftUI

 struct SnowConditionChartView: View {
     let conditions: [SnowCondition] = [
         .hardpack, .groomed, .slushy, .icy, .wet, .powder,
     ]
     let reports: [CGFloat] = [0.6, 0.8, 0.3, 0.1, 0.2, 0.1, 0.05] // Example report data (replace with actual data)

     var body: some View {
         VStack{
             Text("过去48小时")
                 .font(.headline)
             VStack(alignment: .leading, spacing: 10) {
                 // Title
                 
                 HStack(spacing: 25) { // Chart bars
                     ForEach(conditions.indices, id: \.self) { index in
                         BarView(condition: conditions[index], value: reports[index])
                     }
                 }
                 
                 HStack { // Condition icons and labels
                     ForEach(conditions, id: \.self) { condition in
                         VStack {
                             Image(systemName: condition.iconName)
                                 .font(.caption)
                             Text(condition.rawValue)
                                 .font(.caption2)
                             
                         }
                     }
                 }
             }
         }
     }
 }

 // BarView for individual bars
 struct BarView: View {
     let condition: SnowCondition
     let value: CGFloat

     var body: some View {
         ZStack(alignment: .bottom) {
             RoundedRectangle(cornerRadius: 5)
                 .fill(Color.gray.opacity(0.3)) // Background bar
                 .frame(width: 25, height: 100)
             RoundedRectangle(cornerRadius: 5)
                 .fill(condition.color) // Filled portion of the bar
                 .frame(width: 25, height: value * 100)
         }
     }
 }

 // SnowCondition enum for different conditions
 enum SnowCondition: String, CaseIterable {
     case hardpack = "硬雪"
     case groomed = "机压雪"
     case slushy = "烂雪"
     case icy = "多冰"
     case wet = "湿雪"
     case powder = "粉雪"
     

     var iconName: String {
         switch self {
         case .hardpack: return "snowflake"
         case .groomed: return "snowflake.circle"
         case .slushy: return "equal"
         case .icy: return "waveform.path.ecg"
         case .wet: return "drop.fill"
         case .powder: return "smoke.fill"
         
         }
     }

     var color: Color {
         switch self {
         case .hardpack: return .blue
         case .groomed: return .green
         case .slushy: return .yellow
         case .icy: return .cyan
         case .wet: return .orange
         case .powder: return .yellow
         
         }
     }
 }


 #Preview {
     SnowConditionChartView()
 }
 
 
 
 import SwiftUI

 struct ResortsHeaderView: View {
     var body: some View {
         HStack{
             Label("Resorts", systemImage: "flag")
                 .font(.caption)
             
             Spacer()
             
             Button{
                 //
             } label: {
                 Image(systemName: "pencil.and.list.clipboard.rtl")
             }
         }
         .padding(.bottom)
     }
 }

 #Preview {
     ResortsHeaderView()
 }
 
 
 import SwiftUI

 struct ResortsRowView: View {
     let resorts: Resorts
     
     var body: some View {
         VStack{
             ResortsHeaderView()
             ResortsScrollView(resorts: resorts)
         }
         .padding()
         .background(Color(.systemFill))
         .clipShape(RoundedRectangle(cornerRadius: 18))
         .frame(width: 172)
         .padding(.horizontal, 8)
         
     }
 }


 #Preview {
     ResortsRowView(resorts: resorts[0])
 }
 
 
 */




 
 
 


