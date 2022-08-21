//
//  MainMessagesView.swift
//  FirebaseChat
//
//  Created by John Pill on 14/08/2022.
//

//                           

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import SDWebImageSwiftUI
import FirebaseFirestoreSwift



class MainMessagesViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var recentMessages = [RecentMessage]()
    
    init() {
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = Auth.auth().currentUser?.uid == nil
        }
        fetchCurrentUser()
        
        fetchRecentMessages()
        
    }
    
    private var firestoreListener: ListenerRegistration?
    
    func fetchRecentMessages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        firestoreListener?.remove()
        self.recentMessages.removeAll()
        
        firestoreListener = Firestore.firestore()
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for recent messages: \(error)"
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    let docId = change.document.documentID
                    
                    if let index = self.recentMessages.firstIndex(where: { rm in
                        return rm.id == docId
                    }) {
                        self.recentMessages.remove(at: index)
                        
                    }
                    
                    if let rm = try? change.document.data(as: RecentMessage.self) {
                        self.recentMessages.insert(rm, at: 0)
                    }
                    // self.recentMessages.insert(.init(documentId: docId, data: change.document.data()), at: 0)
                    
                })
            }
    }
    
    
    func fetchCurrentUser() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Could not find firebase uid"
            return
            
        }
        
        
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = "Failed to fetch current user: \(error)"
                return
            }
            
            self.chatUser = try? snapshot?.data(as: ChatUser.self)
            self.chatUser = self.chatUser
        }
    }
    
    @Published var isUserCurrentlyLoggedOut = false
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? Auth.auth().signOut()
        
    }
}

struct MainMessagesView: View {
    
    @State var shouldShowLogOutOption = false
    @State var shouldNavigateToChatLogView = false
    
    @ObservedObject private var vm = MainMessagesViewModel()
    
    private var chatLogViewModel = ChatLogViewModel(chatUser: nil)
    
    var body: some View {
        NavigationView {
            
            // NAV BAR
            VStack {
                
                customeNavBar
                messageView
                
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatLogView(vm: chatLogViewModel)
                }
            }
            .overlay(
                newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
    
    
    
    
    private var customeNavBar: some View {
        HStack(spacing: 16){
            
            // Uses SDWebImageSwiftUI library from git hub.
            WebImage(url: URL(string: vm.chatUser?.profileImage ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 54, height: 54)
                .clipped()
                .cornerRadius(54)
                .overlay(RoundedRectangle(cornerRadius: 64) .stroke(Color(.label), lineWidth: 1))
                .shadow(radius: 10)
            
            
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vm.chatUser?.username ?? "")")
                    .font(.system(size: 24, weight: .bold))
                
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("online")
                        .font(.system(size: 12))
                }
            }
            Spacer()
            Button {
                shouldShowLogOutOption.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
        .background(Color(.init(red: 0, green: 0, blue: 0, alpha: 0.03)))
        .actionSheet(isPresented: $shouldShowLogOutOption) {
            .init(title: Text("Settings"), message:
                    Text("What do you want to do?"), buttons: [
                        .destructive(Text("Sign Out"), action: {
                            print("Handle sign out")
                            vm.handleSignOut()
                        }),
                        .cancel()
                    ])
        } .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, onDismiss: nil) {
            LoginView(didCompleteLoginProcess: {
                self.vm.isUserCurrentlyLoggedOut = false
                self.vm.fetchCurrentUser()
                self.vm.fetchRecentMessages()
            }) // If user Logs out - go to log in page.
        }
    }
    
    
    
    private var messageView: some View {
        ScrollView {
            ForEach(vm.recentMessages) { recentMessage in
                VStack {
                    
                    Button {
                        let uid = Auth.auth().currentUser?.uid == recentMessage.fromID ? recentMessage.toID : recentMessage.fromID
                        
                        self.chatUser = .init(id: uid, uid: uid, email: recentMessage.email, profileImage: recentMessage.profileImage)
                        
                        self.chatLogViewModel.chatUser = self.chatUser
                        self.chatLogViewModel.fetchMessages()
                        self.shouldNavigateToChatLogView.toggle()
                        
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: recentMessage.profileImage))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipped()
                                .cornerRadius(64)
                                .overlay(RoundedRectangle(cornerRadius: 64)
                                    .stroke(Color.black, lineWidth: 1))
                                .shadow(radius: 5)
                            
                            // Image(systemName: "person.fill")
                            // .font(.system(size: 32))
                            //.padding()
                            //.overlay(RoundedRectangle(cornerRadius: 44)
                            //  .stroke(Color(.label), lineWidth: 1))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recentMessage.username)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(.label))
                                Text(recentMessage.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.darkGray))
                                    .multilineTextAlignment(.leading)
                                
                            }
                            Spacer()
                            
                            // MESSAGE DATE
                            Text(recentMessage.timeAgo)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
                Divider()
                    .padding(.vertical, 8)
            } .padding(.horizontal)
            
        } .padding(.bottom, 50)
    }
    
    
    @State var shouldShowNewMessageScreen = false
    
    
    private var newMessageButton: some View {
        Button {
            // NEW MESSAGE ACTION
            shouldShowNewMessageScreen.toggle()
            
        } label: {
            HStack{
                Spacer()
                Text("+ New Message")
                Spacer()
            }
            .foregroundColor(Color.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
            
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            CreateNewMessageView(didSelectNewUser: {
                user in
                print(user.email)
                self.shouldNavigateToChatLogView.toggle()
                self.chatUser = user
                self.chatLogViewModel.chatUser = user
                self.chatLogViewModel.fetchMessages()
            })
        }
    }
    
    @State var chatUser: ChatUser?
    
}





struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
        //.preferredColorScheme(.dark)
    }
}
