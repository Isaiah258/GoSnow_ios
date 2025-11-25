//
//  GuideBookView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/7/6.
//

import SwiftUI


struct GuideBookView: View {
    @State private var selectedQuestionDetail: QuestionDetail? // 选中的问题详情
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // 标题
                Text("新手常见问题")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 横向滚动的卡片
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(questions) { question in
                            QuestionCardView(question: question)
                                .frame(width: 200, height: 260)
                                .onTapGesture {
                                    selectedQuestionDetail = QuestionDetail(
                                        question: question.title,
                                        answer: question.description.joined(separator: "\n\n"), // 将多段文字拼接
                                        image: question.image
                                    )
                                }
                        }
                    }
                    .padding(.horizontal)
                }

                // "开始学习滑雪"
                Text("开始学习滑雪")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack {
                    Text("将在未来更新 :)")
                        .font(.body)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 雪场及旅行攻略
                Text("雪场及旅行攻略")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack {
                    Text("将在未来更新 :)")
                        .font(.body)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 联系我们
                Text("联系我们")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack {
                    Text("修补指南请前往微信服务号：雪兔滑行")
                        .font(.body)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.top)
        }
        .navigationTitle("指南书")
        .sheet(item: $selectedQuestionDetail) { detail in
            QuestionDetailView(question: detail.question, answer: detail.answer, image: detail.image)
        }
    }
}

struct GuideBookView_Previews: PreviewProvider {
    static var previews: some View {
        GuideBookView()
    }
}

struct QuestionDetail: Identifiable {
    var id = UUID()
    var question: String
    var answer: String
    var image: String
}

struct QuestionCardView: View {
    let question: Question

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(question.image)  // 动态使用传入的图片
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 180, height: 180)
            
            CardText
                .padding(.horizontal)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 5)
    }
    
    var CardText: some View {
        VStack {
            Text(question.title)
                .font(.body)
                .foregroundStyle(Color.black)
        }
        .foregroundStyle(Color.gray)
        .padding(.bottom, 16)
    }
}

struct Question: Identifiable {
    let id = UUID()
    let title: String
    let description: [String] // 支持多段文字
    let image: String
}

// 问题数组
let questions: [Question] = [
    Question(
        title: "如何“经济”滑雪",
        description: [
            """
            很多人一听到“滑雪”两个字，脑海里立刻浮现出昂贵的装备、遥远的雪场和高昂的教练费。但其实，滑雪并没有你想象中那么遥不可及。它就像一个性格多变的朋友，既可以陪你奢侈一把，也能陪你精打细算。所以，滑雪是一个丰俭由人、可宽裕可经济的运动，而非“贵族”运动。

            ## 1. 装备：与你同行

            在你没有确认自己是否真的热爱滑雪或还没有入门时，不需要在一开始便花费重金买全装备，否则很可能日后会吃灰然后流入闲鱼市场。刚开始作为体验滑雪的游客，你完全可以通过租赁雪场的装备进行体验（小雪场的雪鞋确实会有一些味道，带一个塑料袋套脚上是个不错的选择）。

            根据渐进式入门的思想，即使你有心系统性入门滑雪，我们仍然推荐你可以暂时从必要的装备开始购买，雪鞋、雪袜、手套是能够提升幸福感的必要装备，而诸如雪镜、头盔、雪板都可以暂时租赁。

            随着你内心确认了你是如此热爱滑雪，你就可以挑选你喜欢的其他装备了，但作为新手，你其实不需要太过于纠结品牌、参数等，普通的入门雪板就是最好的。淡季折扣、闲鱼二手市场是最经济的选择。

            不必担心，随着你技术的进步，你的装备会随着你的需求慢慢迭代。

            ## 2. 雪场：从“家门口”开始

            家乡本地的小雪场是入门的绝佳选择，相对低廉的票价可以让你无压力地入门，室内雪场也是个好的选择。而对于外滑，也并不是想象中的那么贵：

            1. **交通**：中国的滑雪地区主要集中在河北崇礼、北京、东北和新疆，如果你想省钱且刚好在周围，那么跟伙伴拼车自驾是最方便经济的，以山东地区为例，四人前往崇礼的路费人均在300元上下。

            2. **雪票与住宿**：如果你是学生，请关注雪场的学生优惠政策，比如万龙的免费雪票、翠云山的学生住滑套餐等，这将使你的外滑成本大幅下降，享受你的学生身份吧。  
            同样，滑雪者也可以通过雪季前的早鸟票与关注住滑套餐等方式以相对便宜的金额进行外滑。住宿不代表高昂的雪场酒店，除了更便宜的县城酒店，追求低廉的，县城的两人一A房费50元的挂壁旅馆也是极好的，毕竟滑雪才是主要的，其他的要啥自行车呢？

            3. **学习**：请享受自学的乐趣：尽管请一个教练会有事半功倍的效果（尤其是在进阶的技术上），但对于初学者，我们并不想无脑建议你请一个教练。在短视频与长视频均无比丰富的今天，网络上有许许多多的滑雪教程，其中不泛有知名的“桃李满天下”的赛博导师，在做足功课的基础上，自学是一件有挑战有乐趣不断产生心得的过程。对于初学者，也能显著降低你的滑雪成本。

            

            ## 3.总结

            滑雪是一个丰俭由人的运动，对于经济的做法，如果你是一个学生，你甚至可以做到在万龙滑一周的出行食宿游玩费用只花1000出头的成本。所以，如果你喜欢这个运动，不要被网络评论等刻板印象误导，尽管去做就好了。

            欢迎你加入期待冬天到来的滑雪人队伍，游玩和学习的过程中，请务必重视安全和雪道规则，对他人负责，对自己负责。
            """
        ],
        image: "question_purple"
    ),
    Question(
        title: "滑雪名词速览",
        description: [
            """
            ### 基础术语

            1. 雪道
                
                指滑雪场内的滑行区域，通常根据难度分为不同等级，如初级道、中级道和高级道(对应绿道、蓝道和黑道)。
                
            2. 雪质
                
                机压雪道：经过压雪机平整处理的雪道，适合初学者和中级滑雪者。粉雪：
            松软、干燥的雪，滑行时感觉轻盈，深受高级滑雪者喜爱。冰面：雪道表面结冰，滑行时摩擦力减小，难度增加。湿雪：
            温度较高时形成的雪，质地较重，滑行时阻力较大。
                
            3. 野雪
                
                未经压雪机处理的自然雪地，通常地形复杂，适合高级滑雪者。
                
            4. 缆车
                
                滑雪场用于将滑雪者运送到山顶的交通工具，常见的有吊椅缆车和吊箱缆车
                
            5. 魔毯
                
                一种类似于传送带的设备，通常用于初级雪道，帮助新手轻松到达坡顶。
            6. 前刃
                
                单板滑雪中，脚尖一侧的板刃，用于控制方向和刹车。

            7. 后刃
            
                单板滑雪中，脚跟一侧的板刃，同样用于控制方向和刹车。
            8. 内刃
                
                双板转弯时靠近身体内侧的板刃。

            9. 外刃
            
                双板转弯时远离身体外侧的板刃。
            
            ### 技术术语
            1. 犁式刹车
            
                双板滑雪的初级刹车技术，用于减速或停止。

            2. 平行转弯
            
                双板滑雪的中级技术，两板保持平行，通过重心转移完成转弯。

            3. 刻滑（卡宾）
            
                一种高级滑行技术，利用雪板边缘切入雪面，形成流畅的弧线滑行。

            4. 换刃
            
                单板滑雪中，从前刃切换到后刃或反之的动作，是滑行和转弯的基础。
            
            5. 回转
            
                小回转：双板的一种快速、连续的转弯技术，适合陡坡或狭窄雪道。
                大回转：幅度较大的转弯技术，适合宽阔雪道或高速滑行。
            6. 反弓
            
                滑雪时通过膝盖和髋部的弯曲，形成身体与雪板之间的角度，以增强对雪板的控制。

            7. 引身
            
                在转弯前通过轻微起身释放雪板压力，帮助更轻松地完成转弯。

            8. 压身
            
                在转弯时通过下压身体增加雪板压力，以提高抓地力和控制力。
            
            """
        ],
        image: "question_blue"
    ),
    Question(
        title: "学习滑雪前要知道的",
        description: [
            "待补充"
        ],
        image: "question_yellow"
    ),
    Question(
        title: "选择单板还是双板？",
        description: [
            """
            ## 入门
              双板是大多数新手的第一选择。它的最大优势在于入门简单。双板滑雪的站立姿势与日常行走类似，这种姿势让人感到自然且容易保持平衡。初学者可以在第一次滑雪时就能体验到从雪道上滑下的乐趣。
            如果你是初次体验滑雪的乐趣，或者带着家人恋人一起滑雪，双板滑雪可能是更好的选择。它入门简单，安全性高，能让你在短时间内享受到滑雪的快乐。（注意：双板由于容易起速，难在控制，新手应严肃重视安全。）

            而单板滑雪的入门难度较高。由于双脚固定在一块雪板上，初学者在初期很难掌握平衡，容易频繁摔倒。对于身体素质较差或平衡感不佳的人来说，单板滑雪的学习曲线可能会比较陡峭，滑雪体验可能会不佳。


            ## 进阶

            尽管双板上手比较简单，但双板滑雪的进阶难度较高，比如平行转弯和 carving（刻滑），需要投入更多的时间和精力。双板更能适应复杂的地形和兼容更广泛的雪场，且对年龄和身体素质的要求较低，适合大多数人。

            单板滑雪的进阶速度较快，掌握了基本的平衡和转向技巧后，滑雪者可以较快地提升水平，甚至尝试一些简单的花式动作。


            单双板是可以转换的，而不是单选题。多观看视频找到你喜欢的风格，最重要的是找到你感兴趣的，个人兴趣才是最好的导师。

            滑雪是一项充满乐趣的运动，选择适合自己的方式，才能更好地享受雪上的自由与激情。希望这篇文章能帮助你做出明智的选择，开启你的滑雪之旅！
            """

        ],
        image: "question_cyan"
    )
    
]









/*
 
 双板是大多数新手的第一选择。它的最大优势在于入门简单。双板滑雪的站立姿势与日常行走类似，这种姿势让人感到自然且容易保持平衡。初学者可以在第一次滑雪时就能体验到从雪道上滑下的乐趣。
如果你是初次体验滑雪的乐趣，或者带着家人恋人一起滑雪，双板滑雪可能是更好的选择。它入门简单，安全性高，能让你在短时间内享受到滑雪的快乐。（注意：双板由于容易起速，难在控制，新手应严肃重视安全。）

而单板滑雪的入门难度较高。由于双脚固定在一块雪板上，初学者在初期很难掌握平衡，容易频繁摔倒。对于身体素质较差或平衡感不佳的人来说，单板滑雪的学习曲线可能会比较陡峭，滑雪体验可能会不佳。


进阶

尽管双板上手比较简单，但双板滑雪的进阶难度较高，比如平行转弯和 carving（刻滑），需要投入更多的时间和精力。双板更能适应复杂的地形和兼容更广泛的雪场，且对年龄和身体素质的要求较低，适合大多数人。

单板滑雪的进阶速度较快，掌握了基本的平衡和转向技巧后，滑雪者可以较快地提升水平，甚至尝试一些简单的花式动作。


单双板是可以转换的，而不是单选题。多观看视频找到你喜欢的风格，最重要的是找到你感兴趣的，个人兴趣才是最好的导师。

滑雪是一项充满乐趣的运动，选择适合自己的方式，才能更好地享受雪上的自由与激情。希望这篇文章能帮助你做出明智的选择，开启你的滑雪之旅！
 */






