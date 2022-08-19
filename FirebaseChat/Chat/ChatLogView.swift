//
//  ChatLogView.swift
//  LBTASwiftUIFirebaseChat
//
//  Created by Brian Voong on 11/18/21.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct FirebaseConstrants {
    static let fromID = "fromID"
    static let toID = "toID"
    static let text = "text"
}

struct ChatMessage: Identifiable {
    var id: String { documentId }
    let documentId: String
    let fromID, toID, text: String
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.fromID = data[FirebaseConstrants.fromID] as? String ?? ""
        self.toID = data[FirebaseConstrants.toID] as? String ?? ""
        self.text = data[FirebaseConstrants.text] as? String ?? ""
    }
}

class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    
    @Published var chatMessages = [ChatMessage]()
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchMessages()
        
    }
    
    private func fetchMessages() {
        guard let fromID = Auth.auth().currentUser?.uid else { return }
        
        guard let toID = chatUser?.uid else { return }
        
        Firestore.firestore().collection("messages")
            .document(fromID)
            .collection(toID)
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
            if let error = error {
                self.errorMessage = "Failed to listen for messages \(error)"
                return
            }
            
            querySnapshot?.documentChanges.forEach({ change in
                if change.type == .added {
                    let data = change.document.data()
                    self.chatMessages.append(.init(documentId: change.document.documentID, data: data))
                }
            })
            
//            querySnapshot?.documents.forEach({ queryDocumentSnapshot in
//                let data = queryDocumentSnapshot.data()
//                let docId = queryDocumentSnapshot.documentID
//                // let chatMessage = ChatMessage(data: data)
//                self.chatMessages.append(.init(documentId: docId, data: data))
//            })
        }
    }
    
    
    func handleSend() {
        print(chatText)
        guard let fromID = Auth.auth().currentUser?.uid else { return }
        
        guard let toID = chatUser?.uid else { return }
        
        let document = Firestore.firestore()
            .collection("messages")
            .document(fromID)
            .collection(toID)
            .document()
            
        
        let messageData = [FirebaseConstrants.fromID: fromID, FirebaseConstrants.toID: toID, FirebaseConstrants.text: self.chatText, "timestamp": Timestamp()] as [String : Any]
        
        document.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message to firestore \(error)"
                
            }
            self.chatText = ""
        }
        
        
        let recipientMessageDocument = Firestore.firestore().collection("messages")
            .document(toID)
            .collection(fromID)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message to firestore \(error)"
                
            }
        }
        
    }
    
}



struct ChatLogView: View {
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    @ObservedObject var vm: ChatLogViewModel
    
    var body: some View {
        ZStack {
            messagesView
            Text(vm.errorMessage)
            VStack(spacing: 0) {
                Spacer()
                chatBottomBar
                    .background(Color.white.ignoresSafeArea())
            }
        }
        .navigationTitle(chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var messagesView: some View {
        ScrollView {
            ForEach(vm.chatMessages) { message in
                VStack {
                    if message.fromID == Auth.auth().currentUser?.uid {
                        HStack {
                            Spacer()
                            HStack {
                                Text(message.text)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    } else {
                        HStack {
                            HStack {
                                Text(message.text)
                                    .foregroundColor(Color(.label))
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            
              
            }
            
            HStack{ Spacer() }
                .frame(height: 50)
        }
        .background(Color(.init(white: 0.95, alpha: 1)))
        
    }
    
    
    
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            ZStack {
                DescriptionPlaceholder()
                TextEditor(text: $vm.chatText)
                    .opacity(vm.chatText.isEmpty ? 0.5 : 1)
            }
            .frame(height: 40)
            
            Button {
                // SEND TEXT BUTTON ACTION
                vm.handleSend()
                
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(4)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

private struct DescriptionPlaceholder: View {
    var body: some View {
        HStack {
            Text("Description")
                .foregroundColor(Color(.gray))
                .font(.system(size: 17))
                .padding(.leading, 5)
                .padding(.top, -4)
            Spacer()
        }
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatLogView(chatUser: .init(data: ["uid": "flGH1I0s8wVs7nt40M1SDblWmxg1", "email": "testing123@gmail.com"]))
        }
    }
}
