//
//  CommunityTerms.swift
//  GoSnow
//
//  Created by federico Liu on 2024/12/17.
//

import SwiftUI

struct CommunityGuidelinesView: View {
    var body: some View {
        ScrollView { // 为了内容超出屏幕时可以滚动
            VStack(alignment: .leading, spacing: 10) { // 使用 VStack 垂直排列，设置间距
                Text("社区准则")
                    .font(.title) // 设置标题字体
                    .fontWeight(.bold) // 加粗标题

                Text("欢迎加入我们的社区！为了确保每位用户都能在一个安全、友好、互助的环境中交流，我们制定了以下社区准则。这些准则旨在保护每个人的权益，营造一个和谐的社区氛围。我们期望所有用户都能遵守这些准则，共同维护社区的良好秩序。")
                    .fixedSize(horizontal: false, vertical: true) // 允许文本换行

                guidelineSection(title: "1. 尊重他人", content: "请始终尊重其他用户，尊重他们的观点、背景和身份。\n禁止发布任何形式的歧视、侮辱、威胁、骚扰或恶意攻击的内容。\n在讨论中保持开放心态，尊重不同的意见和视角。")

                guidelineSection(title: "2. 禁止发布不当内容", content: "禁止发布任何违法、淫秽、暴力、恶心或令人不适的内容。\n禁止传播虚假信息、恶搞、恶意谣言或误导性内容。\n禁止侵犯他人隐私或知识产权的内容，包括但不限于盗用他人图片、文字、视频等。")

                guidelineSection(title: "3. 尊重社区环境", content: "请尽量避免发布与社区主题无关的内容，确保讨论的主题与本社区的核心目的保持一致。\n禁止广告、垃圾信息或无关的自我宣传。无论是产品、服务还是个人推广，都不应发布于讨论帖内。\n发布内容前请检查，避免重复发布相同或相似的帖子。")

                guidelineSection(title: "4. 诚实与透明", content: "请确保所发布的内容真实可信，特别是涉及到事实陈述或他人时，避免误导或夸大事实。\n在发布敏感信息或个人观点时，请清楚标注为个人观点，避免误导他人。")

                guidelineSection(title: "5. 保护个人隐私", content: "请避免公开分享个人敏感信息，如身份证号码、银行账号、密码等。\n在发布图片、视频或其他个人信息时，请确保不会侵犯他人的隐私权。")

                guidelineSection(title: "6. 禁止恶意行为", content: "禁止使用任何形式的恶意软件、病毒、木马、钓鱼链接等危害其他用户或平台安全的行为。\n禁止进行刷赞、刷评论等违反公平原则的行为。")

                guidelineSection(title: "7. 举报与反馈", content: "如果你发现有违反社区准则的行为，欢迎及时举报。平台将对举报内容进行审核，合理的举报会得到及时处理。\n欢迎你提供关于平台或社区的建设性意见与反馈，帮助我们共同提升社区的质量。")

                guidelineSection(title: "8. 处罚措施", content: "对于严重违反社区准则的行为，平台有权采取删除帖子、禁言、封号等处罚措施。\n我们将根据违规的严重性、频繁程度及对其他用户的影响进行评估，作出相应的处理。")

                guidelineSection(title: "9. 规则更新", content: "社区准则会根据需要进行更新和调整，用户应定期查看更新内容。\n更新后的准则将在平台内公示，并即时生效。")
            }
            .padding() // 添加内边距
        }
    }

    func guidelineSection(title: String, content: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline) // 设置小标题字体
                .padding(.bottom, 5) // 小标题底部添加间距
            Text(content)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct CommunityGuidelinesView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityGuidelinesView()
    }
}
