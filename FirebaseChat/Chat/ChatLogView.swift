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

struct FirebaseConstants {
    static let fromID = "fromID"
    static let toID = "toID"
    static let text = "text"
    static let email = "email"
    static let profileImage = "profileImage"
}



class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var count = 0
    
    @Published var chatMessages = [ChatMessage]()
    
    var chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchMessages()
        
    }
    
    var firestoreListener: ListenerRegistration?
    
    
    func fetchMessages() {
        guard let fromID = Auth.auth().currentUser?.uid else { return }
        
        guard let toID = chatUser?.uid else { return }
        chatMessages.removeAll()
        firestoreListener = Firestore.firestore().collection("messages")
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
                
                DispatchQueue.main.async {
                    self.count += 1
                }
                
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
        
        
        let messageData = [FirebaseConstants.fromID: fromID, FirebaseConstants.toID: toID, FirebaseConstants.text: self.chatText, "timestamp": Timestamp()] as [String : Any]
        
        document.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message to firestore \(error)"
                
            }
            
            self.persistRecentMessage()
            
            self.chatText = ""  // Clear the chat text box.
            self.count += 1 // To trigger autoscroll.
        
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
    
    private func persistRecentMessage() {
        guard let chatUser = chatUser else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        
        let document = Firestore.firestore()
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        
        let data = [
            "timestamp": Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromID: uid,
            FirebaseConstants.toID: toId,
            FirebaseConstants.profileImage: chatUser.profileImage,
            FirebaseConstants.email: chatUser.email
        ] as [String : Any]
        
        
        
        document.setData(data) { error in
            if let error = error {
                self.errorMessage = "Failed to save recent message: \(error)"
                return
            }
        }
        
        
    }
  
}



struct ChatLogView: View {
    
//    let chatUser: ChatUser?
//
//    init(chatUser: ChatUser?) {
//        self.chatUser = chatUser
//        self.vm = .init(chatUser: chatUser)
//    }
    
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
        .navigationTitle(vm.chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            vm.firestoreListener?.remove()
        }
    }
    
    static let emptyScrollToString = "Empty"
    
    private var messagesView: some View {
        ScrollView {
            ScrollViewReader { scrollViewProxy in // using to autoscroll.
                
                VStack {
                    ForEach(vm.chatMessages) { message in
                        
                        MessageView(message: message)
                        
                    }
                    HStack{ Spacer() }
                        .id(Self.emptyScrollToString)
                        .frame(height: 65)  // Need to bump the bottom of the messages above the send area.
                    
                }
                .onReceive(vm.$count) { _ in
                    withAnimation(.easeOut(duration: 0.5)) {
                        scrollViewProxy.scrollTo("Empty", anchor: .bottom)
                        
                    }
                }
            }
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

struct MessageView:  View {
    
    let message: ChatMessage
    
    var body: some View {
        
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
       
            
            //ChatLogView(chatUser: .init(data: ["uid": "flGH1I0s8wVs7nt40M1SDblWmxg1", "email": "testing123@gmail.com"]))
            MainMessagesView()
        
    }
}
