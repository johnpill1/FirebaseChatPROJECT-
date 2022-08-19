//
//  FirebaseChatApp.swift
//  FirebaseChat
//
//  Created by John Pill on 10/08/2022.
//

import SwiftUI
import Firebase

@main
struct FirebaseChatApp: App {
    
    init() {
        if FirebaseApp.app() == nil { FirebaseApp.configure()
        }
    }

    
    var body: some Scene {
        WindowGroup {
            MainMessagesView()
        }
    }
}
