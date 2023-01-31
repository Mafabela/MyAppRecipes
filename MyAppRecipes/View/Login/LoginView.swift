//
//  LoginView.swift
//  MyAppRecipes
//
//  Created by Consultant on 1/21/23.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct LoginView: View {
    //MARK: UserDetails
    @State var emailID: String = ""
    @State var password: String = ""
    //MARK: View Properties
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool =  false
    //MARK:  User Defaults
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    @AppStorage("log_status") var logStatus: Bool = false
    
    var body: some View {
        VStack(spacing:10){
            Text("Lets Sign you in")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            Text ("Welcome back, \nYou have been missed")
                .font(.title3)
                .hAlign(.leading)
            
            VStack(spacing: 12){
                TextField("Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                    .padding(.top, 25)
                SecureField("Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                
                Button ("Reset password", action: resetPassword)
                    .font(.callout)
                    .fontWeight(.medium)
                    .tint(.black)
                    .hAlign(.trailing)
                Button(action: loginUser){
                    Text("Sign in")
                        .foregroundColor(.green)
                        .font(.body.bold())
                        .hAlign(.center)
                        .fillView(.black)
                }
                .padding(.top,10)
                
            }
            
            //MARK: Register button
            HStack{
                Text("Dont have account")
                    .foregroundColor(.gray)
                Button("Register Now"){
                    createAccount.toggle()
                }
                .fontWeight(.bold)
                .foregroundColor(.black)
            }
            .font(.callout)
            .VAlign(.bottom)
        }
        .VAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        
        // MARK: Register View VIA Sheets
        .fullScreenCover(isPresented: $createAccount) {
            RegisterView()
        }
        //MARK: Displaying Alert
        .alert(errorMessage, isPresented: $showError, actions: {})
        
    }
    func loginUser(){
        isLoading = true
        closeKeyboard()
        Task {
            do{
                //With the help of Swift Concurrency Auth can be done with SingleLine
                try await Auth.auth().signIn(withEmail: emailID, password: password)
                print("User Found")
                try await fetchUser()
            }catch {
                await setError(error)
            }
        }
    }
    
    //MARK: If User if found then Fetching User Data Firestore
    func fetchUser() async throws{
        guard let userID = Auth.auth().currentUser?.uid else {return}
       let user = try await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self)
        //MARK: UI Updating Must be Run On Main Thread
        await MainActor.run(body: {
            // Setting UserDefaults data and Changing App's Auth Status
            userUID = userID
            userNameStored = user.username
            profileURL = user.userProfileURL
            logStatus = true
        })
    }
    
    
    func resetPassword(){
        Task {
            do{
                //With the help of Swift Concurrency Auth can be done with SingleLine
                try await Auth.auth().sendPasswordReset(withEmail: emailID)
                print("Link Sent")
            }catch {
                await setError(error)
            }
        }
    }
    
    // MARK: Displaying Error VIA Aler
    func setError(_ error: Error)async{
        //Must be update on Main thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}

//MARK: Register View
struct RegisterView: View {
    //MARK: User Details
    @State var emailID: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userBio: String = ""
    @State var userBioLink: String = ""
    @State var userProfilesPicture: Data?
    //MARK: View Properties
    @Environment(\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool =  false
    //MARK: UserDefaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View{
        VStack(spacing:10){
            Text("Lets Register \nAccount")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            Text ("Hello and welcome, have a wonderful journey")
                .font(.title3)
                .hAlign(.leading)
            
           //Aqui estaba    VStack(spacing: 12)
            //MARK: For Smaller Size Optimization
            ViewThatFits{
                ScrollView(.vertical, showsIndicators: false){
                    HelperView()
                }
                HelperView()
            }

            //MARK: Register button
            HStack{
                Text("Already have an account")
                    .foregroundColor(.gray)
                Button("Login Now"){
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundColor(.black)
            }
            .font(.callout)
            .VAlign(.bottom)
        }
        .VAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { newValue in
            //MARK: Extracting UIImage From PhoroItem
            if let newValue {
                Task{
                    do{
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else {return}
                        //MARK: UI must be updated on Main Thread
                        await MainActor.run(body: {
                            userProfilesPicture = imageData
                        })
                    } catch {
                        
                    }
                }
            }
        }
        
        //MARK: Display alert
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    @ViewBuilder
    func HelperView() -> some View {
        VStack(spacing: 12){
            ZStack{
                if let userProfilesPicture, let image = UIImage(data: userProfilesPicture){
                    Image(uiImage: image)
                    //Image("NullProfile")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName:"person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 90, height: 90)
            .background(.gray)
            .clipShape(Circle())
            .contentShape(Circle())
            .onTapGesture {
                showImagePicker.toggle()
            }
            .padding(.top, 15)
            
            
            TextField("Username", text: $userName)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                .padding(.top, 5)
            TextField("Email", text: $emailID)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                
            SecureField("Password", text: $password)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            TextField("About you", text: $userBio, axis: .vertical)
                .frame(minHeight: 100, alignment: .top)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            TextField("Bio Link (Optional)", text: $userBioLink)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                
            Button(action: registerUser){
                Text("Sign up")
                    .foregroundColor(.green)
                    .font(.body.bold())
                    .hAlign(.center)
                    .fillView(.black)
            }
            .disableWithOpacity(userName == "" || userBio == "" || emailID == "" || password == "" || userProfilesPicture == nil)
            .padding(.top, 10)
        }
    }
    
    func registerUser(){
        isLoading = true
        closeKeyboard()
        Task{
            do{
                // Step 1: Creating Firebase Account
                try await Auth.auth().createUser(withEmail: emailID, password: password)
                // Step 2: Uploading Profile Photo into firebase Storage
                guard let userUID = Auth.auth().currentUser?.uid else{return}
                guard let imageData =  userProfilesPicture else {return}
                //let storageRef = Storage.storage()
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)
                // Step 3: Downloading Photo URL
                let dowloadURL = try await storageRef.downloadURL()
                // Step 4: Creating a User Firestore Object
                let user = User(username: userName, userBio: userBio, userBioLink: userBioLink, userUID: userUID, userEmail: emailID, userProfileURL: dowloadURL)
                // Step 5: Saving User Doc into Firestore Database
                let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from: user, completion: { error in
                    if error == nil {
                        print ("Saved Succesfully")
                        userNameStored = userName
                        self.userUID = userUID
                        profileURL = dowloadURL
                        logStatus = true
                        
                        
                    }
                    
                })
            }catch{
                // MARK: Deleting Account In case of Failure
                try await Auth.auth().currentUser?.delete()
                await setError(error)
            }
        }
    }
    
    // MARK: Displaying Error VIA Aler
    func setError(_ error: Error)async{
        //Must be update on Main thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
    
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
        //RegisterView()
    }
}
//MARK: View Extension for UI Building
extension View {
    //Closing All Active Keyboards
    func closeKeyboard(){
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    //MARK: Disabling with opacity
    func disableWithOpacity(_ condition: Bool) -> some View {
        self
            .disabled(condition)
            .opacity(condition ? 0.6 : 1)
    }
    
    func hAlign(_ alignament: Alignment) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: alignament)
    }
    
    func VAlign(_ alignament: Alignment) -> some View {
        self
            .frame(maxHeight: .infinity, alignment: alignament)
    }
    
    //MARK: Custom Border View whit padding
    func border(_ width: CGFloat,_ color: Color) -> some View {
        self
            .padding(.horizontal, 15)
            .padding(.vertical, 15)
            .background{
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(color, lineWidth: width)
            }
    }
    
    //MARK: Custom Fill View whit padding
    func fillView(_ color: Color) -> some View {
        self
            .padding(.horizontal, 15)
            .padding(.vertical, 15)
            .background{
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color)
            }
    }
}
