//
//  RemoveFocusOnTap.swift
//  Coliver
//
//  Created by Никита Шляхов on 15.05.2023.
//

import SwiftUI

public struct RemoveFocusOnTapModifier: ViewModifier {
	public func body(content: Content) -> some View {
		content
			.onTapGesture {
				content.removeFocus()
			}
	}
}

extension View {
	public func removeFocusOnTap() -> some View {
		modifier(RemoveFocusOnTapModifier())
	}
}
