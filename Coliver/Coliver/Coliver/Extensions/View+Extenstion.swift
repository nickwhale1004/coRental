//
//  View+Extenstion.swift
//  Coliver
//
//  Created by Никита Шляхов on 15.05.2023.
//

import SwiftUI

extension View {
	func onBackSwipe(perform action: @escaping () -> Void) -> some View {
		gesture(
			DragGesture()
				.onEnded { value in
					if value.startLocation.x < 50 && value.translation.width > 80 {
						action()
					}
				}
		)
	}
	
	func removeFocus() {
		UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
	}
}
