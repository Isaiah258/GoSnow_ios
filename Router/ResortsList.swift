import SwiftUI
import Supabase

struct ResortsList: View {
    @State var resorts_data: [Resorts_data] = []
    @State private var isLoading = true
    
    var body: some View {
        List(resorts_data, id: \.id) { resorts_data in
           
                Text(resorts_data.name_resort)
                
            
        }
        .overlay {
            if resorts_data.isEmpty {
                ProgressView()
            }
        }
        .task {
            do {
                let manager = DatabaseManager.shared
               
                resorts_data = try await manager.client.from("Resorts_data").select().execute().value
            } catch {
                dump(error)
            }
        }
    }
}
#Preview {
    ResortsList()
    
}

/*
 .task {
             do {
                 let result = try await DatabaseManager.shared.client
                     .from("resorts") // 假设你的 Supabase 表名为 "resorts"
                     .select("*")
                     .execute()
                 
                 if let resortsData = try? result.decoded(to: [Resorts_data].self) {
                     self.resorts = resortsData
                 } else {
                     print("Error decoding resorts data")
                 }
             } catch {
                 print("Error fetching resorts: \(error)")
             }
         }
 */
