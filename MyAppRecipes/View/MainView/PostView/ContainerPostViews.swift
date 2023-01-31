//
//  ContainerPostViews.swift
//  MyAppRecipes
//
//  Created by Consultant on 1/24/23.
//

import SwiftUI
import Firebase

struct ContainerPostViews: View {
    @Binding var posts: [Post]
    // - View properties
    @State var isFetching: Bool = true
    var body: some View {
        ScrollView(.vertical, showsIndicators: false){
            LazyVStack{
                if isFetching{
                    ProgressView()
                        .padding(.top, 30)
                }else{
                    if posts.isEmpty{
                        // No post's Found on Firestore
                        Text("No Posts Found")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 30)
                    }else{
                        // Display Posts
                         Posts()
                    }
                }
            }
            .padding(15)
        }
        .refreshable {
            isFetching = true
            posts = []
            await fetchPost()
        }
        .task {
            guard posts.isEmpty else {return}
            await fetchPost()
        }
    }
    
    // Displaying Fetched Post
    @ViewBuilder
    func Posts()->some View {
        ForEach(posts){item in
            //Text(item.text)
            PostCardView(post: item) { updatedPost in
                //Uptating Post from the array
                if let index = posts.firstIndex(where: { item in
                    item.id == updatedPost.id
                }){
                    posts[index].likedID = updatedPost.likedID
                    posts[index].dislikedID = updatedPost.dislikedID
                }
            } onDelete: {
                //Removing Post from the array
                withAnimation (.easeIn(duration: 0.25)) {
                    posts.removeAll{item.id == $0.id}
                }
                 
            }
            Divider()
                .padding(.horizontal)

        }
    }
    
    // Fetching Posts
    func fetchPost() async {
        do{
            var query: Query!
            query = Firestore.firestore().collection("Posts")
                .order(by: "publishedDate", descending: true)
                .limit(to: 20)
            let docs = try await query.getDocuments()
            let fetchedPosts = docs.documents.compactMap { doc -> Post? in
                try? doc.data(as: Post.self)
            }
            await MainActor.run(body: {
                posts = fetchedPosts
                isFetching = false
            })
        }catch{
            print(error.localizedDescription)
        }
    }
    
}

struct ContainerPostViews_Previews: PreviewProvider {
    static var previews: some View {
        //ContainerPostViews()
        ContentView()
    }
}
