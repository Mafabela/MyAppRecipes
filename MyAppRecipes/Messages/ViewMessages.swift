//
//  ViewMessages.swift
//  MyAppRecipes
//
//  Created by Consultant on 1/28/23.
//

import SwiftUI
import Firebase


struct ViewMessages: View {
    var user: User
    @State private var myProfile: User?
    @State var shouldShowLogOutOptions = false
    
    @ObservedObject private var vm = MainMessagesViewModel()
    
    var body: some View {
        NavigationView {
            
            VStack{
                
                customNavBar
                contenMessagesView
            }
            .overlay(
                newMessageButton,
                alignment: .bottom
            )
            .navigationBarHidden(true)
            //.navigationTitle("Messages View")
        }
        
    }
    private var customNavBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.fill")
                .font(.system(size: 34, weight: .heavy))
            VStack(alignment: .leading, spacing: 4){
                Text(user.username)
                    .font(.system(size: 24, weight: .bold))
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 10, height: 10)
                    Text("online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
                
            }
            Spacer()
            Button{
                shouldShowLogOutOptions.toggle()
            }label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
        .actionSheet(isPresented: $shouldShowLogOutOptions) {
            .init(title: Text("Settings"),
                  message: Text("What do you want to do?"),
                  buttons: [
                    .destructive(Text("Sign Out"), action: {
                        print("Handle sign out")
                    }),
                    //.default(Text("DEFAULT BUTTON")),
                    .cancel()
                  ]
            )
        }
    }
    
    private var contenMessagesView: some View{
        ScrollView{
            ForEach(0..<10, id: \.self) { num in
                VStack {
                    HStack(spacing: 16){
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .padding(8)
                            .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color(.label), lineWidth: 1))
     
                        VStack(alignment: .leading){
                            Text("Username")
                                .font(.system(size: 16, weight: .bold))
                            Text("Message sent to user")
                                .font(.system(size: 14))
                                .foregroundColor(Color(.lightGray))

                        }
                        Spacer()
                        Text("22d")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
            }.padding(.bottom, 50)
        }
    }
    
    private var newMessageButton: some View {
        Button{
            
        }label: {
            HStack{
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(30)
            .padding(.horizontal)
            .shadow(radius: 15)

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
    
}

//struct ViewMessages_Previews: PreviewProvider {
//    static var previews: some View {
//        ViewMessages(user: (username: "Miguel", userBio: "Lalalala", userBioLink: "", userUID: us, userEmail: <#T##String#>, userProfileURL: <#T##URL#>))
//            //.preferredColorScheme(.dark)
//        //ViewMessages()
//    }
//}
