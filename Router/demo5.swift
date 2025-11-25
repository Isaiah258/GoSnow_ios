//
//  demo5.swift
//  GoSnow
//
//  Created by federico Liu on 2024/9/12.
//

import SwiftUI
import Supabase

struct demo5: View {

  @State var countries: [Country] = []

  var body: some View {
    List(countries) { country in
      Text(country.name)
    }
    .overlay {
      if countries.isEmpty {
        ProgressView()
      }
    }
    .task {
      do {
          let manager = DatabaseManager.shared
          
          countries = try await manager.client.from("countries").select().execute().value
      } catch {
        dump(error)
      }
    }
  }
}

#Preview {
    demo5()
}


/*
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
     <key>MKDirectionsApplicationSupportedModes</key>
     <array/>
     <key>NSUserActivityTypes</key>
     <array>
         <string>StartIntent</string>
         <string>StopIntent</string>
     </array>
     <key>CFBundleIcons</key>
     <dict>
         
         <key>CFBundleAlternateIcons</key>
         <dict>
             <key>AppIcon_white</key>
             <dict>
                 <key>CFBundleIconFiles</key>
                 <array>
                     <string>AppIcon_white</string>
                 </array>
             </dict>
             <key>AppIcon_red</key>
             <dict>
                 <key>CFBundleIconFiles</key>
                 <array>
                     <string>AppIcon_red</string>
                 </array>
             </dict>
             <key>AppIcon_yellow</key>
             <dict>
                 <key>CFBundleIconFiles</key>
                 <array>
                     <string>AppIcon_yellow</string>
                 </array>
             </dict>
             <dict>
                 <key>CFBundleIconFiles</key>
                 <array>
                     <string>AppIcon_blue</string>
                 </array>
             </dict>
             <dict>
                 <key>CFBundleIconFiles</key>
                 <array>
                     <string>AppIcon_cyan</string>
                 </array>
             </dict>
             <dict>
                 <key>CFBundleIconFiles</key>
                 <array>
                     <string>AppIcon_green</string>
                 </array>
             </dict>
             <dict>
                 <key>CFBundleIconFiles</key>
                 <array>
                     <string>AppIcon_lavender</string>
                 </array>
             </dict>
             <dict>
                 <key>CFBundleIconFiles</key>
                 <array>
                     <string>AppIcon_Christmas</string>
                 </array>
             </dict>
         </dict>
     </dict>

 </dict>
 </plist>

 */
