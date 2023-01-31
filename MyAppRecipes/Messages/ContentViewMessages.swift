//
//  ContentViewMessages.swift
//  MyAppRecipes
//
//  Created by Consultant on 1/29/23.
//

import SwiftUI

struct ContentViewMessages: View {
    @StateObject var messagesManager = MessagesManager()
    
    var body: some View {
        VStack {
            VStack {
                TitleRow()
                
                ScrollViewReader { proxy in
                    ScrollView{
                        ForEach(messagesManager.messages,
                                id: \.id ) { message in
                            MessegeBubble(message: message)
                        //Message(id: "12345", text: text, received: true, timestamp: Date()))
                                        }
                            }
                    .padding(.top, 10)
                    .background(.white)
                    .cornerRadius(30, corners:
                                    [.topLeft,
                                    .topRight])
                    .onChange(of: messagesManager.lastMessageId) { id in
                        withAnimation {
                            proxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color("Peach"))
            
            MessageField()
                .environmentObject(messagesManager)
        }
       // .padding()
    }
}

struct ContentViewMessages_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewMessages()
    }
}
