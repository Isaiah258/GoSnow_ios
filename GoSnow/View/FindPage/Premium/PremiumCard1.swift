//
//  PremiumCard1.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/27.
//
/*
import SwiftUI
import StoreKit

struct PremiumCard1: View {
    @State private var isProcessing = false
    @State private var product: Product?
    
    let productID = "premium_7day" // 7日会员的产品 ID

    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color("demo2"))
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
                    Text("七日会员")
                        .font(.title3)
                        .fontWeight(.bold)

                    Spacer()
                    
                    if let product = product {
                        Text("¥\(product.displayPrice)")
                    } else {
                        Text("加载中...")
                            .onAppear(perform: loadProduct) // 加载产品信息
                    }
                    
                    Text("七日会员权益≈一包薯片")
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
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                    .disabled(isProcessing || product == nil)
                }
                .frame(width: 260, height: 200)
            )
    }

    // 加载产品信息
    private func loadProduct() {
        Task {
            do {
                let products = try await Product.products(for: [productID])
                product = products.first
            } catch {
                print("Failed to load product: \(error)")
            }
        }
    }

    // 购买产品
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
                        // 处理成功购买后的逻辑
                        print("Purchase successful: \(transaction)")
                        // 完成交易
                        await transaction.finish()
                    case .unverified(_, let error):
                        print("Purchase failed: \(error)")
                    }
                case .userCancelled:
                    print("User cancelled the purchase.")
                default:
                    print("Purchase failed with unknown result.")
                }
            } catch {
                print("Purchase failed: \(error)")
            }
            isProcessing = false
        }
    }
}



#Preview {
    PremiumCard1()
}

*/
