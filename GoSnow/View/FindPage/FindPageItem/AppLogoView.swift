//
//  AppLogoView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/7/6.
//

import SwiftUI

enum AppIcon: String, CaseIterable, Identifiable {
    case primary = "AppIcon_real"
    case christmas = "AppIcon_Christmas"
    case white = "AppIcon_white"
    case blue = "AppIcon_blue"
    case yellow = "AppIcon_yellow"
    case red = "AppIcon_red"
    case cyan = "AppIcon_cyan"
    case green = "AppIcon_green"
    case lavender = "AppIcon_lavender"
    

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .primary: 
            return "默认图标"
        case .christmas: 
            return "圣诞节"
        case .blue: 
            return "克莱因"
        case .yellow:
            return "蜂蜜"
        case .red:
            return "枫叶"
        case .cyan:
            return "碧波"
        case .green:
            return "松针"
        case .lavender:
            return "薰衣草"
        case .white:
            return "霜雪"
        }
    }
}

struct AppLogoView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedAppIcon: AppIcon = .primary
    @State private var successMessage: AlertItem? = nil

    private let selectedIconKey = "selectedAppIcon"

    var body: some View {
        NavigationView {
            List {
                ForEach(AppIcon.allCases) { icon in
                    HStack {
                        Image(icon.rawValue)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Text(icon.displayName)
                            .font(.body)

                        Spacer()

                        ZStack {
                            Circle()
                                .stroke(selectedAppIcon == icon ? Color.orange : Color.black, lineWidth: 1)
                                .frame(width: 15, height: 15)

                            if selectedAppIcon == icon {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("点击了图标：\(icon.rawValue)") // 调试输出
                        selectedAppIcon = icon
                        changeAppIcon(to: icon.rawValue)
                    }
                }
            }
            .navigationTitle("更换 App 图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert(item: $successMessage) { alertItem in
                Alert(title: Text("更换结果"), message: Text(alertItem.message), dismissButton: .default(Text("好的")))
            }
        }
        .onAppear {
            if let savedIcon = UserDefaults.standard.string(forKey: selectedIconKey),
               let appIcon = AppIcon(rawValue: savedIcon) {
                selectedAppIcon = appIcon
                print("从 UserDefaults 加载的图标：\(savedIcon)") // 调试输出
            } else {
                print("UserDefaults 中没有保存的图标") // 调试输出
            }
        }
    }

    func changeAppIcon(to iconName: String) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("该设备不支持更换 App 图标")
            successMessage = AlertItem(message: "该设备不支持更换 App 图标") // 添加提示
            return
        }

        UIApplication.shared.setAlternateIconName(iconName == AppIcon.primary.rawValue ? nil : iconName) { error in
            if let error = error {
                print("更换图标失败: \(error.localizedDescription)")
                successMessage = AlertItem(message: "更换图标失败: \(error.localizedDescription)") // 显示更详细的错误信息
            } else {
                print("成功更换 App 图标为 \(iconName)")
                successMessage = AlertItem(message: "成功更换图标为 \(iconName)")

                UserDefaults.standard.set(iconName, forKey: selectedIconKey)
                print("UserDefaults 中保存的图标：\(iconName)") // 调试输出
            }
        }
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    AppLogoView()
}





