//
//  ChatUser.swift
//  LBTASwiftUIFirebaseChat
//
//  Created by Brian Voong on 11/16/21.
//

import Foundation

struct ChatUser: Identifiable {
    
    var id: String { uid }
    let uid, email, profileImage: String
    
    init(data: [String: Any]) {
        self.uid = data["uid"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.profileImage = data["profileImage"] as? String ?? ""
    }
}
