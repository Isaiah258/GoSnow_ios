//
//  demo6.swift
//  GoSnow
//
//  Created by federico Liu on 2024/9/29.
//
/*
import SwiftUI
import Supabase


struct demo6: View {
    @State private var searchTerm = ""
    @State var resorts_data: [Resorts_data] = []
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    
                    if searchTerm.isEmpty {
                        
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
                        
                        List {
                            ForEach(filteredResorts, id: \.id) { resorts_data in
                                Text(resorts_data.name_resort)
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
            return Array(resorts_data.prefix(10))
        } else {
            return resorts_data.filter { $0.name_resort.contains(searchTerm) }
        }
    }
}

#Preview {
    demo6()
}
*/
