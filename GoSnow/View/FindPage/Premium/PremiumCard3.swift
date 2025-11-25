//
//  PremiumCard3.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/27.
//
/*
import SwiftUI
import StoreKit

struct PremiumCard3: View {
    @State private var isProcessing = false
    @State private var product: Product?
    
    let productID = "premium_150day" // 雪季会员的产品 ID

    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color("demo6"))
            .frame(width: 300, height: 230)
            .overlay(
                VStack(alignment: .leading) {
                    HStack {
                        ZStack {
                            Image(systemName: "flame")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                        }
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.3))
                        .clipShape(Circle())
                        
                        Spacer()
                    }

                    Spacer()
                    Text("雪季会员")
                        .font(.title3)
                        .fontWeight(.bold)

                    Spacer()
                    
                    if let product = product {
                        Text("¥\(product.displayPrice)")
                    } else {
                        Text("加载中...")
                    }
                    
                    Text("六月会员权益≈三分之一张雪票")
                        .font(.caption)
                        .fontWeight(.light)

                    Spacer()

                    Button {
                        purchaseProduct() // 触发购买流程
                    } label: {
                        Text(isProcessing ? "处理中..." : "立即加入")
                            .foregroundColor(.white)
                            .padding()
                            .padding(.horizontal, 80)
                            .background(Color("demo3"))
                            .cornerRadius(10)
                    }
                    .disabled(isProcessing || product == nil)
                }
                .frame(width: 260, height: 200)
            )
            .task {
                await fetchProduct() // 在视图加载时获取产品信息
            }
    }

    private func fetchProduct() async {
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }

    private func purchaseProduct() {
        guard let product = product else { return }
        isProcessing = true
        
        Task {
            do {
                let result = try await product.purchase()
                switch result {
                case .success(let verificationResult):
                    switch verificationResult {
                    case .verified(let transaction):
                        print("Purchase successful: \(transaction)")
                        // 在这里可以添加用户购买成功后的处理逻辑
                    case .unverified(let transaction, let error):
                        print("Purchase unverified: \(error)")
                    }
                case .userCancelled:
                    print("User cancelled the purchase")
                case .pending:
                    print("Purchase pending")
                @unknown default:
                    print("Unknown purchase result")
                }
            } catch {
                print("Purchase failed: \(error)")
            }
            isProcessing = false
        }
    }
}



#Preview {
    PremiumCard3()
}
*/
