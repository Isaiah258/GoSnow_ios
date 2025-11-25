//
//  UIPrimitives.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/9/22.
//

import SwiftUI
import UIKit

// 全站通用：卡片容器（与首页一致）
public struct RoundedContainer<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder public var content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
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

// 小图标徽章（用于卡片标题左侧）
public struct IconBadge: View {
    public let system: String
    public let tint: Color

    public init(system: String, tint: Color) {
        self.system = system
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tint.opacity(0.15))
            Image(systemName: system)
                .font(.callout.weight(.semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 28, height: 28)
    }
}

// 胶囊按钮（黑/红两种风格）
public enum CapsuleStyle {
    case normal, destructive
}

public struct CapsuleButton: View {
    public let title: String
    public var style: CapsuleStyle = .normal

    public init(title: String, style: CapsuleStyle = .normal) {
        self.title = title
        self.style = style
    }

    public var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(style == .normal ? Color.black : Color.red)
            )
            .foregroundStyle(.white)
    }
}

// 轻量信息 Chip（支持可选色）
public struct InfoChip: View {
    public let icon: String
    public let text: String
    public var tint: Color? = nil

    public init(icon: String, text: String, tint: Color? = nil) {
        self.icon = icon
        self.text = text
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.footnote.weight(.semibold))
            Text(text).font(.footnote.weight(.medium)).lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill((tint ?? Color.primary).opacity(0.08)))
        .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1 / UIScreen.main.scale))
        .foregroundStyle(tint ?? .primary)
    }
}



