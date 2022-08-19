//
//  NewMessageView.swift
//  FirebaseChat
//
//  Created by John Pill on 18/08/2022.
//

import SwiftUI
import Firebase
import FirebaseAuth
import SDWebImageSwiftUI

class CreateNewMessageViewModel: ObservableObject {
    
    @Published var users = [ChatUser]()
    @Published var errorMessage = ""
    
    init() {
        fetchAllUsers()
        }
    
    private func fetchAllUsers() {
        Firestore.firestore().collection("users").getDocuments {
            documentsSnapshot, error in
            if let error = error {
                self.errorMessage = "Failed to fetch users: \(error)"
                return
            }
            
            documentsSnapshot?.documents.forEach({ snapshot in
                let data = snapshot.data()
                self.users.append(.init(data: data))
                
            })
        }
        
        
    }
}

struct CreateNewMessageView: View {
    
    let didSelectNewUser: (ChatUser) -> ()
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var vm = CreateNewMessageViewModel()
    
    var body: some View {
        NavigationView{
            ScrollView{
                Text(vm.errorMessage)
                
                ForEach(vm.users) { user in
                    
                    Button {
                        // SELECT A USER TO MESSAGE
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(user)
                        
                    } label: {

                        HStack {
                            // Profile Image
                            WebImage(url: URL(string: user.profileImage))
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(50)
                                .overlay(RoundedRectangle(cornerRadius: 50).stroke(Color(.label), lineWidth: 2))
                                .shadow(radius: 5)
                            Text(user.email)        // Profile name.
                            Spacer()
                        }
                        .padding(.horizontal)
                        Divider()
                    }
                    
                }
            }.navigationTitle("New Message")
                // CREATE CANCEL / DISMISS BUTTON
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Cancel")
                        }
                    }
                }
        }
    }
}

struct CreateNewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewMessageView(didSelectNewUser: { user in
            print(user.email)
        })
    }
}
