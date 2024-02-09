//
//  BottomSheetView.swift
//  Coliver
//
//  Created by Никита Шляхов on 09.02.2024.
//

import SwiftUI

struct BottomSheetView<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray)
                            .frame(width: 50, height: 4)
                            .padding(.top, 16)
                        Spacer()
                    }
                    content
                }
                    .padding(.bottom, 100)
                    .frame(maxWidth: .infinity)
                    .background(
                        Color.white
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    )
                    .gesture(
                        DragGesture().onEnded { value in
                            if value.translation.height > 50 {
                                withAnimation {
                                    isPresented = false
                                }
                            }
                        }
                    )
                
            }
            .opacity(isPresented ? 1 : 0)
            .offset(y: isPresented ? 0 : geometry.size.height)
            .animation(.spring())
            
        }
        .edgesIgnoringSafeArea(.all)
        .background(
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .opacity(isPresented ? 1 : 0)
                .animation(.easeInOut)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
        )
    }
}
