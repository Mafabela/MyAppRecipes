//
//  ProfileView.swift
//  MyAppRecipes
//
//  Created by Consultant on 1/22/23.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct ProfileView: View {
    @StateObject var sesionManager = SessionManager()
    // MARK: My profile Data
    @State private var myProfile: User?
    @AppStorage("log_status") var logStatus: Bool = false
    //MARK: View Properties
    @State var errorMessages: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    @State private var showingAlert = false

    var body: some View {
        NavigationStack{
            VStack{
                if let myProfile{
                  ProfileContent(user: myProfile)
                        .refreshable {
                            //MARK: Refresh User Data
                            self.myProfile = nil
                            await fetchUserData()
                        }
                }else {
                    ProgressView()
                }
            }
            
            .navigationTitle("My Profile")
            .toolbar {
                Menu {
                    //MARK: Logout and Delette
                    Button("Logout")
                    {
                        logOutUser()
                        //print("pressed button")
                    }
                    
                    Button("Delete Account", role: .destructive){
                        print("Deleting...")
                        showingAlert = true
                    }
                   
                    
                }label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.init(degrees: 90))
                        .tint(.black)
                        .scaleEffect(1.2)
                }
            }
            .alert(isPresented: $showingAlert) {
                            Alert(title: Text("Delete Account"),
                                  message: Text("There is no undo"),
                                  //dismissButton: .cancel()
                                  primaryButton: .destructive(Text("Delete")){
                                print("Borrao")
                                deleteAccount()
                            },
                                  secondaryButton: .cancel()
                            )
                        }
        }
        .overlay {
            LoadingView(show: $isLoading)
        }
        .alert(errorMessages, isPresented: $showError){
            
        }
        .task {
            //First time fetch
            if myProfile != nil {return}
            //Initial fetch
            await fetchUserData()
        }
    }
    
    //MARK: Fetching user data
    func fetchUserData()async{
        guard let userUID = Auth.auth().currentUser?.uid else {return}
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self) else {return}
        await MainActor.run(body: {
            myProfile = user
        })
        
    }
    
    func logOutUser(){
        try? Auth.auth().signOut()
        logStatus = false
    }
    
    func deleteAccount(){
        isLoading = true
        Task{
            do{
                guard let userUID =  Auth.auth().currentUser?.uid else {return}
                // 1. First Delete profile images from storage
                let reference = Storage.storage().reference().child("Profile_Images").child(userUID)
                try await reference.delete()
                // 2. Deleting Firestore User document
                try await Firestore.firestore().collection("Users").document(userUID).delete()
                // 3. Deleting Auth Account and Setting Status to false
                try await Auth.auth().currentUser?.delete()
                logStatus = false
            }catch {
                await setError(error)
            }
        }
    }
    
    //Errors
    func setError(_ error: Error)async{
        //UI must be run on Main thread
        await MainActor.run(body: {
            isLoading = false
            errorMessages = error.localizedDescription
            showError.toggle()
        })
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
        //ContentView()
    }
}
