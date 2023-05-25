//
//  RoundedButton.swift
//  Coliver
//
//  Created by Никита Шляхов on 13.05.2023.
//

import SwiftUI

struct RoundedButton: View {
	
	// MARK: - Types
	
	typealias Action = (Bool) -> Void
	
	enum Style {
		case blue
		case black
	}
	
	// MARK: - Properties
	
	private let text: String
	private let style: Style
	private let action: Action
	
	// MARK: - States
	
	private var isEnabled: Bool = true
	
	// MARK: - View
	
	var body: some View {
		Button() {
			action(isEnabled)
		} label: {
			Text(text)
				.frame(minWidth: 80)
				.fontWeight(.semibold)
				.padding(.vertical, 10)
				.padding(.horizontal, 20)
				.disabled(!isEnabled)
				.foregroundColor(isEnabled ? style.textColor : style.disabledTextColor)
				.background(
					RoundedRectangle(cornerRadius: 20)
						.fill(isEnabled ? style.backgroundColor : style.disabledBackgroundColor)
				)
		}
	}
	
	// MARK: - Initialization
	
	init(
		text: String,
		style: Style = .blue,
		action: @escaping (Bool) -> Void = { _ in }
	) {
		self.text = text
		self.style = style
		self.action = action
	}
	
	// MARK: - Methods
	
	func enabled(_ flag: Bool) -> some View {
		var view = self
		view.isEnabled = flag
		return view
	}
}

// MARK: - Preview

struct RoundedButton_Previews: PreviewProvider {
    static var previews: some View {
		RoundedButton(text: "Вход")
    }
}

// MARK: - Style

extension RoundedButton.Style {
	var textColor: Color {
		switch(self) {
		case .blue, .black:
			return .white
		}
	}
	
	var backgroundColor: Color {
		switch(self) {
		case .blue:
			return .blue
		case .black:
			return .black
		}
	}
	
	var disabledTextColor: Color {
		switch(self) {
		case .blue, .black:
			return .white
		}
	}
	
	var disabledBackgroundColor: Color {
		switch(self) {
		case .blue, .black:
			return .gray
		}
	}
}
