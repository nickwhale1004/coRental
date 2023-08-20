//
//  SplashScreen.swift
//  Coliver
//
//  Created by Никита Шляхов on 12.05.2023.
//

import SwiftUI

struct SplashView: View {
	@Binding var hasAppLoaded: Bool
	
	@State var waveOffset1 = CGSize(width: 10, height: 0)
	@State var waveOffset2 = CGSize(width: 90, height: 0)
	@State var opacity: CGFloat = 0.5
	@State var imageSize = 5
	
	var body: some View {
		ZStack {
			VStack(spacing: -5) {
				Image(systemName: "person.fill")
					.foregroundColor(.blue)
				Text("Coliver")
					.scaleEffect(x: 0.4, y: 0.4)
			}
			.scaleEffect(CGSize(width: imageSize, height: imageSize))
			.opacity(opacity)
			
			ZStack {
				VStack {
					Spacer()
					Image("wave")
						.resizable()
						.aspectRatio(contentMode: .fit)
				}
				.offset(waveOffset1)
				VStack {
					Spacer()
					Image("wave")
						.resizable()
						.aspectRatio(contentMode: .fit)
				}
				.offset(waveOffset2)
			}
		}
		.edgesIgnoringSafeArea(.all)
		.onAppear() {
			withAnimation(.easeInOut(duration: 1).delay(2)) {
				imageSize = 6
			}
			withAnimation(.easeInOut(duration: 1)) {
				opacity = 1
			}
			withAnimation(.easeIn(duration: 2)) {
				waveOffset1.width = 0
				waveOffset2.width = 100
			}
			withAnimation(.easeOut(duration: 1).delay(2)) {
				waveOffset1.height = 300
				waveOffset2.height = 200
			}
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
				hasAppLoaded = true
			}
		}
	}
}

struct SplashView_Previews: PreviewProvider {
	static var previews: some View {
		SplashView(hasAppLoaded: Binding.constant(false))
	}
}
