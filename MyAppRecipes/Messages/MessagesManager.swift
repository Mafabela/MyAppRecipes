//
//  MessagesManager.swift
//  ChatApp2
//
//  Created by Consultant on 1/15/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class MessagesManager: ObservableObject {
    @Published private(set) var messages: [Messages] = []
//Next publish is for show the most recent messages
    @Published private(set) var lastMessageId = ""
    
    let db = Firestore.firestore()
    
    init (){
        getMessages()
    }

    //MARK: - Get data from Firestore
    
    func getMessages(){
        db.collection("messages").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(String(describing: error))")
                return
            }
            
            self.messages = documents.compactMap { document -> Messages? in
                do {
                    return try document.data(as: Messages.self)
                } catch {
                    print("Error decoding document into Message: \(error)")
                    return nil
                }
            }
            
            self.messages.sort { $0.timestamp < $1.timestamp}
            
            if let id = self.messages.last?.id {
                self.lastMessageId = id
            }
        }
    }
//MARK: -Add data to Firestore
    
    func sendMessage(text: String) {
        do{
            //let newMessages = Messages(id: "\(UUID())", text: text, received: false, timestamp: Date())
            let newMessages = Messages(id: "\(UUID())", text: text, timestamp: Date(), userName: "Mike", userUID: "1234", received: false)
            try db.collection("messages").document().setData(from: newMessages)
        }catch{
            print("Error adding messages to Firestore: \(error)")
        }
    }
    
    
    
}
