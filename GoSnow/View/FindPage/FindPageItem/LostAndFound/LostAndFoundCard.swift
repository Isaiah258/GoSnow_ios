//
//  LostAndFoundCard.swift
//  GoSnow
//
//  Created by federico Liu on 2024/12/23.
//

import SwiftUI

struct LostAndFoundCard: View {
    let item: LostAndFoundItems
    var resortName: String? = nil  // 由父级传（可选）

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部：类型 + 雪场 + 时间
            HStack(spacing: 8) {
                Tag(text: item.type == "lost" ? "丢失" : "拾到")

                if let resortName, !resortName.isEmpty {
                    Tag(text: resortName, icon: "mountain.2.fill")
                }

                Spacer()

                if let date = item.created_at {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(item.item_description)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if !item.contact_info.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .foregroundStyle(.secondary)
                        Text(item.contact_info)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
}

private struct Tag: View {
    let text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.caption2) }
            Text(text).font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
                .background(
                    Capsule().fill(Color.secondary.opacity(0.08))
                )
        )
        .foregroundStyle(.secondary)
    }
}






/*
 import SwiftUI

 struct LostAndFoundCard: View {
     let item: LostAndFoundItems
     var resortName: String? = nil  // 可选：父级在 join 后传入

     var body: some View {
         VStack(alignment: .leading, spacing: 12) {
             // 顶部：状态徽章 + 雪场 + 时间
             HStack(spacing: 8) {
                 TypeBadge(type: item.type)

                 if let resortName, !resortName.isEmpty {
                     Chip(text: resortName, systemName: "mountain.2.fill")
                 }

                 Spacer()

                 if let date = item.created_at {
                     Text(date, style: .relative) // “xx分钟前”
                         .font(.caption)
                         .foregroundStyle(.secondary)
                 }
             }

             // 内容
             VStack(alignment: .leading, spacing: 8) {
                 HStack(spacing: 6) {
                     Image(systemName: item.type == "lost" ? "person.wave.2" : "tag")
                         .foregroundStyle(.secondary)
                     Text(item.type == "lost" ? "丢失物品" : "找到物品")
                         .font(.subheadline).bold()
                 }
                 .foregroundStyle(.primary)

                 Text(item.item_description)
                     .font(.body)
                     .foregroundStyle(.primary)
                     .lineLimit(3)
             }

             // 联系方式（按钮化）
             if !item.contact_info.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                 HStack(spacing: 8) {
                     ContactButton(contact: item.contact_info)
                     Spacer()
                 }
                 .padding(.top, 4)
             }
         }
         .padding(16)
         .background(
             RoundedRectangle(cornerRadius: 16, style: .continuous)
                 .fill(Color(.systemBackground))
                 .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
         )
     }
 }

 // MARK: - 子控件
 private struct TypeBadge: View {
     let type: String
     var body: some View {
         let isLost = (type.lowercased() == "lost")
         return Text(isLost ? "丢失" : "拾到")
             .font(.caption).bold()
             .padding(.horizontal, 10)
             .padding(.vertical, 6)
             .background(
                 Capsule().fill(isLost ? Color.red.opacity(0.12) : Color.green.opacity(0.12))
             )
             .foregroundStyle(isLost ? .red : .green)
     }
 }

 private struct Chip: View {
     let text: String
     var systemName: String? = nil
     var body: some View {
         HStack(spacing: 6) {
             if let s = systemName { Image(systemName: s).font(.caption) }
             Text(text).font(.caption)
         }
         .padding(.horizontal, 10)
         .padding(.vertical, 6)
         .background(
             Capsule().strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
         )
         .foregroundStyle(.secondary)
     }
 }

 private struct ContactButton: View {
     let contact: String
     var body: some View {
         Button {
             openContact(contact)
         } label: {
             HStack(spacing: 6) {
                 Image(systemName: contact.isPhone ? "phone.fill" : (contact.isEmail ? "envelope.fill" : "doc.on.doc"))
                 Text(contact.isPhone ? "拨打" : (contact.isEmail ? "邮件" : "复制联系方式"))
             }
             .font(.callout)
         }
         .buttonStyle(.bordered)
     }

     private func openContact(_ s: String) {
         if s.isPhone, let url = URL(string: "tel://\(s.digitsOnly)") {
             UIApplication.shared.open(url)
         } else if s.isEmail, let url = URL(string: "mailto:\(s)") {
             UIApplication.shared.open(url)
         } else {
             UIPasteboard.general.string = s
         }
     }
 }

 // MARK: - 小工具
 private extension String {
     var isPhone: Bool { !digitsOnly.isEmpty && digitsOnly.count >= 6 }
     var isEmail: Bool {
         range(of: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$", options: [.regularExpression, .caseInsensitive]) != nil
     }
     var digitsOnly: String { filter("0123456789".contains) }
 }

 
 */
