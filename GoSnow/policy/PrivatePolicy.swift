//
//  PrivatePolicy.swift
//  GoSnow
//
//  Created by federico Liu on 2024/11/19.
//

import SwiftUI

struct TermsView: View {
    // 配置
    private let appName = "上雪"
    private let supportEmail = "gosnow.serviceteam@gmail.com"
    private let lastUpdated = "2025-10-17"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // 标题与更新日期
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(appName) 服务条款与隐私摘要")
                            .font(.title2.bold())
                        Text("最后更新：\(lastUpdated)")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }

                    // 提示
                    Text("请在使用本应用前仔细阅读。本页面为要点摘要，完整条款与隐私政策以我们在应用内或官方网站公布的正式版本为准。继续使用即表示你同意这些条款及其后续修订。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // 一、适用范围与变更
                    Card {
                        SectionHeader(title: "一、适用范围与变更")
                        Bullet("本条款约束你对 \(appName) 应用及相关服务（“服务”）的访问与使用。")
                        Bullet("我们可能不时更新条款与隐私政策；更新后在应用内生效并替代旧版本。")
                        Bullet("我们可在不通知的情况下改进或变更产品与功能，或临时/永久地变更、暂停或终止服务的全部或部分。")
                    }

                    // 二、账户与安全
                    Card {
                        SectionHeader(title: "二、账户与安全")
                        Bullet("你负责妥善保管账户与密码，并对账户下的所有活动负责。")
                        Bullet("我们采取合理安全措施，但无法保证绝对安全。若发现未授权使用或安全问题，请立即联系我们。")
                        Bullet("13 岁以下儿童不应使用本应用。")
                    }

                    // 三、可接受的使用（AUP）
                    Card {
                        SectionHeader(title: "三、可接受的使用（AUP）")
                        Bullet("不得上传或传播违法、侵权、辱骂、仇恨、低俗或其他令人反感的内容。")
                        Bullet("不得冒充他人、散布垃圾信息/广告、上传恶意代码、破坏/干扰服务或网络。")
                        Bullet("不得以自动化方式（脚本、爬虫、机器人等）未经授权访问服务。")
                        Bullet("不得违反适用的法律法规及第三方平台规则。")
                        Bullet("如违反 AUP，\(appName) 可采取包括限制/终止账户在内的措施。")
                    }

                    // 四、用户内容与授权
                    Card {
                        SectionHeader(title: "四、用户内容与授权")
                        Bullet("你对自己上传/发布的内容承担全部责任。")
                        Bullet("你授予 \(appName) 全球范围、不可撤销、免版税的许可，以为提供与推广服务之目的而使用、复制、修改、展示、分发该等内容（在法律允许范围内）。")
                        Bullet("地图、徽标及第三方受版权保护的信息归其权利人所有；应权利人要求，我们可删除相关内容。")
                        Bullet("应用内的度假村/场地信息仅供参考，你应自行核验。")
                    }

                    // 五、软件与知识产权
                    Card {
                        SectionHeader(title: "五、软件与知识产权")
                        Bullet("服务及其中的软件与内容受知识产权保护。除法律允许外，不得对其进行复制、修改、反向工程或衍生利用。")
                        Bullet("\(appName) 授予你个人、不可转让、非独占的访问与使用许可；不得通过非官方接口访问服务。")
                        Bullet("我们保留本协议未明确授予的全部权利。")
                    }

                    // 六、隐私摘要
                    Card {
                        SectionHeader(title: "六、隐私摘要")
                        Bullet("我们依据隐私政策收集与处理必要信息（如账户信息、设备与使用数据）。")
                        Bullet("在符合法律的前提下，我们可能为合规、保障安全、履行合同、客服支持等目的访问、保存或披露必要信息。")
                        Bullet("完整内容请查看《隐私政策》正式文本。")
                    }

                    // 七、免责声明与责任限制
                    Card {
                        SectionHeader(title: "七、免责声明与责任限制")
                        Bullet("服务按“现状/可用”提供，我们不对其满足你的特定需求、不间断、无错误或结果完全准确作出保证。")
                        Bullet("在法律允许范围内，我们不对因使用或无法使用服务而导致的任何直接或间接损失承担责任。")
                    }

                    // 八、医疗免责声明（如适用）
                    Card {
                        SectionHeader(title: "八、医疗免责声明（如适用）")
                        Bullet("\(appName) 不提供医疗建议，应用内内容不能替代专业医疗指导。若有健康问题请咨询专业医生；紧急情况请拨打当地急救电话。")
                    }

                    // 九、终止
                    Card {
                        SectionHeader(title: "九、终止")
                        Bullet("在以下情形下，我们可在不事先通知的情况下立即终止或限制你对服务的访问：违反本条款、执法/监管要求、长时间不活跃、技术/安全问题、欠费等。")
                        Bullet("终止后可能删除与账户相关的信息并限制再次使用服务。")
                    }

                    // 十、沟通与电子通知
                    Card {
                        SectionHeader(title: "十、沟通与电子通知")
                        Bullet("你同意我们以电子方式向你提供通知、披露与其他通信，并视为满足书面形式要求。")
                        Bullet("应用内的论坛/群聊等属公开交流环境，请谨慎发布内容。")
                    }

                    // 十一、第三方设备与材料
                    Card {
                        SectionHeader(title: "十一、第三方设备与材料")
                        Bullet("使用服务可能需要第三方设备或材料。我们不对第三方设备/材料的兼容性、可用性或无错误性作保证。")
                    }

                    // 十二、支持与联系
                    Card {
                        SectionHeader(title: "十二、支持与联系")
                        Bullet("我们通过电子邮件提供支持：")
                        Link(supportEmail, destination: URL(string: "mailto:\(supportEmail)")!)
                            .font(.subheadline.weight(.semibold))
                    }

                    // 结尾提示
                    Text("如你不同意上述条款，请停止使用本应用。继续使用即表示你同意本条款及其后续修订。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                }
                .padding(20)
                .textSelection(.enabled)
            }
            .navigationTitle("服务条款与隐私")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 简洁的样式组件
private struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}


private struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.medium)
            }
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.bottom, 4)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct Bullet: View {
    let text: String
    init(_ t: String) { self.text = t }
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").font(.headline).padding(.top, 1)
            Text(text).font(.subheadline)
        }
        .foregroundStyle(.primary)
    }
}

#Preview {
    TermsView()
        .preferredColorScheme(.light)
}

