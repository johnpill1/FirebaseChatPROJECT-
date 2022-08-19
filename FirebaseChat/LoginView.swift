//
//  ContentView.swift
//  FirebaseChat
//
//  Created by John Pill on 10/08/2022.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State private var isLogInMode = false
    @State private var email = ""
    @State private var password = ""
    
    @State private var shouldShowImagePicker = false
    @State private var image: UIImage?
    
//    init() {
//        if FirebaseApp.app() == nil { FirebaseApp.configure()
//        }
//    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                
                VStack(spacing: 16) {
                    Picker(selection: $isLogInMode, label: Text("Picker here")) {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }.pickerStyle(SegmentedPickerStyle())
                        .padding()
                    
                    if !isLogInMode {
                        Button {
                            shouldShowImagePicker.toggle()
                            
                        } label: {
                            VStack {
                                if let image = self.image {    //If the image has been picked.
                                    Image(uiImage: image)
                                        .resizable()
                                        .frame(width: 128, height: 128)
                                        .scaledToFill()
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .foregroundColor(Color(.label))
                                        .padding()
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64)
                                .stroke(Color.black, lineWidth: 3))
                            
                           
                        }
                    }
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(.white)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(.white)
                    
                    Button {
                        // LOGIN / CREATE ACCOUNT FUNCTION
                        handleAction()
                        
                        
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLogInMode ? "Log in" : "Create Account")
                                .foregroundColor(.white)
                                .padding()
                                .font(.system(size: 18, weight: .semibold))
                            Spacer()
                        }.background(Color.blue)
                    }
                    Text(self.loginStatusMessage).foregroundColor(.red)
                }
                .padding()
                
            }
            .navigationTitle(isLogInMode ? "Log in" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05))
                            .ignoresSafeArea())
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
    }
    
    
    private func handleAction() {
        if isLogInMode {
            print("Login to Firebase")
            loginUser()
        } else {
            print("Create an account in Firebase")
            createNewAccount()
        }
    }
    
    @State var loginStatusMessage = ""
    
    
    private func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) {
            result, err in
            
            if let err = err {
                print("Failed to login user:", err)
                self.loginStatusMessage = "Failed to login user: \(err)"
                return
            }
            
            print("Successefully logged in user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Successfully logged in user: \(result?.user.uid ?? "")"
            
            self.didCompleteLoginProcess()
            
        }
    }
    
    
    
    
    private func createNewAccount() {
        
        if self.image == nil {
            self.loginStatusMessage = "You must select an avatar image!"
        }
        
        Auth.auth().createUser(withEmail: email, password: password) {
            result, err in
            
            if let err = err {
                print("Failed to create user:", err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            
            print("Successefully creates user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = ("Successfully created user: \(result?.user.uid ?? "")")
         
            self.persistImageToStorage()
          
            }
            
        }
    
    
    
    private func persistImageToStorage() {
       // let filename = UUID().uuidString
        guard let uid = Auth.auth().currentUser?.uid
            else { return }
        let ref = Storage.storage().reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
            self.loginStatusMessage = "Failed to push image to Storage: \(err)"
            return
        
            }
            ref.downloadURL { url, err in
                        if let err = err {
                        self.loginStatusMessage = "Failed to download url: \(err)"
                            return
                        }
                self.loginStatusMessage = "Successfully stored image: \(url?.absoluteString ?? "")"
                
                guard let url = url else { return }
                self.storeUserInformation(imageProfile: url)
                
            }
        }
    }
    
    private func storeUserInformation(imageProfile: URL) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userData = ["email" : self.email, "uid": uid, "profileImage": imageProfile.absoluteString]
        Firestore.firestore().collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err)
                    self.loginStatusMessage = "\(err)"
                    return
            }
                
                self.didCompleteLoginProcess()
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: { } )
    }
}
