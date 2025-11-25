//
//  UserData.swift
//  GoSnow
//
//  Created by federico Liu on 2024/12/24.
//

import Foundation
import SwiftUI

class UserData: ObservableObject {
    @Published var userName: String? = "MOMO"
    @Published var userAvatar: Image? = nil
    @Published var avatarName: String?
}
