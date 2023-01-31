//
//  LoadingView.swift
//  MyAppRecipes
//
//  Created by Consultant on 1/22/23.
//

import SwiftUI

struct LoadingView: View {
    @Binding var show: Bool
    
    var body: some View {
        ZStack{
            if show {
                Group{
                    Rectangle()
                        .fill(.black.opacity(0.35))
                        .ignoresSafeArea()
                    ProgressView()
                        .padding(15)
                        .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            
        }
        .animation(.easeOut(duration: 0.05), value: show)
    }
}


