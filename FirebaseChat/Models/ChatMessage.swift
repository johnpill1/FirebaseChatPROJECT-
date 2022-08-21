//
//  ChatMessage.swift
//  FirebaseChat
//
//  Created by John Pill on 21/08/2022.
//

import Foundation
import Firebase


struct ChatMessage: Identifiable {
    var id: String { documentId }
    let documentId: String
    let fromID, toID, text: String
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.fromID = data[FirebaseConstants.fromID] as? String ?? ""
        self.toID = data[FirebaseConstants.toID] as? String ?? ""
        self.text = data[FirebaseConstants.text] as? String ?? ""
    }
    
 
}
