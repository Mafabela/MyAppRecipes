//
//  PostCardView.swift
//  MyAppRecipes
//
//  Created by Consultant on 1/24/23.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage

struct PostCardView: View {
    var post: Post
    // Callback
    var onUpdate: (Post) -> ()
    var onDelete: () -> ()
    //View Properties
    @AppStorage ("user_UID") private var userUID: String = ""
    @State private var docListener: ListenerRegistration?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12){
            WebImage(url: post.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(post.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .padding(.vertical, 8)
                Text(post.text)
                    .textSelection(.enabled)
                    .padding(.vertical, 8)
                
                //Post Image if Any
                if let postImageURL = post.imageURL {
                    GeometryReader{
                        let size = $0.size
                        WebImage(url: postImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(height: 200)
                }
                postInteraction()
            }
            
        }
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content: {
            //Displayin delete Button (only for Author's post)
            if post.userUID == userUID{
                Menu {
                    Button("Delete Post", role: .destructive, action: deletingPost) 
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .rotationEffect(.init(degrees: -90))
                        .foregroundColor(.black)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x:8)
            }
        })
        .onAppear{
            //Add Only One
            if docListener == nil {
                guard let postID = post.id else {return}
                docListener = Firestore.firestore().collection("Posts").document(postID).addSnapshotListener({ snapshot, error in
                    if let snapshot {
                        if snapshot.exists{
                            // - document update
                            //Fetching Update Document
                            if let updatedPost = try? snapshot.data(as: Post.self){
                                onUpdate(updatedPost)
                            }
                        }else{
                            //Document Deleted
                            onDelete()
                        }
                    }
                })
            }
        }
        .onDisappear(){
            //MARK: Applying snapshot Listener Only when Post is Available on the Screen
            //else removing the listener (it save unwanted live updates from the posts was swiped away from the screen)
            if let docListener{
                docListener.remove()
                self.docListener = nil
            }
            
        }
    }
    
    //MARK: LIKE/DISLIKE
    @ViewBuilder
    func postInteraction()->some View{
        HStack(spacing: 6) {
            Button(action: likePost){
                Image(systemName: post.likedID.contains(userUID) ? "hand.thumbsup.circle.fill" : "hand.thumbsup.circle")
            }
            Text("\(post.likedID.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: dislikePost){
                Image(systemName: post.dislikedID.contains(userUID) ? "hand.thumbsdown.circle.fill" : "hand.thumbsdown.circle")
            }
            .padding(.leading, 10)
            
            Text("\(post.dislikedID.count)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .foregroundColor(.black)
        .padding(.vertical, 8)
    }
    
    func likePost(){
        Task{
            guard let postID = post.id else {return}
            if post.likedID.contains(userUID){
                //Removing user ID from the array
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedID": FieldValue.arrayRemove([userUID])
                                                                                                ])
            }else{
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedID": FieldValue.arrayUnion([userUID]),
                    "dislikedID": FieldValue.arrayRemove([userUID])
                ])
            }
        }
    }
    
    func dislikePost(){
        Task{
            guard let postID = post.id else {return}
            if post.dislikedID.contains(userUID){
                //Removing user ID from the array
                try await Firestore.firestore().collection("Posts").document(postID).updateData(["dislikedID": FieldValue.arrayRemove([userUID])])
            }else{
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "dislikedID": FieldValue.arrayUnion([userUID]),
                    "likedID": FieldValue.arrayRemove([userUID])
                ])
            }
        }
    }
    
    func deletingPost(){
        Task{
            //Step 1: Delete Image from Firebase Storage if present
            do{
                if post.imageReferenceID != "" {
                    try await Storage.storage().reference().child("Post_Images").child(post.imageReferenceID).delete()
                }
                //Step 2: Delete Firestore Document
                guard let postID = post.id else {return}
                try await Firestore.firestore().collection("Posts").document(postID).delete()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
}

//struct PostCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        PostCardView()
//    }
//}
