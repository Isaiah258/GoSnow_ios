//
//  tempo.swift
//  GoSnow
//
//  Created by federico Liu on 2024/9/12.
//

import SwiftUI

struct tempo: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
/*
 
 import SwiftUI
 import Supabase


 struct ResortsView: View {
     @State private var searchTerm = ""
     @State var resorts_data: [Resorts_data] = []
     
     
     var body: some View {
         NavigationStack {
             ScrollView {
                 VStack {
                     
                     if searchTerm.isEmpty { // No search or empty search term
                         // Display the original ScrollView section
                         VStack {
                             HStack {
                                 Text("热门雪场")
                                     .font(.subheadline)
                                     .fontWeight(.bold)
                                     .padding(.leading, 20)
                                     .padding(.top)
                                 Spacer()
                             }
                             
                             ScrollView {
                                 ScrollView(.horizontal, showsIndicators: false){
                                     HStack{
                                         ForEach(resorts) { resorts in
                                             ResortsRowView(resorts: resorts)
                                         }
                                     }
                                 }
                             }
                         }
                     } else {
                         // Display the filtered results in a List
                         List {
                             ForEach(filteredResorts, id: \.id) { resorts_data in
                                 Text(resorts_data.name_resort) // Or use your custom ResortsRowView here
                             }
                         }
                         .listStyle(.plain)
                     }
                     
                     
                 }
                 .navigationTitle("雪场")
             }
             
         }
         
         .searchable(text: $searchTerm, prompt: "搜索雪场")
         .task {
             do {
             let manager = DatabaseManager.shared
                 resorts_data = try await manager.client.from("Resorts_data").select().execute().value
             } catch {
                 dump(error)
             }
         }
     }
     
     var filteredResorts: [Resorts_data] {
         if searchTerm.isEmpty {
             return resorts_data
         } else {
             return resorts_data.filter {
                 $0.name_resort.localizedCaseInsensitiveContains(searchTerm)
             }
         }
     }
 }





 #Preview {
     ResortsView()
 }
 
 
 */
    }
}

#Preview {
    tempo()
}
