//
//  RecentMessage.swift
//  FirebaseChat
//
//  Created by John Pill on 21/08/2022.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift


struct RecentMessage: Codable, Identifiable {
    let text, fromID, toID: String
    let timestamp: Date
  //  let documentId: String
    let email, profileImage: String
   // var id: String { documentId }
    
    @DocumentID var id: String?
    
//    init(documentId: String, data: [String: Any]) {
//        self.documentId = documentId
//        self.text = data["text"] as? String ?? ""
//        self.fromID = data["fromID"] as? String ?? ""
//        self.toID = data["toID"] as? String ?? ""
//        self.email = data["email"] as? String ?? ""
//        self.profileImage = data["profileImage"] as? String ?? ""
//        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
//    }
    
    var username: String {
        email.components(separatedBy: "@").first ?? email
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
}
